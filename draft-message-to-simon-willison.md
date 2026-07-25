# Draft message to Simon Willison

**Context:** Simon adapted the same xAI Rust Mermaid renderer for WASM. We're taking a different path with the same source code. This is a note explaining our approach — not a correction of his, but a "here's what we're doing with the same code, and why we went the other way."

---

Subject: Terminal-native Mermaid — bake the art, skip the runtime

Hi Simon,

Saw your WASM adaptation of the xAI Mermaid renderer — neat work. We've been working with the same Rust source and went the opposite direction. Thought you'd find the contrast interesting.

The core move: instead of shipping the renderer to the browser (WASM) or shipping the source to a client with a renderer (GitHub's live SVG), we **bake the rendered art into the markdown at authoring time**. A ~40-line CLI wraps the Rust binary, renders Mermaid source to Unicode box-drawing art, and writes it into a `​```text` fenced block in the markdown file. The source goes in a `​```mmd` block (not `​```mermaid`, so GitHub doesn't render it as a second live diagram — collision avoidance).

The result is a markdown file that displays the diagram in **any viewer** — Glow, `cat`, GitHub web, any email client — without a renderer, runtime, or plugin. The art is plain text: 16 non-ASCII characters from the box-drawing and geometric-shapes Unicode blocks, all covered by every monospace font. In a browser, `​```text` becomes `<pre><code>` with a monospace font stack. It just shows up, identically to the terminal.

The renderer runs once at authoring time (<15ms on a local CPU). The browser does zero work at view time. WASM would ship a ~100KB binary + JS glue to re-render the same source at view time, producing the exact same box-drawing characters that are already in the file. For the batch product, the bake step is the anti-WASM move — it eliminates the problem WASM solves.

The one place WASM still makes sense: browser-based **live preview** (editing `.mmd` source in a web editor, seeing art update in real-time). The browser can't shell out to a native binary, so WASM is the only client-side path. We've parked that as a separate idea — different product, different audience (browser editors, not terminal editors). For batch rendering, the bake step wins.

We're packaging the binary for npm (esbuild/biome pattern — precompiled platform binaries via optional deps) with a `curl | sh` escape hatch. The `--inject` mode renders art blocks into existing markdown in-place; `--verify` re-renders and diffs to detect stale diagrams (the art itself is the checksum — no hash needed). Repo will be standalone, MIT licensed.

The principle: the diagram is the product. The source is reference material. Render once, ship text, done.

Would value your take — particularly if you see a hole in the collision-avoidance reasoning (the `​```mmd` vs `​```mermaid` fence choice is the load-bearing decision).

— Peter
