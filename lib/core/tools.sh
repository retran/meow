#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

YQ_VERSION="${YQ_VERSION:-4.47.1}"

ensure_yq() {
  local version_output

  if command -v yq >/dev/null 2>&1; then
    version_output=$(yq --version 2>&1)
    if [[ "$version_output" == *"version \"$YQ_VERSION\""* ]]; then
      return 0
    fi
    echo "⇒ Found yq, but version mismatch: $version_output"
  fi

  echo "⇒ Installing yq v${YQ_VERSION}..."

  local OS ARCH BIN_NAME URL DEST TMPBIN

  case "$(uname -s)" in
    Linux)   OS="linux" ;;
    Darwin)  OS="darwin" ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; return 1 ;;
  esac

  case "$(uname -m)" in
    x86_64)    ARCH="amd64" ;;
    aarch64)   ARCH="arm64" ;;
    arm64)     ARCH="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac

  BIN_NAME="yq_${OS}_${ARCH}"
  URL="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${BIN_NAME}"
  DEST="/usr/local/bin/yq"
  TMPBIN="/tmp/${BIN_NAME}"

  if curl -fsSL "$URL" -o "$TMPBIN"; then
    sudo mv "$TMPBIN" "$DEST" || return 1
    sudo chmod +x "$DEST" || return 1
    echo "✓ yq v${YQ_VERSION} installed to $DEST"
    return 0
  else
    echo "✗ Failed to download yq from $URL" >&2
    return 1
  fi
}
