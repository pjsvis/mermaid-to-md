# playbook: phase-boundary handoff

**Captured:** 2026-07-25
**Origin:** session 2026-07-25 II (see `debriefs/002-session-2026-07-25-ii.md`)
**Worked example:** the `mermaid-extract.sh` stale-path bug (`td-27b276`, commit `9cb7dfb`)
**Reference:** `SYSTEM.md` (Edinburgh Protocol — `wrap-up`, locus tags), `td handoff`

## The pattern

At a phase boundary — across `/new`, across sessions, wherever context is
genuinely lost — the closing phase writes a **structured handoff** for the
opening phase. The opening phase has zero memory of the closing phase's
work. The handoff is not a log dump; it is a resumption kit, written for
the agent who replaces you.

## Why it works

1. **Context is lost at boundaries, not within sessions.** Within a
   session, the dialog *is* the memory. Across `/new`, it is gone. The
   handoff is the only thing that survives the boundary — which is why the
   ceremony guardrail below matters: a structured handoff where no context
   was lost duplicates the dialog and is entropy.

2. **Assumptions don't survive unspoken.** A brief says *"do X like the
   existing thing."* That is an inherited assumption. If it is not written
   into the handoff as an *assumption (not verified)*, it becomes a latent
   bug in the next phase — discovered only when someone trips on it. The
   handoff's job is to make inherited assumptions explicit so they can be
   checked, not inherited blind.

3. **Orientation is O(n) unless the handoff makes it O(1).** *"See session
   logs"* sends the next agent to read everything — the exact re-orientation
   cost the newup discipline exists to avoid. A one-line resumption
   instruction (next command + first file + first decision owed) collapses
   orientation to a single read.

## How to do it

1. **Don't let `td finish` auto-generate the handoff at a phase boundary.**
   `td log` → `td finish` populates the handoff from the log and leaves
   three of the four structured fields empty. At a real boundary, run
   `td handoff` with the fields deliberately *before* finishing. (Within a
   session, log + finish is fine — see the guardrail.)

2. **Use all four fields — `td handoff` already has them:**
   - **`done`** — what this phase produced: artifacts, commits, verified
     criteria.
   - **`remaining`** — the next phase's *first move*, as a one-line
     resumption instruction: the command to run, the file to read, and the
     first decision owed. Not *"see session logs."*
   - **`decisions`** — decisions made, *including decisions deferred* to
     the next phase (e.g. *"sentinel convention: deferred to Phase 2 —
     must be chosen before idempotency work"*).
   - **`uncertain`** — two sub-types, tagged:
     - `assumption:` — inherited from prior work, not verified this phase.
       This is the latent-bug slot. The one that catches the class of bug
       this playbook exists for.
     - `question:` — open, blocks work.

3. **Verify-on-entry — the receiving phase's first act.** Before relying on
   an inherited reference (a sibling script, a brief's *"same as X"*
   instruction), execute it once. Don't inherit a convention you haven't
   seen run. This pays down the handoff debt the prior phase flagged (or
   failed to flag) in `uncertain`.

4. **Write for zero memory.** State the obvious. Name files by path. Flag
   every assumption. The handoff is not for you; it is for the agent who
   replaces you at the next `/new`.

## When to use it

- Across `/new` — the canonical case.
- Across sessions, even without `/new`.
- When the next phase is a different td task that will start fresh.
- When the next phase depends on a decision this phase deferred.

## When not to use it (ceremony)

- Within a single session — the dialog is the memory; a structured handoff
  duplicates it.
- For a trivial fix — log + finish suffices.
- When the "next phase" is the same agent continuing without a context
  break.

A structured handoff where no context is lost is entropy, not anti-entropy.
The Protocol's locus-tag rule applies: omit when there is no underlying
structure to section.

## The worked example

Brief 001 instructed *"same binary path resolution as `mermaid-extract.sh`."*
That was an inherited assumption. It was not verified at Phase 1 entry. It
was stale — post-spin-off, the binary had moved to the repo root, and
`mermaid-extract.sh` was unrunnable, dying on "build first" against a built
binary.

The bug surfaced mid-implementation, not at entry. The handoff's `uncertain`
slot was empty. Cost: one diagnostic detour plus a follow-up task
(`td-27b276`).

Had the entry handoff carried one line — `uncertain: assumption —
mermaid-extract.sh path resolution (not re-verified)` — the first act of
Phase 1 would have been `bash scripts/mermaid-extract.sh <test>`. The bug
would have surfaced in five seconds, and the fix would have landed *before*
the wrapper was written, not after.

## The meta-lesson

The schema was already there — `td handoff`'s four fields. Three went
unused because the default finish flow auto-generates from the log. **The
gap was discipline, not tooling.** Don't propose a feature where a habit
suffices; that is the bar the deferred td feature request must clear before
it is filed.
