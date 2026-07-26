# decision: verify scope — bake and inject share one output shape

**Created:** 2026-07-26
**Status:** decided
**Resolves:** B1 (`briefs/007-outstanding-issues-and-nits.md`) — `--verify` flags every
baked diagram as `missing`, because bake output wrapped the ```` ```mmd ````
source inside a `<details>` block with no following sentinel+art region.
**Related:** `decisions/002-sentinel-convention.md` (the sentinel this extends),
`briefs/007` item B1, `docs/the-case-for-baked-diagrams.md` (the position this
confirms)

## Context

`--verify` re-renders each ```` ```mmd ```` block and diffs the result against
the art in the *following managed region* (sentinel + ```` ```text ````, per
`decisions/002`). A ```` ```mmd ```` with no following managed region is
`missing` — exit 1. That is the intended behaviour for inject-mode files: a
source block the author forgot to render is exactly the rot verify exists to
catch.

Bake mode, however, emitted a *different* shape:

````markdown
```text
<art>
```

<details>
<summary>Mermaid source</summary>

```mmd
<src>
```

</details>
````

The ```` ```mmd ```` sits inside `<details>`, last, with no following
sentinel+art. So `--verify` on any freshly baked file (including
`demo/mermaid-to-md-demo.md`) reported `missing` at every diagram and exited 1.
Repro: `scripts/mermaid-to-md.sh --verify demo/mermaid-to-md-demo.md` → 3×
`missing`, exit 1.

`briefs/007` framed this as a design decision with three options:

- **(a)** verify skips ```` ```mmd ```` inside `<details>` (recognise bake
  output structurally).
- **(b)** verify governs only ```` ```mmd ```` blocks that should have a
  following sentinel — inject-mode-only; bake output out of scope by default.
  *(brief recommended)*
- **(c)** a flag (`--verify --bake` / `--strict`) selects the mode.

## Decision

**(d) Unify the output shape.** Bake produces the *same managed pair* as
inject — source-first, with the sentinel, no `<details>`:

````markdown
```mmd
<src>
```

<!-- mermaid-to-md:art -->
```text
<art>
```
````

Verify's logic is unchanged. It now governs bake output too, because bake
output is structurally an inject-mode file: every ```` ```mmd ```` is followed
by its sentinel+art. B1 dissolves — there is no bake-specific case to detect,
scope, or flag.

## Rationale

**1. Uniformity beats special-casing.** Options (a) and (b) both concede that
bake output is a second class of file verify must handle differently — (a) by
detecting `<details>` structurally, (b) by declaring bake out of verify's
scope. Both split the world into "files verify checks" and "files it doesn't"
along a line that is invisible to the reader. (d) removes the line: there is
one output shape, one verify path, one freshness contract. The `<details>`
detection in (a) is especially fragile — it couples verify to a presentation
wrapper that nothing else depends on.

**2. Source-first is the complexity meter.** The source block is a terse,
scannable declaration of the diagram's structural weight; the art is the
committed spatial claim. Reading source-first surfaces the weight *before* the
layout can tidy it away (a sequence diagram packs ten events into a compact
column, hiding the weight the source declares). Wrapping the source in
`<details>` makes the meter opt-in — the reader has to *ask* to see the
complexity rather than having it surface. The flat, source-first layout makes
the meter a first-glance check. (See `USAGE.md` — "Two signals, two
remedies.") This is the same anti-entropy instinct as the tool itself: don't
hide the thing that reveals the rot.

**3. Bake and inject are one operation at two scales.** Bake renders a single
source block into a fresh file; inject renders each source block in an
existing file. If both produce the same managed pair, a baked file *is* a
valid inject-mode artifact: re-inject is idempotent, verify is fresh, the
source is a regeneration handle and the art is a cache — exactly the contract
`docs/the-case-for-baked-diagrams.md` argues for. The `<details>` format broke
that identity: a baked file was not re-injectable (inject would insert a
*new* managed pair after the ```` ```mmd ````, duplicating the art) and not
verifiable. Unifying restores it.

**4. Reconciles with `decisions/002`, does not contradict it.** `decisions/002`
defined the sentinel's *intent* — distinguish tool-managed art from
user-authored ```` ```text ```` — and framed its *contract* around inject
because inject was the only producer using it at the time. Nothing in 002
forbids bake from emitting the sentinel; 002's scope was the convention's
shape, not the set of producers. This record extends the contract: **bake
creates the pair**, as a sibling to 002's "inject creates the pair." The
sentinel's job (mark tool-managed art) applies to any file the tool produces;
a baked file is tool-produced. Evolution, not contradiction.

## Consequences

- **Bake output shape changes.** ```` ```text ```` + `<details>`/```` ```mmd ````
  → ```` ```mmd ```` + sentinel + ```` ```text ````, source-first. Breaking for
  any consumer parsing the old bake format; acceptable because the tool is
  pre-1.0 and this is the format-defining decision (the prior format was never
  documented as stable).
- **`<details>` retired** from bake output. The wrapper, the demo, `USAGE.md`,
  and `agent-workflow-discussion.md` are re-baked in the unified shape.
- **B1 resolved.** `--verify` on a freshly baked file exits 0. A regression
  test (`bake-then-verify`) is added to `scripts/test-inject.sh` to lock it in.
- **`decisions/002`'s contract gains a sibling clause** ("bake creates the
  pair"). 002 is a frozen decision record and is not edited; this record
  carries the extension.
- **`demo/mermaid-to-md-demo.md`** is now a living inject-mode artifact (it was
  already multi-diagram, inject's use case). `just demo` re-renders it;
  `just demo-verify` checks freshness without side effects.

## What this is not

Not a decision about bake's title behaviour (filename-derived `# heading`
remains), bake's `-o` / stdout semantics, the trailing-newline correctness of
the bash `while read` loops (that is B2, `briefs/007`, tracked separately as
`td-774a89`), or Phase 3's release/packaging hygiene. Those are owned
elsewhere.
