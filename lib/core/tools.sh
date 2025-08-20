#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    local actual_version
    actual_version=$(yq --version | awk '{print $4}')

    if [[ "$actual_version" == "$YQ_VERSION" ]]; then
      echo "⇒ yq ${YQ_VERSION} is already installed."
      return 0
    fi

    echo "⇒ Found yq, but version mismatch. Expected: '$YQ_VERSION', Found: '$actual_version'"
  fi

  echo "⇒ Installing yq v${YQ_VERSION}..."

  local OS ARCH BIN_NAME URL DEST TMPBIN

  case "$(uname -s)" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      return 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64 | aarch64 | arm64)
      [[ "$(uname -m)" == "x86_64" ]] && ARCH="amd64" || ARCH="arm64"
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      return 1
      ;;
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
