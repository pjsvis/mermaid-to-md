# Agent workflow — a state diagram for discussion

> Rendered with `mermaid-tui`, baked into this file. Open in Glow (or `cat`)
> to see the diagram. No Mermaid renderer required. The art is the product;
> the source is reference material.

This document is a conversation piece, not a spec. It models the **td + briefs
workflow** that the agent and the human use to manage work in this repo, as a
state diagram — then surfaces what the diagram reveals.

## The diagram

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

<!-- mermaid-to-md:art -->
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
           ╰───┬───╯   ╰───────────╯                       │
               └──────┐                                    │
                      ▼abandon                             │
                    ╭───╮                                  │
                    │ ● │◄─────────────────────────────────┘
                    ╰───╯
```

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

---

## The second diagram — and a lesson learned

The conversation continued. The user noted that the first diagram missed a
step: the human requests an epic for the next task, the epic is phased, and
the agent is newed-up between phases. That's the *epic lifecycle* — an outer
state machine that contains the session machine above. Each epic phase runs
the session state machine; the phase boundary is where the newup discipline
bites.

The first attempt was a single diagram combining the epic creation flow with
the phase loop (the `Working → Handoff → Compacted → Working` cycle). The
renderer couldn't route the long back-edge — labels collided, edges merged.
Six iterations of tweaking labels and structure produced no improvement.

**The lesson: if the tool can't handle the big job, give it smaller jobs.**
A diagram that the renderer can't lay out is a diagram that's trying to be
two diagrams. The complexity was the signal, not the problem. Splitting into
two small diagrams — each rendering cleanly on the first try — took less
time than the sixth iteration of the single-diagram version. This is the
same anti-entropy principle as the newup discipline itself: when the unit of
work is too big, split it. The tool told us the diagram was too complicated,
and it was right.

### Diagram 2a: Epic creation (linear, no cycles)

```mmd
stateDiagram-v2
    [*] --> Idle
    Idle --> EpicRequested: human asks
    EpicRequested --> EpicCreated: td epic create
    EpicCreated --> PhaseLoop: pick phase 1
    PhaseLoop --> EpicDone: all phases done
    EpicDone --> [*]: debrief
    Idle --> [*]: no work
```

<!-- mermaid-to-md:art -->
```text
       ╭───╮
       │ ● │
       ╰─┬─╯
         │
         ▼
     ╭──────╮
     │ Idle ├──────────────┐
     ╰───┬──╯              │
         │                 │
         ▼human asks       │
 ╭───────────────╮         │
 │ EpicRequested │         │
 ╰───────┬───────╯         │
         │                 │
         ▼td epic create   │
  ╭─────────────╮          │
  │ EpicCreated │          │
  ╰──────┬──────╯          │
         │                 │
         ▼pick phase 1     │
   ╭───────────╮           │
   │ PhaseLoop │           │
   ╰─────┬─────╯           │
         │                 │
         ▼all phases done  │
   ╭──────────╮            │
   │ EpicDone │            │
   ╰─────┬────╯            │
         │                 │
         ▼debrief          │
       ╭───╮       no work │
       │ ● │◄──────────────┘
       ╰───╯
```

This is the outer machine. `PhaseLoop` is a placeholder for the inner cycle
— the box the next diagram opens. The key observation: **`EpicRequested` is
a human-driven transition.** The agent does not create epics on its own; the
human asks. This is a checkpoint, not a step, and the diagram makes that
visible by putting a whole state between `Idle` and `EpicCreated`. If the
agent could self-epic, that state would collapse. It shouldn't.

### Diagram 2b: The phase loop (the newup cycle)

```mmd
stateDiagram-v2
    [*] --> Working
    Working --> Handoff: phase done
    Handoff --> Compacted: /new
    Compacted --> Working: td context
    Working --> Blocked: blocked
    Blocked --> Working: unblocked
    Working --> [*]: all phases done
```

<!-- mermaid-to-md:art -->
```text
                  ╭───╮
                  │ ● │
                  ╰─┬─╯
                    │
                    ▼
               ╭─────────╮             td context
               │ Working │◄───────────────────────┐
               ╰────┬┬───╯                        │
       ┌────────────┴┼──────────┐                 │
       ▼phase done   ▼blocked   ▼all phases done  │
  ╭─────────╮   ╭─────────╮   ╭───╮               │
  │ Handoff │   │ Blocked ├───│ ● │───────────────┤
  ╰────┬────╯   ╰─────────╯   ╰───╯               │
       │                                          │
       ▼/new                                      │
 ╭───────────╮                                    │
 │ Compacted ├────────────────────────────────────┘
 ╰───────────╯
