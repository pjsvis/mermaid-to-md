# brief: mermaid-to-md — bake rendered Mermaid art into markdown for Glow viewing

**Created:** 2026-07-23
**Status:** ready to implement (td epic td-14ca22)
**Depends on:** `mermaid-tui` binary — ✅ built (`target/release/mermaid-tui`)
**Sibling:** `scripts/mermaid-extract.sh` (the inverse: extract *from* markdown → terminal)

## What

A thin shell script (`scripts/mermaid-to-md.sh`) that takes Mermaid source (from a `.mmd` file or stdin), renders it to Unicode box-drawing art via the existing `mermaid-tui` binary, and emits a markdown file with the art embedded in a fenced code block — so the rendered diagram is visible in Glow, `cat`, or any markdown viewer that renders code blocks verbatim.

```
mermaid-to-md input.mmd > diagram.md
mermaid-to-md input.mmd -o diagram.md
echo 'graph TD\n  A --> B' | mermaid-to-md > out.md
```

## Why

We already have two rendering paths for Mermaid in this repo:

1. **`mermaid-tui`** — renders Mermaid source to Unicode art in the terminal (stdin → stdout).
2. **`mermaid-extract.sh`** — extracts `​```mermaid` blocks *from* a markdown file and renders them to the terminal on the fly.

Neither *persists* the rendered art. The terminal output is ephemeral — you render, you read, it's gone. If you want to share the diagram, you share the Mermaid *source* and hope the recipient has a renderer (GitHub's web preview, a VSCode plugin, or `mermaid-tui` itself).

This tool closes the gap. Render the art once, bake it into a markdown file, and the file is now self-contained: anyone with Glow (or `cat`, or any text viewer) sees the diagram without a Mermaid renderer. The diagram is plain text — diffable in git, greppable, copy-pasteable, no binary blobs, no SVG pipeline.

**The use case:** design docs, architecture notes, README diagrams that should be readable in the terminal, not just on GitHub. The "diagrams for docs" brief (`2026-07-23-brief-mermaid-diagrams-for-docs.md`) authors Mermaid *source* in markdown for GitHub's renderer. This tool serves the other audience — terminal-native readers who use Glow.

## How

### Phase 1: Standalone bake (the minimum useful thing)

`scripts/mermaid-to-md.sh`:

- Input: a `.mmd` file (path arg) or stdin (no arg / `-`)
- Renders via the `mermaid-tui` binary (same binary path resolution as `mermaid-extract.sh`)
- Emits a markdown file to stdout (or `-o <file>`) containing:
  - An optional H1/H2 heading (from a `--title` flag, or derived from the input filename)
  - A fenced `​```text` block with the rendered art
  - The original Mermaid source in a fenced `​```mmd` block (collapsible `<details>` optional, for readers who want the source)

**Why include the source, and why NOT in a `​```mermaid` block?** The baked art is the *product* — the canonical diagram, viewer-agnostic. The source is the *input*, preserved for regeneration and reference. But the source must NOT go in a `​```mermaid` fence, because GitHub renders that as a *second, live diagram* — visual collision. Two diagrams for one. The art block is the diagram; the source block is reference material, not a parallel render.

GitHub's Mermaid renderer triggers on exactly one info string: `mermaid`. Any other fence is plain text. So the source goes in a `​```mmd` fence — signals "mermaid source" to humans, unrendered by GitHub, still machine-extractable for regeneration.

**The principle:** the diagram is the product. The source is in a code block, but not one that is rendered. One diagram everywhere — Glow, GitHub, `cat`, anywhere.

**Output shape (default):**

````markdown
# <title>

```text
<rendered unicode art>
```

<details>
<summary>Mermaid source</summary>

```mmd
<source>
```

</details>
````

### Phase 2 (gated): In-place injection into existing markdown

The more powerful mode: given a markdown file that already has `​```mmd` source blocks, render each one and inject/replace a `​```text` art block immediately after it. The file serves the terminal-native audience — Glow shows the art, the source is plain text (not a second live diagram). If the file has `​```mermaid` blocks (GitHub-style), `--inject` converts them to `​```mmd` to avoid collision (see the Relationship section below).

This is gated on Phase 1 landing first and actual demand. The injection has idempotency concerns (re-running must not duplicate art blocks — detect/replace existing art blocks by a sentinel comment or paired-fence convention). Defer until the standalone bake proves useful.

