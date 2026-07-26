# brief: mermaid-to-md — repo text consistency & sensibility review

**Created:** 2026-07-25
**Status:** ready to implement (no td issue yet — create on adoption)
**Depends on:** the shipped tool + the accumulated prose surface (README, USAGE, about, SYSTEM, briefs/, decisions/, debriefs/, playbooks/, docs/, demo/)
**Sibling:** `briefs/007-outstanding-issues-and-nits.md` — code/CI/distribution loose ends; this brief is the *prose* counterpart (distinct object, no overlap)
**Reference:** `debriefs/004` (the doc-rot lesson this generalises), `decisions/001` (the positioning sweep this confirms)

## What

A bounded, one-pass review of the repo's prose surface for consistency and
sensibility — the cleanup after a burst of work across multiple sessions
(four debriefs on 2026-07-25 alone, plus the position pieces added today).
Text accumulates drift faster than code, and drift is silent: `just
check-docs` catches stale-marker *phrases* in the *standard docs* only, but
it does not scan `briefs/`, `decisions/`, `debriefs/`, `playbooks/`,
`docs/`, and it cannot catch semantic drift (positioning, terminology,
dangling cross-references, mis-classified doc liveness). This brief scopes
the manual, semantic review that closes that gap.

Findings-first: produce a findings list (per axis, per file,
severity-tagged) *before* applying fixes, so fixes are reviewable and the
review doesn't quietly rewrite things. Then apply fixes as a follow-up
commit, or open a `decisions/` entry where a choice is needed (e.g.,
classifying an ambiguous doc as living vs historical).

## Why

`debriefs/004` caught one instance by accident: `about.md`/`README.md`
claimed the wrapper was "to be written" after it had shipped across four
commits. That was the symptom of a missing feedback path, fixed with `just
check-docs`. But the same shape of rot — a doc describing a state that is
no longer the state — exists in dirs `check-docs` doesn't scan, and in
forms `check-docs` can't match. Two confirmed instances already:

- **Staleness in an unscanned dir.** `briefs/002` describes
  `mermaid-to-md.sh` as "to be written" (line 64). The script shipped.
  `check-docs` scans standard docs only, so this slipped through.
- **Dangling cross-references.** `briefs/001` references
  `2026-07-23-brief-mermaid-diagrams-for-docs.md` and
  `go-mermaid-renderer-01.md` — neither exists under those names (renamed
  to the `NNN-` convention or removed). Bare-filename references are
  invisible to a naive `dir/file.md` grep, which is why they survived.

And one confirmed *pass*, for honesty: the `decisions/001` "whiteboard"
retirement sweep is clean — "whiteboard" survives only in the decision and
debrief that legitimately record its retirement, not in user-facing copy.
The review's job is to *confirm* sweeps like this, not to assume drift.
Some axes will pass; the value is running them all systematically rather
than noticing the failures by accident.

## The axes

Organised by what they check. Each is a pass / fail / investigate question
applied across the in-scope surface.

### A1: Positioning consistency

