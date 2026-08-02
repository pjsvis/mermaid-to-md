# brief: mermaid-to-md — art-first layout (flip the managed region)

**Created:** 2026-07-27
**Status:** ready to implement
**Decision:** `decisions/004-art-first-layout.md` (the format-defining choice this brief implements)
**Amends:** `decisions/003-verify-scope.md` (source-first → art-first)
**Depends on:** the shipped tool (bake/inject/verify wrapper, 54/54 tests)
**Phases:** 4 — decision+brief (this), wrappers+tests, re-bake, docs

## What

Flip the managed region's byte order from source-first to art-first.

**Current (decisions/003):**
````markdown
```mmd
<src>
```

<!-- mermaid-to-md:art -->
```text
<art>
```
````

**Target (decisions/004):**
````markdown
<!-- mermaid-to-md:art -->
```text
<art>
```

```mmd
<src>
```
````

The diagram is the product; the source is the checksum. The product goes
first. See `decisions/004-art-first-layout.md` for the full rationale.

## Why

Source-first contradicted the README's own positioning ("The diagram is
the product. The source is reference material"). Every reader scrolled
past a wall of Mermaid source before reaching the diagram. The complexity
meter (decision 003's rationale) is a real but secondary function —
served equally well below the art. Art-first honours the product-first
positioning without hiding the source (no `<details>`; flat, visible,
just below).

## Scope — four phases

### Phase 1: decision + brief (this document)

- `decisions/004-art-first-layout.md` — the format-defining decision.
- `briefs/009-art-first-layout.md` — this brief.

**Done when:** both files exist and cross-reference.

### Phase 2: wrappers + tests

The mechanical core. Both wrappers change; the test suite flips.

**`scripts/mermaid-to-md.sh`:**
- **Inject:** the `IN_MMD` state currently emits `​```mmd\n<src>\n​```\n\n<!-- sentinel -->\n​```text\n<art>\n​```\n`. Flip to `<!-- sentinel -->\n​```text\n<art>\n​```\n\n​```mmd\n<src>\n​```\n`. The `AFTER_MMD` / `SKIP_SENTINEL` / `SKIP_TEXT` states that consume the old managed region are unchanged — they still skip forward past old art. Old-format files convert on first re-inject.
- **Verify:** anchor changes from `​```mmd` to the sentinel. New state flow: `TEXT` → find sentinel → `IN_MANAGED` (expect `​```text`) → `IN_ART` (collect actual art) → `IN_MANAGED_SRC` (expect `​```mmd`) → `IN_SRC` (collect source, render expected, diff). Orphan `​```mmd` blocks found in `TEXT` state (no preceding sentinel) → `missing`.
- **Bake:** flip the emit order to match inject.

**`bin/mermaid-to-md.js`:**
- Mirror the bash changes exactly. The JS wrapper is functionally equivalent; the state machines are parallel.

**`scripts/test-inject.sh`:**
- Assertions that check source-first order (e.g. "bake source-first (mmd fence)") flip to art-first.
- New assertions: sentinel precedes `​```text` precedes `​```mmd` in bake output.
- Verify assertions: stale/missing/unclosed states exercise the new sentinel-anchored flow.
- Idempotency: re-inject on an art-first file stays art-first (no duplication, no reversion).

**Done when:** `just test` is green (all assertions pass), and a manual inject+verify on a test file confirms art-first output.

### Phase 3: re-bake all artifacts

Every baked file in the repo converts to the new format.

- `demo/mermaid-to-md-demo.md` — `just demo` (re-injects in place).
- `docs/form-lifecycle-diagram.md` — `--inject`.
- `agent-workflow-discussion.md` — `--inject`.
- `USAGE.md` — `--inject` (the baked state diagram in the usage guide).
- Any other file with `​```mmd` blocks — find and re-inject.

**Done when:** `just test` green (includes `demo-verify` and `check-docs`), and `--verify` passes on every baked file.

### Phase 4: docs

Update prose that describes the format or references decision 003.

- `USAGE.md` — the "Two signals, two remedies" section references source-first as the complexity meter. Reframe: the source is still a complexity meter, but a post-read check, not a pre-read warning. The baked state diagram in USAGE itself re-bakes in Phase 3.
- `README.md` — if it describes the output shape, update to art-first.
- `decisions/003-verify-scope.md` — add a dated addendum pointing to 004. Do not edit the original (decisions are frozen).
- `docs/the-case-for-baked-diagrams.md` — if it shows or describes the output shape, update.

**Done when:** no prose describes source-first as the current format; `check-docs` clean.

## Acceptance criteria

- [ ] Phase 1: `decisions/004-art-first-layout.md` and `briefs/009-art-first-layout.md` exist and cross-reference.
- [ ] Phase 2: `just test` green; both wrappers emit art-first; verify anchors on sentinel; orphan `​```mmd` blocks report `missing`.
- [ ] Phase 2: idempotent re-inject on art-first file stays art-first (no duplication, no reversion to source-first).
- [ ] Phase 2: old-format files (source-first) convert cleanly on first `--inject` (no duplicated art, no orphan sentinels).
- [ ] Phase 3: every baked file in the repo is art-first; `--verify` passes on all.
- [ ] Phase 4: no prose describes source-first as current; `decisions/003` has dated addendum pointing to 004; `check-docs` clean.

## The Derrida question

"Should this even be in our consideration set?" Yes — this is a
format-defining decision, same weight as 003. The tool is pre-1.0; the
format is not yet stable. Now is the time to get the reading order right,
not after consumers depend on source-first.

## The moat question

"Can you name your secrets?" The moat is the renderer. This is a
presentation-layer change — the byte order within the managed region. It
doesn't touch the renderer, the parser, or the box-drawing canvas. It
changes what the reader sees first, not what the tool can render. Channel,
not moat.
