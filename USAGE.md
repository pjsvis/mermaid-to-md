# Usage — reasoning with baked state diagrams

> A guide for humans using mermaid-to-md as a reasoning tool, not just a
> renderer. Open in Glow (or `cat`) alongside a terminal for editing.

## The pitch

This tool renders Mermaid diagrams to Unicode box-drawing art and bakes the
art into markdown files. But the interesting use case is not "pretty
diagrams in the terminal." It is **reasoning about systems by drawing state
diagrams and discussing them** — with another human, or with an AI agent.

A baked state diagram is a shared cognitive artifact. Both parties look at
the same image on the same surface. The diagram commits to a structure that
prose can hedge. Gaps surface as dangling nodes and missing edges —
perceptually salient before they are articulable.

## The two-terminal workflow

Open two terminals side by side:

```
┌───────────────────┐  ┌───────────────────┐
│ Terminal 1        │  │ Terminal 2        │
│                   │  │                   │
│ Pi (agent)        │  │ Glow              │
│ or $EDITOR        │  │                   │
│                   │  │ glow doc.md       │
│ Edit the .mmd     │  │                   │
│ source, re-render │  │ Press R to        │
│ with mermaid-tui  │  │ refresh the view  │
│                   │  │                   │
└───────────────────┘  └───────────────────┘
```

- **Terminal 1**: your editor (or an AI agent like Pi). You write Mermaid
  source, render it with `mermaid-tui`, and bake the art into the markdown
  file.
- **Terminal 2**: Glow, viewing the same markdown file. When the file
  changes, press **`R`** to refresh. Glow reloads from disk and shows the
  updated diagram immediately.

This is the key interaction: **the discussion proceeds in one terminal, the
diagram updates in the other.** No context switch. No browser. No renderer
plugin. The diagram and the prose about the diagram stay on the same scroll.

## The cycle

```text
            ╭───╮
            │ ● │
            ╰─┬─╯
              │
              ▼
          ╭──────╮
          │ Draw ├───────────────────────────┐
          ╰───┬──╯                           │
           ┌──┘                              │
           ▼bake, open Glow                  │
       ╭──────╮            re-render, press R│
       │ View │◄─────────────────────────────┼┐
       ╰───┬──╯                              ││
           │                                 ││
           ▼read diagram                     ││
      ╭─────────╮                            ││
      │ Discuss │                            ││
      ╰────┬────╯                            ││
     ┌─────┴─────┐                           ││
     ▼gap found  ▼it shows what is going on  ││
╭────────╮   ╭──────╮ first attempt suffices ││
│ Redraw │   │ Done │◄───────────────────────┘│
╰────┬───╯   ╰───┬──╯                         │
     │           │                            │
     ▼update mmd ▼ource                       │
 ╭──────╮      ╭───╮                          │
 │ Bake ├──────│ ● │──────────────────────────┘
 ╰──────╯      ╰───╯
```

<details>
<summary>Mermaid source</summary>

```mmd
stateDiagram-v2
    [*] --> Draw
    Draw --> View: bake, open Glow
    View --> Discuss: read diagram
    Discuss --> Redraw: gap found
    Discuss --> Done: it shows what is going on
    Redraw --> Bake: update mmd source
    Bake --> View: re-render, press R
    Draw --> Done: first attempt suffices
    Done --> [*]
```

</details>

1. **Draw.** Write Mermaid source for the system you're reasoning about.
   The first diagram does not need to be right. It needs to portray *some
   part* of the process. State diagrams for workflows; flowcharts for
   pipelines.

2. **Bake.** Render with `mermaid-tui` and write the art into a markdown
   file. Open it in Glow.

3. **Discuss.** Read the diagram and the prose alongside it. Ask: *does it
   tell me what is going on?* Look for:
   - **Dangling nodes** — states with no exit or no entrance
   - **Missing edges** — transitions you can't justify drawing
   - **Asymmetric terminals** — states that end the same way but shouldn't
     feel the same

4. **Redraw.** When a gap appears, update the Mermaid source, re-render,
   and press `R` in Glow. The diagram updates. Discuss again.

5. **Done.** When the diagram tells you what is going on — when there are
   no more dangling nodes or missing edges that bother you — you're done.
   The diagram is a map you can trust enough to navigate by.

## What to reason about

This tool is for **things you can draw state diagrams for**:

- **Workflows and processes** — what states can the work be in? What
  transitions are possible? What transitions are *impossible* (the design
  constraints)?
- **System lifecycles** — creation, phased work, handoff, completion,
  failure. Where does the system get stuck? Where does it terminate?
- **Protocol design** — what are the valid states? What events cause
  transitions? What states are unreachable (and is that intentional)?
- **Agent–human collaboration** — who does what? Where are the human
  checkpoints? Where can the agent act autonomously?

State diagrams are the right type for these because they express
**constraints as missing edges**. Flowcharts hide constraints by only
showing permitted paths. State diagrams make you earn every permitted path
and leave the forbidden ones as conspicuous absences.

## The worked example

`agent-workflow-discussion.md` in this repo is the worked example. It was
produced in a single session using the two-terminal workflow described
above — Pi in one terminal, Glow in the other. The session:

1. Drew the td + briefs workflow as a state diagram
2. Three gaps surfaced (no timeout on Stuck, no Blocked→Handoff edge, no
   Stuck→Debrief edge)
3. Drew the epic lifecycle — renderer struggled with the combined diagram
4. Split into two smaller diagrams, each rendered cleanly
5. Three more gaps surfaced from the split diagrams
6. Wrote commentary alongside each diagram

None of the analysis existed before the first diagram was drawn. The
diagram did the rest. See `playbooks/diagrams-for-agent-human-discussion.md`
for the full pattern.

## The split lesson

If the renderer can't lay out your diagram — labels collide, edges merge,
the output looks wrong — **split the diagram.** A diagram the renderer
can't handle is a diagram trying to be two diagrams. Don't persevere with
complexity. Give the tool smaller jobs. This is the same anti-entropy
principle as bounded work: when the unit is too big, split it.

## Quick reference

```bash
# Render Mermaid source to Unicode art
echo 'stateDiagram-v2
    [*] --> A
    A --> B: event
    B --> [*]' | ./target/release/mermaid-tui

# View a baked document in Glow
glow agent-workflow-discussion.md

# In Glow, press R to refresh after the file changes
```
