# playbook: elision and deferral

**Captured:** 2026-07-25
**Origin:** session 2026-07-25 IV (the conversation after `debriefs/003`)
**Worked example:** the "proce of fish" typo (below) — deferral admits the gap, elision papers over it
**Reference:** `SYSTEM.md` (locus tags, wrap-up, anti-ceremony), `playbooks/phase-boundary-handoff.md`

## The pattern

Two tools for keeping a conversation tractable. They act on different
things, so they're independent — you can use either without the other:

- **Elision** acts on *content*. Drop the derivation, keep the conclusion.
  Risk: losing something you later need.
- **Deferral** acts on *decisions*. Keep the question, postpone the
  resolution. Risk: the question never comes back — a lost thread.

## Why it works

1. **Two overload sources, two tools.** A conversation drowns in too much
   content or too many open decisions — usually both. Elision compresses
   the first; deferral parks the second. They pair because the sources are
   distinct, not because the tools are alike.

2. **The breath is the error-correction channel.** In human conversation,
   elision and deferral are safe to use sloppily. Elide too hard and the
   other party pulls the detail back at a pause — *"wait, what did you mean
   by X?"* Defer and forget, and they re-raise it at the next gap — *"and
   the other thing…"* The breath isn't just rhythm; it's what catches the
   failure modes of both tools. They're permitted to be approximate
   *because* correction is cheap and near-instant.

3. **The agent-human loop replaces the breath with the turn boundary.**
   Same two tools, different price for getting them wrong — which inverts
   how carefully each is used (next section).

## How to do it (the inversion)

Correction is per-turn, not per-breath. So the agent uses the two tools at
*opposite* conservatism to a human:

- **Elide sparingly.** Over-elision at sentence 3 compounds to sentence 30
  before the human can correct it — a whole wasted turn, not a half-second
  pause. When the conclusion is load-bearing, keep the derivation.

- **Defer aggressively — but record it.** The turn boundary is a clean
  decision point, so deferral fits the loop well. But a deferred decision
  that isn't written down dies at the boundary. Deferral is only safe when
  it's durable: in a handoff's `decisions deferred`, a wrap-up's *"what's
  left"*, an `uncertain: question` slot. Vague postponement is a lost
  thread.

Rule of thumb: humans elide freely and defer loosely (the breath rescues
both); agents elide sparingly and defer rigorously (the turn boundary
punishes loose deferral, and there's no breath to rescue an over-elision).

## What this explains about the Protocol

The Protocol's pieces are elision and deferral engineered for a medium that
doesn't ship with breaths:

- **Locus tags manufacture breath.** They section a turn into navigable
  phases, giving the human a *designed* pause to intervene at — the thing a
  human conversation gets for free from rhythm.
- **Anti-ceremony is elision at the format layer.** Omit locus tags on a
  single-phase turn; don't add structure with no underlying need. Same
  release valve, applied to format.
- **Wrap-up is deferral's bookkeeping.** It carries *"what's left"* across
  the turn so a deferred decision survives instead of silently dropping.
  The `uncertain: assumption` vs `uncertain: question` split is deferral
  with the thread made explicit.

## The worked example

Mid-conversation the user typed *"the proce of fish"* — a typo. Two
responses were available:

- **Elide the not-knowing:** silently guess, confabulate a meaning, move on.
  The sycophantic move — papers over the gap.
- **Defer the judgement:** say *"I can't fully decode that, I won't
  fabricate a reading"* (Hume's Razor), offer a best inference *flagged as
  inference*, and let the human confirm at the next turn. The honest move —
  admits the gap, keeps the thread open.

The honest agent defers; the sycophant elides the not-knowing. The typo
that names the loop's limit illustrates the loop's error-correction: in a
human conversation the breath would have caught it in half a second; in
the turn-based loop, deferral is what carries the gap to the next pause
without pretending it isn't there.

## When to use it

- **Elide** when the conclusion is what's load-bearing and the derivation
  is recoverable or asked-for. In the agent-human loop, lean toward keeping
  the derivation — the breath isn't there to rescue an over-elision.
- **Defer** when a decision can't be made cleanly now but the thread must
  survive the turn. Always record the deferral — handoff, wrap-up, or an
  explicit *"deferred: …"* note.

## When not to use it (ceremony)

- **Don't dress deferral up as a decision.** *"We'll work it out later"* is
  deferral; calling it *"resolved: defer to phase N"* is overwrought. Name
  it as deferred and move on.
- **Don't elide the not-knowing.** If you don't know, defer the judgement
  (say so) rather than elide the gap (pretend you do). The former is
  honesty; the latter is sycophancy.
- **The bar for writing about this at all.** The label this insight nearly
  acquired — *"ontological orthogonality mechanism"* — is the example of
  what to avoid: a plain pair of tools dressed in academic Latinate. If
  the writeup drifts into that register, rewrite it in plain words or cut
  it. The insight is two tools and an inverted conservatism. That's the
  whole of it.

## The meta-lesson

Elision and deferral are how humans get through conversations. The
agent-human loop doesn't ship with breaths, so it has to engineer them —
and invert the conservatism the breath used to guarantee. The Protocol's
locus tags and wrap-up are that engineering. The naming is overwrought; the
using is the work.
