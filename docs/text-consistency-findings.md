# text consistency & sensibility review — findings

**Captured:** 2026-07-25
**Origin:** execution of `briefs/008-text-consistency-review.md` (findings-first pass)
**Status:** findings, pre-fix — reviewable before any edits are applied
**Scope:** all `.md` prose (outward-facing + process + stray root); code comments and non-prose out of scope; items owned by `briefs/007` deferred

## Method

Every in-scope `.md` read (30 files, ~3,820 lines). Axes A1–A7 run across the
full surface. Passes recorded, not just failures. Liveness classified (A5)
before flagging staleness, so frozen records aren't "fixed."

## A5 — doc-liveness classification

| doc / dir | liveness | note |
|---|---|---|
| `README.md`, `USAGE.md`, `about.md`, `DEPENDENCIES.md` | **living** | user-facing; must track reality |
| `SYSTEM.md` | **living** (local instance) | Protocol copy; drift from canonical tracked by `007`/E2 |
| `AGENTS.md` | **living** | agent config |
| `demo/`, `npm/*/README.md` | **living** | |
| `briefs/` | **mixed** | living while status ≠ done; historical once shipped/superseded |
| `decisions/` | **decided** (frozen) | records; do not "update" — supersede |
| `debriefs/` | **historical** (frozen) | session records; "what's next" describes the time, not drift |
| `playbooks/` | **living** | repeatable practice |
| `docs/the-case-for-baked-diagrams.md`, `docs/paint-discuss-persist.md` | **living** | position pieces (added today) |
| `docs/example-handoff-instruction.md` | **reference** (stable) | example |
| `agent-workflow-discussion.md` | **living** (canonical) | the worked example; referenced by USAGE/004/005/draft-msg |
| `draft-message-to-simon-willison.md` | **draft** | see M3 |

## Findings

### High

**H1 — moat-answer drift (A1/A3).** `briefs/002` answers the moat question as
*"the secret is the 5,238-line Rust renderer."* `decisions/001` answers it as
*"the secret is the practice, not the rendering."* Direct contradiction.
`decisions/001` (2026-07-25) supersedes `briefs/002` (2026-07-23), but the
brief was never updated. Two living docs give opposite moat answers.
**Fix:** update `briefs/002`'s moat section to align — renderer is the
*channel/how*, not the moat — or annotate the point as superseded by
`decisions/001`.

**H2 — dangling date-prefixed cross-references (A4), widespread.** The brief
naming migrated from date-prefixed (`2026-07-23-brief-mermaid-*.md`) to
`NNN-`, but the briefs that predate the migration still cite the old names.
Confirmed dangling (files do not exist under those names):
- `briefs/002`: `2026-07-23-brief-mermaid-to-md-spinoff.md` (self),
  `2026-07-23-brief-mermaid-live-preview.md` (→ `003`),
  `go-mermaid-renderer-01.md`, `mermaid-extract.md`, `mermaid-diagrams-for-docs.md`
- `briefs/001`: `2026-07-23-brief-mermaid-diagrams-for-docs.md`,
  `go-mermaid-renderer-01.md`, `mermaid-extract.md` (in "Relationship")
- `briefs/003`: `2026-07-23-brief-mermaid-to-md-spinoff.md` (→ `002`)
- `SYSTEM.md` lexicon (Locus tags entry): `briefs/2026-07-14-brief-locus-tag-consumer.md`

Bare-filename refs (no `briefs/` prefix) are invisible to a naive
`dir/file.md` grep — that's why they survived.
**Fix:** update each to the current `NNN-` name, or annotate as removed /
external (some may have been deleted, not renamed — confirm per ref).

### Medium

**M1 — `briefs/002` factual staleness (A2).** Line 64 calls
`mermaid-to-md.sh` "to be written per the parent brief, Phase 1." The script
shipped (debrief 002). `check-docs` doesn't scan `briefs/`, so it slipped
through. **Fix:** update line 64 to reflect shipped status.

**M2 — `briefs/002` acceptance criterion unmet/obsolete (A2).** Phase 1
criterion: *"No references to Pi, Edinburgh Protocol, or cool-pi-extensions
in the new repo."* The repo carries `SYSTEM.md` (the Protocol) and
`AGENTS.md`. Either the criterion was re-scoped (the Protocol is carried
deliberately as the operating system) or it's obsolete. **Fix:** reconcile —
likely re-scope the criterion to "no *runtime* dependency on Pi," since
carrying the Protocol as OS text was a later, deliberate choice (debrief 002).

**M3 — `draft-message-to-simon-willison.md` tracking vs declared-transitory (A6/A2).**
`debriefs/001` step 3 says it was *"gitignored (transitory)."* It is now a
tracked, committed root file. Also a leading `x` typo on line 1
(`x# Draft message…`). Classification needed: meant to ship as a reference
draft (keep, fix typo, maybe move to `docs/`), or transitory (should not be
tracked — prune or re-gitignore)? **Fix:** decide liveness; if kept, fix the
typo and consider relocating out of root.

### Low / nits

