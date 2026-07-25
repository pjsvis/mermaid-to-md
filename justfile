# mermaid-to-md — facade only. Implementation lives in scripts/ and src/.

set shell := ["bash", "-o", "pipefail", "-c"]

# ── Discovery ──

default:
    @just --list

orient:
    @echo "=== mermaid-to-md ==="
    @git log --oneline -5 2>/dev/null || echo "(no commits yet)"
    @echo ""
    @echo "=== Build ==="
    @ls target/release/mermaid-tui 2>/dev/null && echo "binary: built" || echo "binary: not built (run: just build)"
    @echo ""
    @echo "=== Briefs ==="
    @ls briefs/ 2>/dev/null || echo "(none)"

about:
    @cat about.md

# ── Build ──

build:
    cargo build --release

# ── Test ──

test: build
    @scripts/test-inject.sh

# ── Mermaid rendering ──

mermaid FILE BLOCK="":
    @scripts/mermaid-extract.sh {{ FILE }} {{ BLOCK }}

# ── Demo ──

demo:
    @glow demo/mermaid-to-md-demo.md
