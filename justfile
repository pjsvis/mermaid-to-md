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

# test runs the inject/verify regression suite, the doc-stale check, and a
# freshness verify on the demo (a living inject artifact). All green = ship.
test: build check-docs demo-verify
    @scripts/test-inject.sh

check-docs:
    @scripts/check-docs.sh

# ── Mermaid rendering ──

mermaid FILE BLOCK="":
    @scripts/mermaid-extract.sh {{ FILE }} {{ BLOCK }}

# ── Demo ──

# Re-render the demo's diagrams (inject) and display the result.
# Idempotent: re-running only changes output if the renderer or source did.
# `git diff demo/` after this to review drift.
demo: build
    scripts/mermaid-to-md.sh --inject demo/mermaid-to-md-demo.md
    @glow demo/mermaid-to-md-demo.md

# Check the demo's baked art is fresh (CI-equivalent; no side effects).
demo-verify: build
    scripts/mermaid-to-md.sh --verify demo/mermaid-to-md-demo.md