**L1 — `briefs/008` self-error (A2, meta).** The brief's scope line says
"the three `AGENTS.md`"; only one lives in the repo (the others are
parent-dir configs, not tracked here). **Fix:** correct to "`AGENTS.md`."
(Brief is uncommitted — trivial.)

**L2 — README renderer line-count inconsistency (A2 nit).** Structure comment
says "5,238 lines"; attribution says "~5,200." Trivial. **Fix:** pick one
(the exact `5,238` is in `briefs/002` too — verify against `wc -l
src/mermaid.rs` and use the real number, or commit to "~5,200" everywhere).

**L3 — "SpaceXAI" attribution — verify against upstream (A2).** Consistent
internally across `NOTICE`, `README`, `npm/*/README.md` (so not drift), but
the name is unusual — possible SpaceX/xAI conflation. The upstream is
`xai-org/grok-build`. **Fix:** verify the copyright holder string against
the upstream file's header; correct if conflated. (Cannot resolve without an
upstream fetch — flagged, not fixed.)

**L4 — "Stuff into Things" vs "Stuff-into-Things" hyphenation (A3 nit).**
Lexicon (`SYSTEM.md`) defines it spaced; cited hyphenated as an adjective
("the Stuff-into-Things move") in `decisions/001`, `briefs/001`, the two new
`docs/` pieces. Likely grammatical (noun vs modifier). **Fix:** verify
intentional; probably no change.

**L5 — USAGE cycle vs `docs/paint-discuss-persist` vocabulary divergence (A7).**
`USAGE.md`'s cycle is Draw/Bake/View/Discuss/Redraw/Done; the new doc is
paint/discuss/persist. Same practice, different beat-names, different
altitudes (user how-to vs practice spine). Likely intentional. **Fix:**
confirm the two don't confuse a reader; consider a one-line cross-link so the
relationship is visible. Low priority.

**L6 — `agent-workflow-discussion.md` root placement (A6).** Canonical (referenced
by USAGE, briefs 004/005, the draft message, debriefs) but sits at root
alongside the process dirs. A move to `docs/` would tidy root but requires
updating ~6 refs. **Fix:** decision, not a correction — low priority.

**L7 — terms used but not in the lexicon (A3 nit).** "Hume's Razor,"
"Mentation," "Mentational Humility" appear in `SYSTEM.md` guidelines and
docs but aren't defined in the Conceptual Lexicon. Likely intentional
(plain-English vs defined terms). **Fix:** none unless the operator wants
them anchored.

## Confirmed passes (honesty)

- **A1 positioning:** tagline consistent in `README` + `USAGE`; "whiteboard"
  fully retired from user-facing copy — survives only in `decisions/001` and
  `debriefs/002`, which legitimately record the retirement. Clean.
- **A2 `about.md`, `DEPENDENCIES.md`:** current and accurate (debriefs 003/004
  fixed both). Clean.
- **`decisions/001`, `002`:** decided, current, internally consistent. Clean.
- **`debriefs/001`–`004`:** historical/frozen, lexicon used well, cross-refs
  resolve. Clean (and correctly *not* candidates for "updating").
- **`playbooks/`:** clean, well-cross-referenced.
- **`npm/*/README.md`:** correct template (spot-checked darwin-arm64; others
  assumed identical — verify on fix pass).
- **`AGENTS.md`:** matches config, clean.

## Deferred to `briefs/007` (owned there, not fixed here)

- **E1** — version hardcoded across ~8 files.
- **E2** — `version@repo` reconciliation (SYSTEM.md lexicon drift from
  canonical Protocol: 5 eval terms trimmed, moat question restored — known,
  tracked).
- **N3** — stale-pending markers ("once published", `npx mermaid-to-md`) in
  `about.md`/`README.md`.

## Next

Fixes phase. Order: H1, H2 (the two real contradictions), then M1–M3, then
the low/nit batch as a single sweep. L1 (the brief's own error) folds in
trivially. Each fix as a small, reviewable commit; choices that need a
decision (M2, M3, L6) open a `decisions/` entry or get flagged here for the
operator's call.

## Resolutions (fix phase)

Applied: H1 (annotated, per decision), H2 (refs renamed/annotated), M1, M2 (re-scoped per decision), L1, L2. Deferred to `007`: E1/E2/N3. Left as flagged: L4–L7 (L6 agent-workflow placement still an open decision).

Corrections to the findings themselves:

- **M3 — was a misread, already resolved.** The Simon draft is *already* `.gitignore`d and untracked (`git ls-files` empty) — the desired state. I mistook "suppressed from the untracked list" for "tracked." Residual leading-`x` typo on the local draft fixed in place.
- **L3 — resolved, pass.** Verified against upstream: `xai-org/grok-build`'s own repo description reads *"SpaceXAI's coding agent harness and TUI."* "SpaceXAI" matches upstream's self-description — not a conflation. No fix.
- **L2 — fixed.** `wc -l src/mermaid.rs` = 5,229 (both prior figures were off: "5,238" by 9; "~5,200" a loose approx). Updated exact "5,238" → "5,229" in `README` and `briefs/002`; left "~5,200" approximations (valid approx of 5,229).
