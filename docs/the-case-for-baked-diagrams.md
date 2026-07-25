# the case for baked diagrams

*Or: isn't this the way it's supposed to be?*

**Written:** 2026-07-25
**Sibling:** `decisions/001-state-diagrams-for-agent-human-discussion.md` — the positioning decision this argues for
**Status:** position piece — distils a conversation, not a session debrief

---

## The observation

Diagrams in documentation break in every viewer except the one they were
authored in. A `mermaid` fence renders on GitHub's web preview and not in
`cat`, not in Glow, not in an email preview, not in the PR diff anyone
actually reads. This is treated as normal. It isn't normal; it's a
collective misalignment we've stopped noticing because it's everywhere.

## The diagnosis (systems, not villains)

Nobody is acting irrationally. GitHub renders Mermaid natively, so the
author writes a `mermaid` fence — path of least resistance, and it looks
great in the one place the author is looking. The cost — breakage in every
other viewer — is externalised to the reader, who isn't in the room when
the author hits save. That's an incentive structure, not a technology gap.
Better renderers won't fix it; the renderer is fine. The renderer is not
the thing that's broken.

## The structural fix

Three mundane moves, none of them clever:

1. **Bake the art into the text substrate.** The diagram becomes the file,
   not a program the file invokes. Zero viewer dependencies — it renders in
   `cat`, Glow, GitHub, any editor, a printer, a PR diff. The substrate *is*
   the distribution.

2. **Keep the source as a regeneration handle.** The art is a cache, not the
   source of truth. Lose the renderer and you still have regenerable source;
   lose the source and the art still reads. Stuff (source) preserved
   alongside the Thing (art) — the Stuff-into-Things move, with Stuff kept
   as a handle, not destroyed.

3. **Add a freshness check.** A cache without a freshness check is a lie
   waiting to happen. `--verify` re-renders each source block and diffs
   against the cached art; drift becomes a loud, CI-failable error instead
   of a silent rot. This is what separates a format from a ceremony — the
   format can prove it's current.

## The fidelity redirect

Yes, the text art isn't as pretty as a rendered SVG. *That's a "whatever."*

Fidelity is the wrong axis to optimise — arguing whether box-drawing art
matches a dagre layout is benchmaxxing for diagrams. The art is predictably
adequate: it raises the floor (every viewer, every time) without raising
the ceiling. The metric that matters is *"can the next person read this in
any tool, six months from now,"* and by that metric the renderer-dependent
default fails and the text version wins. The fidelity gap is the price of
adequacy, and adequacy was the goal.

`decisions/001` predicted this: *"the rendering is the how, not the what."*
Lived use confirms it. After you've read a few baked diagrams, you stop
noticing the fidelity gap — not because it vanished, but because it was
never the thing you were reading the diagram for. You were reading it to
understand the states. The art was adequate to that, so the gap became
noise. That's the "whatever" — not dismissal, but the correct
de-prioritisation of a problem solved adequately.

## Why state diagrams compound

The format earns its keep most clearly on state diagrams, because state
diagrams are the one diagram type whose value *compounds* with persistence.

A state diagram's job is to expose what other representations hide — the
missing state, the illegal transition, the terminal that isn't there. Prose
lets you skip a state; a ticket describes the happy path; a flowchart can
be complete as a *process* while the state space underneath it is full of
holes. A state diagram refuses that hedge: you list the states, you list
the transitions, you say what's terminal. The form demands enumeration, and
enumeration is what forces the overlooked into view.

On a whiteboard, that forcing function fires once, at design time. Baked
into the markdown next to the code — diffable, re-readable, co-located with
the implementation — it fires *repeatedly*, over the life of the system.
Every time someone re-reads it while touching the code; every time it lands
in a PR diff. Persistence converts a one-time forcing function into a
recurring one. That is the real value, and it is specific to a format that
bakes the art into the readable surface — not to "diagrams" in the
abstract. (See `decisions/001` for the positioning call this argues for.)

## The close

This isn't clever. It's the way it's supposed to be. The anomaly is that
"ship a renderer dependency and externalise the breakage" ever became the
default — and it became the default because the author pays none of the
cost. The fix is three mundane moves and a freshness check. The fidelity
gap is a feature: it's the price of adequacy, paid up front, so that six
months from now the diagram still reads in whatever tool the next person
happens to be in.

The diagram should be the file. The source should be preserved. The cache
should be checked. That's the whole pitch. The only surprising thing about
it is that it isn't already how every diagram in every repo works.
