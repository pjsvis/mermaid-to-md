# brief: propose Edinburgh Protocol v1.2.0 — phase-boundary handoff vocabulary

**Created:** 2026-07-25
**Status:** ready to deliver (to cool-pi-extensions, the Protocol's source of truth)
**Deliverable:** this brief, provided to cool-pi-extensions for triage
**Evidence base:** `debriefs/002-session-2026-07-25-ii.md`, `playbooks/phase-boundary-handoff.md`, `decisions/001-state-diagrams-for-agent-human-discussion.md`
**Baseline:** Edinburgh Protocol v1.1.0 (this repo's `SYSTEM.md`)

## What

A proposal to update the Edinburgh Protocol from **v1.1.0 → v1.2.0**,
capturing the phase-boundary handoff discipline as **new lexicon terms** plus
**one Operational Guideline line**. The detailed practice lives in
`playbooks/phase-boundary-handoff.md` (this repo); the Protocol gets the
*vocabulary* that practice is named with.

This brief is authored in the mermaid-to-md repo and **delivered to**
cool-pi-extensions, where the Protocol's source of truth lives. Authoring it
here keeps a record of what was proposed and why; adoption is cool-pi-extensions'
call.

## Why

Three reasons.

1. **The Protocol already foreshadowed this.** The v1.1.0 lexicon entries for
   `wrap-up` ("summarise what happened, persist the important parts, note
   what's left") and `locus tags` ("per-section compaction into the
   handoff/review — *future*") were explicitly scoped for a compaction step
   that did not yet exist. That future has arrived: debrief 002 + the
   phase-boundary-handoff playbook are that compaction, made concrete. The
   Protocol should name what it already promised.

2. **The lexicon proved it eats its own dog food.** Decision 001 resolved the
   project's tagline not by taste but by applying two lexicon entries — the
   moat question and the Derrida question — to the project's *own*
   positioning. A lexicon that earns its place in one real decision is worth
   extending with terms proven in the next. The evidence for extending is
   not theoretical; it is one decision and one bug.

3. **The failure mode is structural, not local.** The stale-path bug
   (`td-27b276`) came from an inherited assumption: brief 001 said *"same
   binary path resolution as `mermaid-extract.sh`,"* and that resolution was
   broken. Any *"do X like the existing thing"* instruction carries this
   failure mode — it is not specific to this repo. Terms that name a
   structural, repo-independent failure mode belong in the shared Protocol,
   not buried in one repo's playbook.

## How

### 1. New lexicon terms (the proposal's core)

Match the existing lexicon's format (term, definition, counterparts/prior art
where relevant).

- **Inherited assumption** — an assumption carried in from prior work (a
  brief, a sibling script, a convention) that the current phase did not
  verify. Distinct from an open question: a *question* blocks work; an
  *inherited assumption* is a latent bug. The failure mode behind the
  stale-path bug. *Counterpart action:* verify-on-entry.

- **Verify-on-entry** — the receiving phase's first act: execute an inherited
  reference once before relying on it. Don't inherit a convention you haven't
  seen run. Pays down handoff debt. *Prior art:* this repo's
  `playbooks/phase-boundary-handoff.md`.

- **Resumption instruction** — the one-line handoff entry that names the next
  phase's first move (command + file + first decision owed). The O(1)
  orientation that defeats the newup re-orientation cost. Lives in the
  `remaining` field. *Addresses:* debrief 001's finding that "the real
  friction is orientation on the far side of `/new`."

- **Handoff debt** *(candidate — maintainers' call)* — accumulated inherited
  assumptions; the aggregate that verify-on-entry pays down. Included if the
  "debt" framing earns its place; droppable without loss to the other three.

### 2. One Operational Guideline line

Add a single line under Operational Guidelines, pointing to the playbook
rather than inlining the detail:

> **Phase-boundary handoff** — at a real phase/session boundary, write a
> structured handoff (`done`/`remaining`/`decisions`/`uncertain`); see the
> repo's `playbooks/phase-boundary-handoff.md`. Within a session, the log
> suffices. *(Anti-ceremony: omit where no context was lost.)*

The Protocol owns the *term* and the *when*; the playbook owns the *how*.

### 3. Clarify the existing `wrap-up` entry

Add one sentence to the `wrap-up` lexicon entry: the wrap-up's output feeds
the structured handoff fields, not the freeform log. This closes the loop the
v1.1.0 entry left as "future."

### 4. Version bump

1.1.0 → 1.2.0. Changelog:

> *v1.2.0 (2026-07-25) — + phase-boundary handoff guideline; + lexicon terms
> (inherited assumption, verify-on-entry, resumption instruction[, handoff
> debt]); `wrap-up` entry clarified (feeds structured handoff fields).*

## Acceptance criteria

- [ ] Protocol v1.2.0 merges the new guideline + lexicon terms
- [ ] `wrap-up` entry clarified (output feeds structured fields, not log)
- [ ] This repo's `SYSTEM.md` syncs to v1.2.0 once adopted
- [ ] The guideline references `playbooks/phase-boundary-handoff.md` (or the
      adopting repo's equivalent)
- [ ] Changelog entry present, dated, with the evidence-base links

## Out of scope

- **The detailed handoff discipline** — lives in the playbook, not the
  Protocol. The Protocol must not accrete runbook detail.
- **The td feature request** (`uncertain: assumption|question` split,
  phase-first-class `remaining`) — deferred per concurrence; the discipline
  proves itself before the tooling is proposed. Tracked as a candidate, not
  filed.
- **The positioning lessons from debrief 002** (moat/Derrida questions
  applied to the project's own positioning) — those are *uses* of the
  lexicon, not changes to it. They validate extending the lexicon; they are
  not themselves lexicon entries.
- **Restructuring the Protocol** — additive only. No renumbering, no
  rephrasing of existing philosophy. v1.2.0, not v2.0.

## Relationship

- **`playbooks/phase-boundary-handoff.md`** (this repo) — the practice the
  Protocol's new terms point to. The Protocol owns the vocabulary; the
  playbook owns the practice.
- **`debriefs/002`** — the evidence base (four lessons; the
  verify-the-sibling lesson is the one this brief generalises).
- **`decisions/001`** — proof the lexicon eats its own dog food (justifies
  extending it rather than treating it as decorative).
- **Edinburgh Protocol v1.1.0** (`SYSTEM.md`) — the baseline being updated.

## The opinion

**Lexicon terms up to the Protocol; detailed discipline down to playbooks.**
The Protocol's secret — its moat, by its own question — is a compact lexicon
that gets *cited* in real decisions. Bloating it with every repo's runbook
detail would dilute that. The right division of labour: the Protocol owns the
*shared vocabulary* those details are named with (so two repos can talk about
"inherited assumptions" without re-deriving the term); each repo owns the
*local practice* where its evidence lives. Additive, lexicon-first, v1.2.0.

This is the moat question turned on the Protocol itself: the value is the
cited compactness, not the length. A Protocol that accretes detail is a
Protocol losing its moat.
