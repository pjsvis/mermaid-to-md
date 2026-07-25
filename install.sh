#!/usr/bin/env sh
# install.sh — curl|sh escape hatch for non-npm users.
# Downloads the correct precompiled mermaid-tui binary from GitHub Releases
# and installs it to ~/.local/bin (or a prefix you choose).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pjsvis/mermaid-to-md/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --prefix /usr/local
#   curl -fsSL .../install.sh | sh -s -- --version 0.1.0
set -eu

REPO="pjsvis/mermaid-to-md"
VERSION="${MERMAID_TO_MD_VERSION:-latest}"
PREFIX="${PREFIX:-$HOME/.local/bin}"
PREFIX_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)  PREFIX="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── detect platform ──────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLATFORM_OS="darwin" ;;
  Linux)  PLATFORM_OS="linux" ;;
  *) echo "Unsupported OS: $OS (install via npm: npm install -g mermaid-to-md)" >&2; exit 1 ;;
esac

case "$ARCH" in
  arm64|aarch64) PLATFORM_ARCH="arm64" ;;
  x86_64|amd64)  PLATFORM_ARCH="x64" ;;
  *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
esac

PLATFORM="${PLATFORM_OS}-${PLATFORM_ARCH}"
BIN_NAME="mermaid-tui"

echo "Installing mermaid-tui for ${PLATFORM} (version: ${VERSION})"

# ── resolve download URL ─────────────────────────────────────────────────
if [ "$VERSION" = "latest" ]; then
  URL="https://github.com/${REPO}/releases/latest/download/${BIN_NAME}"
else
  URL="https://github.com/${REPO}/releases/download/v${VERSION}/${BIN_NAME}"
fi

# ── download ─────────────────────────────────────────────────────────────
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARGET="${TMPDIR}/${BIN_NAME}"

echo "Downloading ${URL}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TARGET"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TARGET" "$URL"
else
  echo "Error: neither curl nor wget found" >&2; exit 1
fi

chmod +x "$TARGET"

# ── install ──────────────────────────────────────────────────────────────
mkdir -p "$PREFIX"
mv "$TARGET" "${PREFIX}/${BIN_NAME}"

echo ""
echo "Installed mermaid-tui to ${PREFIX}/${BIN_NAME}"
echo ""
if ! echo "$PATH" | grep -q "$PREFIX"; then
  echo "NOTE: ${PREFIX} is not in your PATH. Add it:"
  echo "  export PATH=\"${PREFIX}:\$PATH\""
fi
echo "Verify: mermaid-tui --help"
