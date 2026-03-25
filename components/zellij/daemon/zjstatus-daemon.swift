// MIT License
//
// Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
//
// @file: components/zellij/daemon/zjstatus-daemon.swift
// @brief: Event-driven daemon that pushes keyboard layout, network status, and
//         battery state into zjstatus pipe widgets instantly — no polling.
// @author: Andrew Vasilyev
// @license: MIT
//
// Event sources:
//   Keyboard  — DistributedNotificationCenter / Carbon TIS
//   Network   — SCDynamicStore (SystemConfiguration framework)
//   Battery   — IOPSNotificationCreateRunLoopSource (IOKit)
//
// Each change broadcasts `zellij pipe "zjstatus::pipe::pipe_<widget>::<value>"`
// to all plugins in the current session (ZELLIJ_SESSION_NAME env var).
//
// Usage:
//   zjstatus-daemon &
//   # killed automatically when the zellij session exits (parent process gone)

import Foundation
import Carbon
import SystemConfiguration
import IOKit.ps

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Send a value to a zjstatus pipe widget in the current zellij session.
/// Runs `zellij pipe` as a fire-and-forget child process.
func pipe(widget: String, value: String) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = ["zellij", "pipe", "zjstatus::pipe::pipe_\(widget)::\(value)"]

    // Inherit ZELLIJ_SESSION_NAME so zellij targets the right session
    let env = ProcessInfo.processInfo.environment
    task.environment = env

    // Suppress stdout/stderr — we don't care about the pipe command's output
    task.standardOutput = FileHandle.nullDevice
    task.standardError  = FileHandle.nullDevice

    do {
        try task.run()
        // Don't waitUntilExit — fire and forget
    } catch {
        // If zellij isn't available or the session is gone, silently ignore
    }
}

// ── Keyboard layout ───────────────────────────────────────────────────────────

/// Map a raw macOS input source ID to a short display label.
func keyboardLabel(from sourceID: String) -> String {
    // Strip known prefixes
    var name = sourceID
    for prefix in ["com.apple.keylayout.", "com.apple.inputmethod."] {
        if name.hasPrefix(prefix) {
            name = String(name.dropFirst(prefix.count))
            break
        }
    }
    // For dotted input-method IDs keep only the last segment
    if let dot = name.lastIndex(of: ".") {
        name = String(name[name.index(after: dot)...])
    }
    // Well-known aliases
    switch true {
    case name == "ABC" || name == "US"
            || name.hasPrefix("USInternational")
            || name.hasPrefix("British")
            || name.hasPrefix("Australian"):
        return "󰌌 EN"
    case name.hasPrefix("Russian"):
        return "󰌌 RU"
    default:
        return "󰌌 \(name)"
    }
}

func currentKeyboardLabel() -> String {
    guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceID)
    else { return "󰌌 ?" }
    let id = Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as! String
    return keyboardLabel(from: id)
}

func setupKeyboardWatcher() {
    // Send initial value immediately
    pipe(widget: "keyboard", value: currentKeyboardLabel())

    DistributedNotificationCenter.default().addObserver(
        forName: NSNotification.Name("AppleSelectedInputSourcesChangedNotification"),
        object: nil,
        queue: nil
    ) { _ in
        pipe(widget: "keyboard", value: currentKeyboardLabel())
    }
}

// ── Network ───────────────────────────────────────────────────────────────────

func networkLabel(store: SCDynamicStore) -> String {
    // Primary IPv4 interface from SCDynamicStore
    if let val = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString),
       let dict = val as? [String: Any],
       let iface = dict["PrimaryInterface"] as? String {
        if iface == "en0" || iface.hasPrefix("wlan") || iface.hasPrefix("wlp") {
            return "󰤨 \(iface)"
        } else {
            return "󰈁 \(iface)"
        }
    }
    return "󰤭"
}

func setupNetworkWatcher() -> SCDynamicStore {
    var ctx = SCDynamicStoreContext(
        version: 0, info: nil, retain: nil, release: nil, copyDescription: nil
    )

    let store = SCDynamicStoreCreate(
        nil, "zjstatus-daemon" as CFString,
        { store, _, _ in
            pipe(widget: "network", value: networkLabel(store: store))
        },
        &ctx
    )!

    // Watch global IPv4 state (covers connect/disconnect/interface swap)
    let keys = ["State:/Network/Global/IPv4",
                "State:/Network/Global/IPv6"] as CFArray
    SCDynamicStoreSetNotificationKeys(store, keys, nil)

    guard let src = SCDynamicStoreCreateRunLoopSource(nil, store, 0) else { return store }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .defaultMode)

    // Send initial value
    pipe(widget: "network", value: networkLabel(store: store))

    return store
}

// ── Battery ───────────────────────────────────────────────────────────────────

let iconsDischarging = ["󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]

func batteryLabel() -> String {
    let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [AnyObject]

    for src in list {
        guard let desc = IOPSGetPowerSourceDescription(info, src)?
                            .takeUnretainedValue() as? [String: Any],
              let type_ = desc[kIOPSTypeKey] as? String,
              type_ == kIOPSInternalBatteryType,
              let isPresent = desc[kIOPSIsPresentKey] as? Bool,
              isPresent
        else { continue }

        let pct     = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let state   = desc[kIOPSPowerSourceStateKey] as? String ?? ""
        let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let charged  = desc[kIOPSIsChargedKey]  as? Bool ?? false

        if charging && !charged {
            return "󰂄 \(pct)%"
        } else if charged || state == kIOPSACPowerValue {
            return "󰁹 \(pct)%"
        } else {
            let idx = min(pct / 10, 10)
            return "\(iconsDischarging[idx]) \(pct)%"
        }
    }
    // No internal battery (desktop / AC-only)
    return "󰚥"
}

func setupBatteryWatcher() {
    // Send initial value
    pipe(widget: "battery", value: batteryLabel())

    let src = IOPSNotificationCreateRunLoopSource({ _ in
        pipe(widget: "battery", value: batteryLabel())
    }, nil).takeRetainedValue()

    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .defaultMode)
}

// ── Entry point ───────────────────────────────────────────────────────────────

setupKeyboardWatcher()
let networkStore = setupNetworkWatcher()
setupBatteryWatcher()

// Re-send all initial values after a short delay to ensure zjstatus has
// finished loading (it may not be ready when the daemon first starts).
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    pipe(widget: "keyboard", value: currentKeyboardLabel())
    pipe(widget: "network",  value: networkLabel(store: networkStore))
    pipe(widget: "battery",  value: batteryLabel())
}

// Run forever — killed when the zellij session exits
RunLoop.main.run()