Does every user-facing surface reflect `decisions/001`? Tagline current
("State diagrams for agent–human discussion. Baked into markdown, visible
anywhere."), "whiteboard" retired, "shared cognitive artifact" used where
the shared-surface sense is meant. [Sample: the "whiteboard" sweep passes —
confirm across all surfaces, don't assume.]

### A2: Factual staleness

Does each doc describe the *current* state of the tool? Shipped features
not described as planned; planned features not described as shipped. The
gap `check-docs` doesn't cover: `briefs/` / `decisions/` / `debriefs/` /
`playbooks/` / `docs/`. [Confirmed: `briefs/002` line 64.]

### A3: Terminology consistency

The repo carries a defined lexicon (`SYSTEM.md`'s Conceptual Lexicon, the
Edinburgh Protocol terms, the tool's own vocabulary: bake/inject/verify,
`mmd` fence, sentinel, shared cognitive artifact). Are terms used
consistently? Retired terms gone? No loose synonyms for defined terms
(e.g., "whiteboard" where "shared cognitive artifact" is meant; "render"
where "bake" is the defined verb)?

### A4: Cross-reference integrity

Do all references resolve? Both prefixed (`briefs/00X-…`) and
bare-filename (`go-mermaid-renderer-01.md`). Is numbering sequential? Are
there references to renamed/deleted files? [Confirmed: `briefs/001` has
two dangling bare-filename refs.]

### A5: Doc-liveness classification

Not every doc should stay current. A debrief is a frozen record of a
session; a living brief must track reality. *Classify before fixing*:
updating a historical debrief to "current" muddles its provenance (the
categorise-by-nature-not-origin lesson from `debriefs/004`). Tag each doc
living | historical | draft; only living docs carry a staleness obligation.

### A6: Stray/draft hygiene

Root-level `agent-workflow-discussion.md` and
`draft-message-to-simon-willison.md` — tracked, committed, not in a
process dir. Classify: canonical (move to a dir), draft (mark or move to a
drafts area), or orphan (prune). "Clean up afterwards" includes deciding
what these are.

### A7: Voice/tone

Lower priority. The repo has a strong, specific voice (dry, precise,
lexicon-grounded). Flag gross drift into generic/corporate register only.
Do not gold-plate style.

## Scope

**In:** all `.md` prose — outward-facing (`README`, `USAGE`, `about`,
`SYSTEM`, `DEPENDENCIES`, `NOTICE`, `AGENTS.md`, `demo/`) +
process (`briefs/`, `decisions/`, `debriefs/`, `playbooks/`, `docs/`) +
stray root docs (`agent-workflow-discussion.md`,
`draft-message-to-simon-willison.md`).

**Out:** code comments (`src/`, `scripts/`, `bin/`) — a separate pass if
warranted; non-prose (`Cargo.toml`, `package.json`, `ci.yml`, `justfile`,
`.js`).

**Deferred to `007`** (owned there, not duplicated here): E1
version-hardcoding across ~8 files, E2 `version@repo` reconciliation, N3
stale-pending markers in `about.md`/`README.md`. This brief notes if it
trips over them; it does not fix them.

## Acceptance criteria

- [ ] A findings doc exists (in `docs/` or as a `debriefs/` entry),
      severity-tagged per axis per file.
- [ ] A1–A7 each run across the full in-scope surface; passes recorded,
      not just failures.
- [ ] Dangling cross-references (A4) resolved — updated to current names
      or annotated as removed.
- [ ] Each doc tagged living | historical | draft (A5); only living docs
      carry forward a fix obligation.
- [ ] Stray root docs (A6) classified; moved, marked, or pruned.
- [ ] Fixes applied as a follow-up commit (or a `decisions/` entry where a
      choice is needed).
- [ ] Items owned by `007` (E1/E2/N3) noted, not fixed here.

## Relationship to existing mechanisms

- **`just check-docs`** (`debriefs/004`): automated stale-marker scan,
  *standard docs only*. This brief is the manual, semantic complement —
  all prose dirs, all axes. Possible follow-up (separate brief if
  warranted): a dangling-cross-ref checker script to mechanise the
  prefixed-ref case; bare-filename refs stay manual.
- **`briefs/007`**: the code/CI/distribution counterpart. Distinct object;
  this brief defers to it on E1/E2/N3.
- **`playbooks/elision-and-deferral.md`**: this is deferral's bookkeeping —
  same framing as `007`. A deferred cleanup not written down dies at the
  boundary; this brief is the written-down deferral.

## The Derrida question

"Should this even be in our consideration set?" Yes. Drift compounds after
a burst of work; the review is cheap to run once; two confirmed gaps
(`briefs/002` staleness, `briefs/001` dangling refs) prove real entropy
beyond what `check-docs` catches. The cost of *not* doing it is that the
next reader trusts a doc that lies — the same failure mode `debriefs/004`
caught by accident.

## The moat question

"Can you name your secrets?" No — this is hygiene and bookkeeping, not the
moat. Same framing as `007`: the moat is the practice (per `decisions/001`);
this is the cleanup that keeps the practice's artefacts trustworthy. None
of it touches the moat.