### `--verify` mode (drift detection)

The art block is the checksum. If you re-render the source and the output differs from the existing art block, the diagram is stale — by definition. No hash needed. The verification logic is simply: re-render each `​```mmd` block, diff against the adjacent `​```text` art block, report stale diagrams.

```
mermaid-to-md --verify doc.md    → exit 0 if all fresh, exit 1 if stale (prints which)
mermaid-to-md --inject doc.md    → regenerate all art blocks in-place
```

`--verify` is CI-friendly: run it in CI to catch un-regenerated diagrams before merge. `--inject` is the fix. Both share the same render-and-compare logic. The sentinel comment from the inject mode marks which art blocks are tool-managed (so `--verify` doesn't flag manually-authored art blocks that happen to be near an `​```mmd` block).

## Acceptance criteria

### Phase 1

- [x] `scripts/mermaid-to-md.sh <file.mmd>` emits valid markdown with the rendered art to stdout
- [x] `mermaid-to-md.sh <file.mmd> -o <out.md>` writes the file
- [x] `echo 'graph TD\n  A --> B' | mermaid-to-md.sh` works from stdin
- [x] `--title "My Diagram"` sets the heading; default derives from filename
- [x] Output markdown renders the art block correctly in Glow (verified by eye)
- [x] Source block uses `​```mmd` fence (NOT `​```mermaid`) — GitHub shows it as plain text, not a second live diagram
- [x] Empty/blank input produces a valid (empty) markdown file, not a crash
- [x] Binary-not-built error message matches `mermaid-extract.sh` convention
- [x] Script is ≤40 lines of bash (31 lines)
- [x] No rendering logic in the script — it only wraps the binary's output

### Phase 2 (gated)

- [x] `mermaid-to-md.sh --inject <file.md>` finds `​```mmd` blocks and inserts/replaces art blocks after each
- [x] Re-running `--inject` on the same file is idempotent (replaces, not duplicates)
- [x] A sentinel convention marks injected art blocks (`<!-- mermaid-to-md:art -->` — see `decisions/002-sentinel-convention.md`) so they're detectable
- [ ] `mermaid-to-md.sh --verify <file.md>` re-renders each `​```mmd` block and diffs against the existing art block
- [ ] `--verify` exits 0 if all diagrams are fresh, exits 1 if any are stale (prints which are stale)
- [ ] `--verify` ignores `​```text` blocks not marked with the sentinel (doesn't false-positive on manually-authored art)
- [ ] `--verify` is CI-friendly (no side effects, clear exit code, machine-parseable output)

## Out of scope

- Rendering logic (the `mermaid-tui` binary owns that — the script is a wrapper)
- Mermaid syntax validation (bad syntax renders as a fallback box; that's the binary's behaviour)
- Colour/ANSI in the baked art (plain text is the point — ANSI codes would not survive in a markdown code block)
- Non-markdown output formats (RST, AsciiDoc)
- Interactive mode (fzf diagram picker, etc.)
- The Pi extension bridge (separate concern, separate brief if warranted)

## Relationship to existing briefs

- **`mermaid-extract.md`** (sibling): the inverse operation. Extract reads `​```mermaid` *from* markdown and renders to the *terminal*. `mermaid-to-md` reads Mermaid *from* a source file and writes rendered art *to* markdown. One round-trips source→terminal, the other source→markdown. Both are thin wrappers over the same binary.
- **`mermaid-diagrams-for-docs.md`**: authors Mermaid *source* in `​```mermaid` blocks for GitHub's renderer. **Deliberately different audience.** That brief serves web readers (GitHub's live SVG). This tool serves terminal readers (Glow's plain-text art). A doc should NOT carry both fence types for the same diagram — that causes visual collision on GitHub (art block + live render = two diagrams). If a doc needs both audiences, the Phase 2 injection mode appends the art block but **converts the source fence from `​```mermaid` to `​```mmd`** so GitHub stops rendering it. One diagram per viewer, not two.
- **`go-mermaid-renderer-01.md`**: the binary this tool depends on. Already built.

## The opinion

This is the Stuff-into-Things move applied to diagram sharing. Mermaid source is Stuff (structured, but not viewable without a renderer). Baked art in markdown is a Thing (structured *and* viewable anywhere). The pipeline is three Unix tools composed: `cat source.mmd | mermaid-tui | wrap-in-fence > out.md`. The script just makes the wrapping reproducible.
