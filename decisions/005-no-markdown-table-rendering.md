# decision: no markdown table rendering — pipe tables are already the product

**Created:** 2026-07-27
**Status:** rejected (a scope guard — this repo does not render markdown tables)
**Trigger:** a misrendered table observed during CLI testing (2026-07-27 session)
**Method:** the Derrida question ("should this even be in our consideration set?") applied before any eval or design. Recorded per the rejected-decisions-in-the-log practice.

## Context

During dogfood testing of the globally installed CLI, a misrendered table
sparked the idea: extend mermaid-to-md to render markdown pipe tables as
Unicode box-drawing tables, baked like diagrams (sentinel → art → source).

The idea died at the gate, before any implementation. This record exists so
the conclusion survives the session — the trigger (a misrendered table) will
recur, and without a record the analysis would be re-derived from scratch by
a memoryless future session.

## The Derrida question, applied

Four tests. The comparison column is the load-bearing one.

| Test | Diagrams (the incumbent case) | Tables (the candidate) |
|---|---|---|
| Brokenness | Break in every viewer except the authoring one — the anomaly this repo exists to fix | Pipe tables are legible in every viewer already: `cat`, PR diffs, email, Glow |
| Disclosure | Art *discloses* — topology, gaps, dangling nodes invisible in source | Art *decorates* — same information, aligned nicer; a Thing re-arranged, not Stuff made into a Thing |
| Checksum model (004) | Art is the payload, source is the checksum | Inverts: the pipe source *is* the payload; art would be a cache nobody reads; verify would guard a decoration |
| Moat | The renderer — ~5,200 lines of layout engine | Column alignment via `unicode-width`, ~100 lines; every terminal markdown viewer already does it |

The decisive test is brokenness. This repo's whole case (`docs/the-case-for-baked-diagrams.md`)
is that renderer-dependent diagrams are a collective misalignment. Pipe tables
have no such misalignment to fix. Rendering them adds ceremony (new fence
convention, verify states, tests, docs) with zero entropy reduction —
**Decorated Stuff**: format without substance.

Secondary: identity. The repo is *mermaid*-to-md, pre-1.0, npm channel still
pending (`td-6e3b3a`). Scope dilution before the first release is the
pizza-shop-turns-chip-pan-fire move.

## Decision

**Out of the consideration set.** Not "bad idea, deprioritised" — it does not
clear the gate that exists to stop us evaluating things that shouldn't be
evaluated. If re-raised, read this record before writing a brief.

## What would flip it (falsifiers — check before reopening)

1. A named external consumer that genuinely cannot read pipe tables.
2. Repeated evidence that wide tables fail to scan in real PR diffs.
3. A table engine sharing the renderer's layout intelligence in a way rivals
   can't replicate (i.e., an actual moat).

Absent one of these, the moat question answers "no secrets here."

## What this is not

- Not a rejection of *hardening the renderer* against non-diagram input.
  A table (or any prose) pasted inside a `​```mmd` fence currently renders as
  deterministic garbage — and `--verify` calls that garbage **fresh**, because
  it re-renders the same source and gets the same garbage back. A
  renderability signal (the renderer declaring "this is not a diagram I can
  honestly draw") so verify can fail it is in-set and remains a candidate.
- Not a decision about tabular data *authored as* a Mermaid diagram (no such
  type; a table drawn as a graph is worse than the table).

## Postscript — the meta-lesson

The trigger idea was expressed, gated, and rejected within one exchange — the
Derrida question did its job at the cheapest possible point: zero lines
written, zero ceremony created. The generalisable guards, kept for reuse:

- **Broken vs plainer:** render-adjacent ideas must clear "does the current
  form *break* in viewers?" — plainer is not brokenness.
- **One-sentence claims first:** if the idea can't survive being written down
  ("convert pipe tables to box art"), the brief never needed to exist.
