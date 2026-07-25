# brief: mermaid-to-md live preview — inline editable Mermaid preview on keystroke

**Created:** 2026-07-23
**Status:** parked
**Gated on:** `mermaid-to-md` npm package shipping (brief `2026-07-23-brief-mermaid-to-md-spinoff.md`)
**Needs:** more thought — this brief captures the idea and the design space, not a build plan

## What

An interactive layer on top of the `mermaid-to-md` CLI: while editing a `​```mmd` source block in a markdown file, the adjacent `​```text` art block updates live — either on a keystroke combo or as real-time virtual-text preview. The renderer is fast enough (<15ms) for per-keystroke updates. The batch tool produces the primitives; this layer composes on top.

## The two flavours

### Flavour 1: keystroke-triggered inject (simple, editor-agnostic)

Cursor is in a `​```mmd` block, you hit a key combo, `mermaid-to-md --inject <file>` runs, the adjacent art block updates. No custom editor, no plugin API — any editor that can bind a shell command to a keystroke (helix, neovim, kakoune, vim) supports it. The `--inject` mode from the parent brief is the entire implementation. Editor integration is one line of config. Costs nothing once the CLI ships.

### Flavour 2: live virtual-text preview (powerful, editor-specific)

You edit the source block and the art renders *beside or below* it in real-time as editor-rendered virtual text — not as file content, but as a live preview overlay. You see source and rendered diagram simultaneously, updating as you type. Requires a neovim plugin (or equivalent editor plugin API) — a real project, not a key binding. The art is not part of the file; it's a preview that the plugin manages.

## Why it's cool

The renderer is already fast enough for live preview — that's the enabling fact. The batch tool produces the primitives (`--inject` for update, `--verify` for staleness). The interactive layer calls those primitives; it doesn't replace them. The architecture composes cleanly: batch tool → keystroke binding (Flavour 1) → editor plugin (Flavour 2).

## Why it's parked

1. **The npm package hasn't shipped.** Flavour 1 is one line of editor config once `--inject` exists. There's nothing to build until the CLI is out.
2. **Flavour 2 is a real project** (neovim plugin, virtual text API, debounce logic, multi-diagram tracking). It needs someone who wants it enough to write the plugin.
3. **The design space needs more thought:**
   - Should the preview be inline (art block in the file) or overlay (virtual text, not in the file)? These are different products.
   - Should it update on every keystroke (debounced) or only on leaving insert mode? Latency vs. distraction.
   - Multi-diagram files: does the preview track only the cursor's block, or all blocks?
   - What happens when the source is invalid mid-typing? (The binary renders a fallback box — is that the right preview behaviour, or should it show "invalid syntax"?
   - Does Flavour 2 manage the art block in the file (like `--inject`), or is it purely a visual overlay that disappears when you close the editor?

## The WASM angle

If the live preview target is a web-based markdown editor (browser IDE, web note app), WASM is the right runtime — the native binary can't run in a browser. This is the one scenario where WASM is justified (not premature): a different editor ecosystem with a different runtime. The terminal path (native binary) serves terminal editors; the browser path (WASM) serves browser editors. Same renderer, different compile target. The terminal path comes first because it's our audience. The browser path is gated on demand from the browser-editor crowd.

This doesn't change the spin-off brief's Phase 4 deferral — WASM is still out of scope for the batch tool. It becomes relevant *here*, in the interactive layer, if and only if the target editor is browser-based.

## Sequencing (when unparked)

1. Ship the npm package (batch CLI with `--inject` and `--verify`)
2. Flavour 1: document the keystroke-binding config in the README (free — no code beyond the CLI)
3. Flavour 2: write the neovim plugin (or equivalent) — gated on someone wanting it
4. WASM build: gated on a browser-editor use case materialising

## Out of scope (until unparked)

- Building anything — this is a parked idea, not a build plan
- Choosing Flavour 1 vs Flavour 2 — they're complementary, not competing
- Editor choice (neovim is the obvious first target, but the design shouldn't be locked to it)
- WASM build (only relevant if the target editor is browser-based; the batch tool has rejected WASM — the bake step makes it superfluous for batch rendering. See spin-off brief.)