```

This is the inner machine — the same `Working → Handoff → Compacted →
Oriented` loop from diagram 1, but now seen as the *content of a single
epic phase*. The newup loop is the cost-control mechanism, and the diagram
shows it as a tight cycle: three states, three edges, one purpose.

**What this diagram surfaces that the first one didn't:**

1. **`/new` is a harness command, not an agent action.** The agent cannot
   self-terminate and resume — it's inside the context that `/new` destroys.
   The transition `Handoff → Compacted` is issued by the *human*, not the
   agent. The diagram makes this a human checkpoint, and it should stay one:
   the decision to continue, stop, or redirect is most valuable when the work
   is going badly, which is exactly when you don't want auto-continue.

2. **The real friction is on the far side of `/new`.** The keystroke cost of
   `/new` + `td context` is trivial. The real cost is *orientation* — the new
   agent reading context and figuring out where it is. If `td handoff`
   captured phase-scoped state ("Phase 1 complete, Phase 2 inputs are X,
   acceptance criteria are Y"), `td context` in the new session would drop
   the agent directly at Phase 2 instead of at "orient to the whole repo."
   That's where the O(n²)→O(n) actually lives. The automation target is the
   **resume**, not the **newup**.

3. **Phase is not first-class in td.** Right now, a phase is text in an epic
   description. If phases were addressable objects with their own
   handoff/context, the loop would be phase-scoped and orientation cost
   would collapse. That's a td feature request, not a pi feature request,
   and it's the automation that pays for itself.

## Why this all emerged from drawing a diagram

None of the analysis above existed before the first diagram was drawn. The
sequence was:

1. Draw the session workflow as a state diagram.
2. Three gaps appear (no `Stuck` timeout, no `Blocked → Handoff`, no
   `Stuck → Debrief`).
3. User notes the diagram missed the epic creation step.
4. Draw the epic lifecycle. Renderer struggles with the combined diagram.
5. Split into two diagrams. Each renders cleanly.
6. The split itself surfaces the insight: the phase loop is the cost-control
   unit, and the automation target is the resume, not the newup.

This is the user's thesis made concrete: **the first diagram does not need to
be right. It just needs to portray some part of the process. The gaps will
appear due to dangling nodes or missing nodes. The question one asks of the
diagram is: does it tell me what is going on? And if it does not, what needs
added or removed to make it show me what is going on.**

Both agent and human can reason about a diagram a lot easier than using words
alone. The diagram is a shared cognitive artifact — it lives on the same
surface (the terminal, via Glow) for both parties, and it commits to a
structure that prose can hedge.

## Is this Shannon pattern matching, or another mechanism?

The user asked whether the efficacy of diagram-based reasoning comes from
leveraging Shannon's pattern-matching capabilities. The honest answer is:
it's pattern matching, but not Shannon's. Claude Shannon's contribution was
*information theory* — entropy, channel capacity, the bit. Pattern matching
is more a **Gestalt perception** mechanism. The distinction matters.

What actually happens when an agent or a human reads a state diagram:

- **Gestalt perception** (the primary mechanism): the visual structure is
  perceived as a whole before any individual node is read. A dangling node
  is *seen* before it is *named*. A missing edge is *felt* as an asymmetry
  before it is *articulated* as a gap. This is pre-conscious — the visual
  cortex flags structural anomalies before the language centres name them.
  That's why drawing the diagram surfaces gaps that thinking about the
  process doesn't: the gaps are *perceptual*, not *logical*, and perception
  is faster than reasoning.

- **Spatial reasoning** (the secondary mechanism): the diagram externalises
  structure into space. "These two states are far apart" or "this cycle is
  tight" are spatial facts that map to design facts (coupling, cost). Prose
  has no space — every sentence is one-dimensional. The diagram gives the
  reasoning system a second dimension to work in.

- **Commitment** (the anti-entropy mechanism, from the Edinburgh Protocol):
  the diagram forces every state and transition to be named and placed. Prose
  is reversible; a diagram is a *commitment*. Gaps appear not because of
  pattern matching but because of *completeness* — you can't draw a state
  diagram without deciding what every state is, and any decision that's hard
  to make is a gap.

So: not Shannon, but Gestalt + spatial reasoning + forced commitment. The
Shannon connection is real but indirect — the diagram is a *low-entropy
representation* of a high-entropy process. It compresses the workflow into a
structure where anomalies are perceptually salient. Shannon would approve of
the compression; the *seeing* is Gestalt.

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

The one caveat: the first diagram is already slightly dishonest (the `Stuck`
distinction the tool doesn't enforce). A diagram is still a map. The
discipline is to redraw it when the territory pushes back — which is the
conversation this document is meant to start, and has continued.

**And the meta-lesson: when the tool can't handle the big job, give it
smaller jobs.** The renderer couldn't lay out the combined epic + phase
diagram. Six iterations of tweaking produced nothing. Splitting into two
small diagrams took one iteration each. The tool was telling us the diagram
was too complicated, and it was right — the same way a dangling node tells
you the model is too complicated. Listen to the tool. Split the diagram.
Move on.

## Next

The natural next move is the briefs state machine (`drafted → decided →
implemented → debriefed`), coupled to the session and epic machines. That
will surface its own gaps — likely around `decided → implemented`, where
decisions age and implementation drifts. But that's a third turn. This one
earned its keep twice: once by surfacing gaps, once by surfacing the lesson
that the diagram itself teaches you when to split.
