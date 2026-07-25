# playbook: diagrams for agent–human discussion

**Captured:** 2026-07-25
**Origin:** session 2026-07-25 (see `debriefs/001-session-2026-07-25.md`)
**Worked example:** `agent-workflow-discussion.md`

## The pattern

When an agent and a human need to discuss a system design — a workflow, a
process, a state machine — produce a baked state diagram as a shared
cognitive artifact. The diagram and the prose about the diagram inhabit the
same markdown file, visible in Glow (or `cat`) with no renderer switch.

## Why it works

1. **Commitment.** A state diagram forces every state and transition to be
   named and placed. Prose is reversible — you can hedge, qualify, leave
   edges implied. A diagram commits. Gaps appear not because of pattern
   matching but because of *completeness* — you can't draw a state diagram
   without deciding what every state is, and any decision that's hard to
   make is a gap.

2. **Gestalt perception.** The visual structure is perceived as a whole
   before any individual node is read. A dangling node is *seen* before it
   is *named*. A missing edge is *felt* as an asymmetry before it is
   *articulated* as a gap. This is pre-conscious — the visual cortex flags
   structural anomalies before the language centres name them.

3. **Spatial reasoning.** The diagram externalises structure into space.
   "These two states are far apart" or "this cycle is tight" are spatial
   facts that map to design facts (coupling, cost). Prose has no space —
   every sentence is one-dimensional. The diagram gives reasoning a second
   dimension.

4. **Shared surface.** Both agent and human read the same file in the same
   viewer (Glow). No context switch to a browser or a renderer. The diagram
   and the argument about the diagram are on the same scroll.

## How to do it

1. **Draw the first diagram.** It does not need to be right. It needs to
   portray *some part* of the process. State diagrams for workflows,
   flowcharts for pipelines.

2. **Ask: does it tell me what is going on?** If not, what needs added or
   removed? Look for:
   - **Dangling nodes** — states with no exit or no entrance
   - **Missing edges** — transitions you can't justify drawing (these are
     the design constraints)
   - **Asymmetric terminals** — states that end the same way but shouldn't
     feel the same

3. **When the renderer struggles, split.** A diagram the renderer can't
   lay out is a diagram trying to be two diagrams. Don't persevere with
   complexity — split into smaller diagrams. This is the same anti-entropy
   principle as the newup discipline: when the unit of work is too big,
   split it.

4. **Write the commentary alongside the diagram.** The diagram surfaces the
   gaps; the prose articulates them. The two belong on the same page.

5. **Iterate.** Redraw when the territory pushes back. The first diagram is
   a map; the discipline is to revise it when the model exceeds the
   evidence.

## When to use it

- Designing or reviewing a workflow or process
- Discussing system state transitions
- Surfacing constraints (the impossible transitions are the design
  constraints — state diagrams express them as missing edges)
- Any agent–human conversation where "does this tell us what is going on?"
  is the question

## When not to use it

- Pipelines (linear transformations) — a flowchart is fine
- Single-phase work — a diagram without structure is ceremony, not
  anti-entropy
- When the diagram would be smaller than the prose explaining it

## The fence convention

Source goes in `mmd` blocks (not `mermaid`), so GitHub renders it as plain
text, not a second live diagram. Art goes in `text` blocks. One diagram per
viewer. Bake the art; don't ship the renderer.

## The meta-lesson

The tool tells you when the diagram is too complicated. Listen to it.
Split the diagram. Move on. Six iterations of a combined diagram produced
nothing; two small diagrams rendered on the first try. The complexity was
the signal, not the problem.
