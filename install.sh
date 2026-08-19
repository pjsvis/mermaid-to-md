#!/usr/bin/env sh
# install.sh — curl|sh escape hatch for non-npm users.
# Downloads the precompiled mermaid-tui binary AND the mermaid-to-md
# wrapper (bake/inject/verify) from GitHub Releases, and installs both
# to ~/.local/bin (or a prefix you choose). The wrapper resolves the
# binary via PATH, so the pair works standalone — no build tree needed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pjsvis/mermaid-to-md/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --prefix /usr/local
#   curl -fsSL .../install.sh | sh -s -- --version 0.1.0
#
# Testing: MERMAID_TO_MD_BASE_URL overrides the release base
# (default https://github.com/pjsvis/mermaid-to-md/releases) so the
# download path can be exercised against a local server.
set -eu

REPO="pjsvis/mermaid-to-md"
VERSION="${MERMAID_TO_MD_VERSION:-latest}"
PREFIX="${PREFIX:-$HOME/.local/bin}"
BASE_URL="${MERMAID_TO_MD_BASE_URL:-https://github.com/${REPO}/releases}"

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

echo "Installing mermaid-tui + mermaid-to-md wrapper for ${PLATFORM} (version: ${VERSION})"

# ── resolve download URLs ─────────────────────────────────────────────────
if [ "$VERSION" = "latest" ]; then
  ASSET_URL="${BASE_URL}/latest/download"
else
  ASSET_URL="${BASE_URL}/download/v${VERSION}"
fi

# ── download ──────────────────────────────────────────────────────────────
fetch() {  # fetch <asset-name> <dest>
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${ASSET_URL}/$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "${ASSET_URL}/$1"
  else
    echo "Error: neither curl nor wget found" >&2; exit 1
  fi
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading ${ASSET_URL}/${BIN_NAME}"
fetch "$BIN_NAME" "${TMPDIR}/${BIN_NAME}"

echo "Downloading ${ASSET_URL}/mermaid-to-md.sh"
fetch "mermaid-to-md.sh" "${TMPDIR}/mermaid-to-md"

chmod +x "${TMPDIR}/${BIN_NAME}" "${TMPDIR}/mermaid-to-md"

# ── install ──────────────────────────────────────────────────────────────
mkdir -p "$PREFIX"
mv "$TMPDIR/$BIN_NAME" "${PREFIX}/${BIN_NAME}"
mv "$TMPDIR/mermaid-to-md" "${PREFIX}/mermaid-to-md"

echo ""
echo "Installed to ${PREFIX}:"
echo "  mermaid-tui    — render Mermaid (stdin) to Unicode art"
echo "  mermaid-to-md  — bake / inject / verify wrapper"
echo ""
if ! echo "$PATH" | grep -q "$PREFIX"; then
  echo "NOTE: ${PREFIX} is not in your PATH. Add it:"
  echo "  export PATH=\"${PREFIX}:\$PATH\""
fi
echo "Verify: mermaid-tui --version"
