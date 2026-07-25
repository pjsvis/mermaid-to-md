# mermaid-to-md

*State diagrams for agent–human discussion. Baked into markdown, visible anywhere.*

Render Mermaid diagrams to Unicode box-drawing art, baked into markdown files.

## The pitch

Mermaid diagrams in markdown are only viewable with a renderer — GitHub's web
preview, a VSCode plugin, a browser. `mermaid-to-md` renders the diagram at
**authoring time** and bakes the art into the markdown file as a `​```text`
block. The result is visible in **any viewer** — Glow, `cat`, GitHub web, any
email client — without a renderer, runtime, or plugin.

The diagram is the product. The source is reference material. Render once,
ship text, done.

## Quick start

### From source (Rust)

```bash
cargo build --release
echo 'graph TD\n  A --> B --> C' | ./target/release/mermaid-tui
```

### From npm (once published)

```bash
npx mermaid-to-md < diagram.mmd > out.md
```

### Render to a markdown file

```bash
# Bake the art into a markdown file
scripts/mermaid-to-md.sh diagram.mmd -o diagram.md

# View in Glow
glow diagram.md
```

## The demo

See `demo/mermaid-to-md-demo.md` for three baked diagrams (flowchart, state
diagram, sequence diagram) viewable in Glow:

```bash
glow demo/mermaid-to-md-demo.md
```

## Modes

The binary (`mermaid-tui`) renders Mermaid source from stdin to Unicode art
on stdout. The three modes below are the wrapper layer
(`scripts/mermaid-to-md.sh`) — shipped (bake, inject, verify; `just test`
runs the regression suite). npm packaging is pending (`td-6e3b3a`).

| Mode | Command | What it does |
|------|---------|--------------|
| **Bake** | `mermaid-to-md <file.mmd> -o <out.md>` | Render source → markdown file with art + source |
| **Inject** | `mermaid-to-md --inject <file.md>` | Render `​```mmd` blocks in-place, insert/replace art blocks |
| **Verify** | `mermaid-to-md --verify <file.md>` | Re-render and diff — exit 0 if fresh, 1 if stale |

## Why not WASM?

The bake step renders at authoring time with a compiled binary (<15ms). The
browser displays static text — `<pre><code>` with a monospace font. WASM would
ship a runtime to re-render the same source at view time, producing the exact
same box-drawing characters that are already in the file. The bake step is the
anti-WASM move. See `briefs/002-mermaid-to-md-spinoff.md` for the full
rationale.

## The `​```mmd` convention

Source goes in `​```mmd` blocks (not `​```mermaid`) so GitHub renders it as
plain text, not a second live diagram. One diagram per viewer, not two.

## Repository structure

```
mermaid-to-md/
├── Cargo.toml              # the Rust binary (mermaid-tui)
├── src/
│   ├── main.rs             # CLI entry point
│   └── mermaid.rs          # the renderer (5,238 lines)
├── bin/
│   └── mermaid-to-md.js    # JS wrapper for npm (placeholder, Phase 2)
├── scripts/
│   ├── mermaid-to-md.sh    # bash wrapper — bake/inject/verify (shipped)
│   └── mermaid-extract.sh  # sibling: extract mmd from markdown → terminal
├── demo/
│   └── mermaid-to-md-demo.md
├── briefs/                 # project specs
├── debriefs/               # session debriefs
├── decisions/              # decision records (positioning, scope)
├── playbooks/              # repeatable patterns (diagrams, video recording)
├── SYSTEM.md               # the Edinburgh Protocol (agent operating system)
├── DEPENDENCIES.md         # install instructions (macOS verified, Linux/Windows invited)
├── USAGE.md                # how to use: reasoning with baked state diagrams
├── agent-workflow-discussion.md  # dogfood: state diagram as comms channel
└── README.md
```

## Attribution

The Mermaid renderer (`src/mermaid.rs`, ~5,200 lines) is **not original to
this repo**. It is copied from **xAI's open-sourced Grok CLI** —
[`xai-org/grok-build`](https://github.com/xai-org/grok-build), at
`crates/codegen/xai-grok-markdown/src/mermaid.rs` — the component Grok uses
to draw mermaid blocks in the terminal. It is copyright 2023–2026 **SpaceXAI**
and licensed under the **Apache License 2.0**.

The `ratatui` dependency is the only modification: upstream uses `ratatui` for
styled terminal output; this repo replaces it with inline no-op stubs (the
"Style stubs (ratatui extraction)" block at the top of `mermaid.rs`) so the
renderer depends on nothing but `unicode-width`. The parsing, layout, edge
routing, and box-drawing canvas are upstream's work.

**Simon Willison** inspired this port. His
[`grok-mermaid`](https://simonwillison.net/2026/Jul/16/grok-mermaid/) tool
compiled the same renderer to WebAssembly for an in-browser playground — the
work that brought this renderer to our attention and takes the direction this
repo plays against. Where Simon ships the renderer *to the browser* (WASM,
view-time), this repo *bakes the art into markdown* at authoring time and
ships text. The contrast clarified the move; credit where it's due.

## License

This repository is dual-licensed by component (see `NOTICE`):

- **Wrapper layer** (`scripts/`, `bin/`, `src/main.rs`) — MIT, © 2026 Peter
  Smith. See `LICENSE`.
- **Renderer** (`src/mermaid.rs`) — Apache License 2.0, © 2023–2026 SpaceXAI,
  carried from `xai-org/grok-build` (see [Attribution](#attribution) above).
  See `LICENSE-Apache-2.0.txt`.

Prebuilt platform binaries (distributed as npm optional-dependency packages,
e.g. `mermaid-to-md-darwin-arm64`) are derivative works of the Apache-2.0
renderer and carry its terms; `NOTICE` and `LICENSE-Apache-2.0.txt`
accompany them.
