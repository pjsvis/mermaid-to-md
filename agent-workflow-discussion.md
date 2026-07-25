# Agent workflow — a state diagram for discussion

> Rendered with `mermaid-tui`, baked into this file. Open in Glow (or `cat`)
> to see the diagram. No Mermaid renderer required. The art is the product;
> the source below is reference material.

This document is a conversation piece, not a spec. It models the **td + briefs
workflow** that the agent and the human use to manage work in this repo, as a
state diagram — then surfaces what the diagram reveals.

## The diagram

```text
                 ╭───╮
                 │ ● │
                 ╰─┬─╯
                   │
                   ▼
             ╭───────────╮
             │ Unstarted │
             ╰─────┬─────╯
                   │
                   ▼td usage --new-session
             ╭──────────╮              td context resume
             │ Oriented │◄───────────────────────────────┐
             ╰─────┬────╯                                │
                   │                                     │
                   ▼td usage -q, pick task               │
              ╭─────────╮                  human responds│
              │ Working │◄───────────────────────────────┼┐
              ╰────┬┬───╯                                ││
      ┌────────────┴┼───────────┐                        ││
      ▼need human in▼ut         ▼task complete, debrief  ││
 ╭─────────╮   ╭─────────╮  ╭──────╮                     ││
 │ Blocked ├───│ Handoff │──│ Done ├─────────────────────┼┴┐
 ╰────┬────╯   ╰────┬────╯  ╰──────╯                     │ │
      └────────┐    └────────┐                           │ │
               ▼no response i▼/N                         │ │
           ╭───────╮   ╭───────────╮                     │ │
           │ Stuck │   │ Compacted ├─────────────────────┘ │
           ╰───┬───╯   ╰───────────╘                       │
               └──────┐                                    │
                      ▼abandon                             │
                    ╭───╮                                  │
                    │ ● │◄─────────────────────────────────┘
                    ╰───╯
```

<details>
<summary>Mermaid source</summary>

```mmd
stateDiagram-v2
    [*] --> Unstarted
    Unstarted --> Oriented: td usage --new-session
    Oriented --> Working: td usage -q, pick task
    Working --> Blocked: need human input
    Blocked --> Working: human responds
    Blocked --> Stuck: no response in N
    Working --> Handoff: phase boundary, td handoff
    Handoff --> Compacted: /new
    Compacted --> Oriented: td context resume
    Working --> Done: task complete, debrief
    Done --> [*]
    Stuck --> [*]: abandon
```

</details>

## What the diagram is

Each node is a **state of a unit of work** (a session's worth of effort), not
a state of the agent or the human. Transitions are the events that move work
between states. The `td` commands are the transition labels — the mechanism,
not the state.

- **Unstarted** — a fresh `/new`, nothing loaded.
- **Oriented** — `td usage --new-session` + `just orient` have run; the agent
  knows where it is.
- **Working** — a bounded task is in progress.
- **Blocked** — the agent needs the human and cannot proceed alone.
- **Handoff** — a phase boundary; `td handoff` has persisted the state.
- **Compacted** — `/new` has cleared context; the next session is cheap.
- **Done** — work complete, debrief written.
- **Stuck** — blocked with no response. The dangling edge.

The two loops are the interesting structure:

1. **Working ↔ Blocked** — the inner loop. Agent hits a wall, human unblocks.
   Most entropy enters here.
2. **Oriented → Working → Handoff → Compacted → Oriented** — the outer loop.
   This is the bounded-phase discipline from `AGENTS.md`: half a dozen newups
   in a long session keeps cost O(n), not O(n²). The loop *is* the cost
   control.

## What the diagram surfaces

This is the user's thesis, and it holds: drawing the states forces the
underspecified bits into view. Three things this diagram reveals that prose
would let slide:

**1. `Stuck` has no timeout.** The label says "no response in N" but `td`
has no expiry. There is no `td stuck` or `td expire`. The transition
`Blocked → Stuck` is a *vibe*, not a mechanism. In reality `Blocked` and
`Stuck` are the same state — the agent is just sitting there. The diagram
makes this dishonesty visible: I drew a distinction the tooling doesn't
enforce. Either `td` grows a timeout, or `Stuck` collapses into `Blocked` and
the only exit is the human or abandonment.

**2. No transition `Blocked → Handoff`.** You cannot hand off while blocked.
That sounds right — you can't persist state you don't have — but it means a
session that blocks near a phase boundary has no graceful exit. The only paths
out of `Blocked` are *human responds* or *abandon*. There is no "park the
question and hand off the rest." That's a real gap in the workflow, and it's
only visible because the diagram refuses to let me draw an edge I can't
justify.

**3. `Done` and `Stuck` both terminate, but they are not symmetric.** `Done`
is a *successful* terminal; `Stuck` is a *failed* one. In the diagram they
both hit `[*]`, which flattens the difference. A richer model would split the
terminal — but for a discussion diagram, the flattening is the point: it asks
"should these feel the same?" They shouldn't. A debrief on `Stuck` is
arguably more valuable than one on `Done`, because the entropy is in the
failure. The diagram makes me notice I have no `Stuck → Debrief` edge.

## Where briefs live

Briefs are **artifacts**, not states, so they don't appear as nodes. They flow
*through* the states: a brief is drafted during `Working`, decided during
`Working`, implemented across the outer loop, and closed with a debrief at
`Done`. If we wanted to model briefs as first-class, we'd need a parallel
state machine (drafted → decided → implemented → debriefed) and the two
machines would couple at `Working` and `Done`. That's a second diagram, for a
second conversation. The first diagram already earned its keep by surfacing
the three gaps above.

## Opinion

The thesis is sound. A baked state diagram is an efficacious channel for
agent–human system design talk, for three reasons that are not the reasons
one might expect:

**It's not about the picture being pretty.** It's that the act of drawing it
is a *commitment*. Prose is reversible — you can hedge, qualify, and leave
edges implied. A state diagram forces you to name every state and draw every
transition, and any transition you can't draw is a gap you have to either
fill or admit. The three gaps above were not found by thinking hard; they
were found by trying to draw edges and finding I had nowhere to put them.
That's Hume's Razor applied to design: the diagram exposes where my model
exceeds my evidence.

**Baking beats live rendering for this use.** The user has Glow open beside
Pi. A baked diagram is visible *in the same medium as the prose* — they read
the diagram and the commentary in one scroll, in the terminal, with no
context switch to a browser or a renderer. A live Mermaid block would force a
renderer switch and break the reading flow. The diagram and the argument
about the diagram inhabit the same surface. That is the whole pitch of this
repo, and this document is a dogfood of it.

**State diagrams are the right diagram type for workflows.** Flowcharts show
*what happens*; state diagrams show *where things can be* and *what is
impossible*. For a workflow, the impossible transitions are the design
constraints. "You cannot hand off while blocked" is a constraint, not a step,
and a state diagram expresses it as a *missing edge* — which is exactly the
shape of a dangling-node smell. Flowcharts hide constraints by only showing
permitted paths. State diagrams make you earn every permitted path and leave
the forbidden ones as conspicuous absences.

The one caveat: the diagram above is already slightly dishonest (the `Stuck`
distinction the tool doesn't enforce). A diagram is still a map. The
discipline is to redraw it when the territory pushes back — which is the
conversation this document is meant to start.

## Next

The natural next move is the second diagram: the briefs state machine
(`drafted → decided → implemented → debriefed`), coupled to this one. That
one will surface its own gaps — likely around `decided → implemented`, where
decisions age and implementation drifts. But that's a second turn. This one
earned its keep.
