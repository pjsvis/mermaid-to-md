# decision: art-first layout — the diagram is the product, the source is the checksum

**Created:** 2026-07-27
**Status:** decided
**Amends:** `decisions/003-verify-scope.md` (which established source-first as the output shape)
**Related:** `decisions/002-sentinel-convention.md` (the sentinel this builds on), `README.md` ("The diagram is the product. The source is reference material."), `USAGE.md` (the complexity-meter argument this demotes)

## Context

Decision 003 unified bake and inject output into one shape — source-first:

````markdown
```mmd
<src>
```

<!-- mermaid-to-md:art -->
```text
<art>
```
````

The rationale was the **complexity meter**: the source block is a terse
declaration of the diagram's structural weight; reading it first surfaces
the weight before the art's layout can tidy it away. A sequence diagram
packs ten events into a compact column; the source-first layout lets the
reader gauge the weight before the compact art hides it.

That rationale is real but secondary. The source's primary job in a baked
file is **regeneration** — the handle you pull to re-render. That job is
served equally well below the art. The complexity meter is a bonus, and
the bonus does not justify making every reader scroll past a wall of
Mermaid source before they see the diagram they came for.

## Decision

**Art-first.** The managed region is now:

````markdown
<!-- mermaid-to-md:art -->
```text
<art>
```

```mmd
<src>
```
````

The sentinel marks the start of the managed region (unchanged from 002).
The art follows immediately (what the reader came for). The source follows
the art — present, visible, flat (not `<details>`), but below the payload
it regenerates. **The source is a checksum**: it comes after the content,
not before it.

The sentinel's job (mark tool-managed art) is unchanged. Its position
relative to the source is what flips: sentinel → art → source, not
source → sentinel → art.

## Rationale

**1. The product goes first.** The README says "The diagram is the
product. The source is reference material." A product goes first;
reference material goes after. Source-first contradicted the positioning.
Art-first honours it.

**2. The checksum model is the better mental model.** A checksum comes
after the payload. You don't read the checksum first; you read the
content, and the checksum is there for verification. The baked art is the
content; the `​```mmd` source is the checksum. Art-first is the layout
that matches the model.

**3. The complexity meter is demoted, not lost.** The source is still
fully visible — no `<details>`, no click-to-reveal, no hiding. A reader
who knows to look can still gauge structural complexity from source
length. What changes is the reading order: the meter works as a
post-read check instead of a pre-read warning. For the
sequence-diagram-packs-ten-events case, the reader sees the compact art
first, then the long source below, and corrects their first impression.
Later correction instead of upfront warning. Weaker as a meter, stronger
as a reading experience. The trade is worth it: every reader sees the
diagram first, every time; the complexity-meter use case is niche.

**4. Not `<details>`.** Decision 003 retired `<details>` because "hiding
the source hides the meter." Art-first doesn't hide the source — it's
flat, visible, just below. The meter is visible without interaction; the
reading order changed, not the visibility. This is a different proposition
from `<details>` and a better one. 003's rejection of `<details>` stands.

## Consequences

- **Output shape changes.** `mmd → sentinel → text` becomes
  `sentinel → text → mmd`. Breaking for any consumer parsing the current
  format; acceptable because the tool is pre-1.0 and this is the
  format-defining decision (003 was never documented as stable beyond the
  repo).
- **Inject state machine:** minimal change. Still finds `​```mmd`,
  collects source, emits managed region. Emit order flips. The
  AFTER_MMD/SKIP_SENTINEL/SKIP_TEXT states still consume the old
  managed region that follows — old-format files convert on first
  re-inject.
- **Verify state machine:** anchor changes from `​```mmd` to the
  sentinel. Sentinel → art → source → diff. Orphan `​```mmd` blocks
  (no preceding sentinel) reported as `missing`.
- **All baked artifacts re-baked:** demo, USAGE.md,
  agent-workflow-diagram.md, docs/form-lifecycle-diagram.md, and any
  others. `--inject` on each converts to the new format; `--verify`
  confirms freshness.
- **Test suite updated:** assertions that check source-first order flip
  to art-first. New assertions verify the sentinel precedes the art
  which precedes the source.
- **Decision 003 amended, not contradicted.** 003's core insight — bake
  and inject share one output shape, `<details>` retired, verify governs
  both uniformly — stands. This record changes the *order within the
  shape*, not the shape's existence or the verify contract. 003 is a
  frozen decision record and is not edited; this record carries the
  amendment.

## What this is not

Not a change to the sentinel convention (002), the `​```mmd` fence name,
verify's exit codes, bake's `-o`/stdout semantics, or the wrapper CLI
interface. Only the byte order within the managed region changes.
