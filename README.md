# mermaid-to-md

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
# Bake the art into a markdown file (standalone mode, to be implemented)
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
on stdout today. The three modes below are the wrapper layer
(`scripts/mermaid-to-md.sh`) — planned, not yet implemented (brief 001).

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
│   ├── mermaid-to-md.sh    # bash wrapper — bake/inject/verify (planned)
│   └── mermaid-extract.sh  # sibling: extract mmd from markdown → terminal
├── demo/
│   └── mermaid-to-md-demo.md
├── briefs/                 # project specs
├── agent-workflow-discussion.md  # dogfood: state diagram as comms channel
└── README.md
```

## License

MIT
