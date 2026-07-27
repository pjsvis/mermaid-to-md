# Announcing mermaid-to-md

*State diagrams for agent–human discussion. Baked into markdown, visible anywhere.*

**Draft:** 2026-07-27 — artefact for sculpting, not final copy.
**Siblings:** `docs/the-case-for-baked-diagrams.md` (the position piece),
`decisions/001-state-diagrams-for-agent-human-discussion.md` (the
positioning call), `docs/digram-tools.md` (the market survey this argues
from), `USAGE.md` (the practice).

---

## The observation

Diagrams in documentation break in every viewer except the one they were
authored in. A `​```mermaid` fence renders on GitHub's web preview and not
in `cat`, not in Glow, not in an email preview, not in the PR diff anyone
actually reads. This is treated as normal. It isn't normal; it's a
collective misalignment we've stopped noticing because it's everywhere.

We are releasing a small tool that refuses to accept that as normal. It's
called `mermaid-to-md`. It renders Mermaid to Unicode box-drawing art and
**bakes the art into the markdown file** at authoring time. The result
displays in any viewer — `cat`, Glow, GitHub web, any editor, any email
client — without a renderer, runtime, or plugin. The diagram becomes the
file. The source is kept as a regeneration handle. A `--verify` mode
re-renders and diffs, so stale diagrams fail CI loudly instead of rotting
silently.

That's the whole tool. The interesting question is *why it needed to exist
at all* — and the answer is that the market sorted itself into four camps,
none of which made this move. So before the justification, the survey.

## The market, in four camps

### 1. Code-first, render-at-view-time (Eraser, PlantUML, Mermaid-as-code)

You write a DSL; a UI panel renders the graphic. This is the dominant
pattern and the source of the breakage. The author writes a `​```mermaid`
fence because GitHub renders it natively — path of least resistance, and
it looks great in the one place the author is looking. The cost — breakage
in every other viewer — is externalised to the reader, who isn't in the
room when the author hits save.

Nobody is acting irrationally. This is an incentive structure, not a
technology gap. Better renderers won't fix it; the renderer is fine. The
renderer is not the thing that's broken.

### 2. Spatial canvas agents (Miro AI, FigJam)

Enterprise whiteboards now embed LLMs to generate sticky notes and
flowcharts on an infinite 2D canvas. Lovely for product brain-dumping.
Lousy for software engineering: canvas diagrams don't version control,
don't feed back into pipelines, and drift visually. The Derrida question
applies — *should this even be in our consideration set?* For
execution-level state machines, no. We're not competing with Miro; we're
playing a different game on a different surface.

### 3. Execution-flow as runtime (LLMermaid, agentic flowcharts)

Here the diagram isn't documentation — it's the **state machine that
controls the agent's execution**. Fetch → Validate → Retry → Output, and
the agent reports its current node each turn. This shares our thesis that
diagrams are *alignment contracts*, not decoration. The overlap is real
and the philosophy is sound. But it answers a different question: "how do
I constrain an agent at runtime?" We answer: "how do two parties — one
human, one agent — reason about a system together and leave a durable
record?" Runtime control vs. shared cognitive artefact. Adjacent, not
rival.

### 4. ASCII engineering by hand (agent skills, `ARCHITECTURE.md` boxes)

A growing push toward ASCII-first architectural planning inside agent
environments — skills that make agents draw boxes in pull requests. The
instinct is right: terminal-native, git-diffable, no GUI. The problem is
that LLMs are bad at it. Predicting multi-line column alignments
token-by-token is notoriously hard; the boxes come out broken, and the
agent can't tell.

This is the camp that proves the move. The agents are *reaching for the
right output* (text art in the diff) but *doing the wrong work* (drawing
it by hand). The fix is not a better ASCII-drawing skill; it's offloading
the spatial math to a deterministic engine and letting the agent write
the *source* — the part LLMs are actually good at. Mermaid in, art out,
no token-level layout gambling. Stuff into Things, with the engine doing
the transformation.

## The gap we're stepping into

Plot the four camps on two axes — *is it git-diffable?* and *does the
agent author the source or the layout?* — and a quadrant sits empty:

| Camp | Git-diffable? | Agent authors |
|------|---------------|---------------|
| Code-first / SVG | no (renderer dep) | source (good) |
| Spatial canvas | no | source (good) |
| Execution-flow runtime | sometimes | source (good) |
| ASCII by hand | yes | **layout** (bad) |

The empty cell: **git-diffable, agent authors the source, a deterministic
engine authors the layout.** That's `mermaid-to-md`. Mermaid source in a
`​```mmd` block (not `​```mermaid`, so GitHub doesn't render a second
competing diagram — collision avoidance); box-drawing art baked into a
`​```text` block beside it; the source kept as a regeneration handle, not
destroyed. The agent writes what it's good at; the engine renders what
the agent is bad at; the file is the distribution.

## The justification, and the honesty

The move is three mundane things and a freshness check:

1. **Bake the art into the text substrate.** The diagram *is* the file,
   not a program the file invokes. Zero viewer dependencies.
2. **Keep the source as a regeneration handle.** Lose the renderer, you
   still have regenerable source; lose the source, the art still reads.
3. **Verify.** `--verify` re-renders and diffs. A cache without a
   freshness check is a lie waiting to happen; drift becomes a
   CI-failable error instead of silent rot.

None of this is clever. The anomaly is that "ship a renderer dependency
and externalise the breakage" ever became the default — and it became the
default because the author pays none of the cost. The fix was always
available. Nobody shipped it because the incentive pointed the other way.

Now the honesty, because an announcement without it is just marketing:

**The rendering is replicable in a weekend.** It's a ~40-line wrapper
around an existing Apache-2.0 renderer. The *how* is not the moat. The
moat question — *can you name your secrets?* — has an answer, and the
answer is the **practice**: an agent and a human drawing a state diagram
together on one surface, where the diagram's formality surfaces the gaps
prose hides. A state diagram refuses to let you draw an edge you can't
justify; prose lets you hedge. On a whiteboard that forcing function fires
once, at design time. Baked into the markdown next to the code —
diffable, re-readable, co-located — it fires *repeatedly*, over the life
of the system. Persistence converts a one-time forcing function into a
recurring one. *That* is the thing, and it is specific to a format that
bakes the art into the readable surface — not to "diagrams" in the
abstract.

**The art isn't as pretty as a rendered SVG.** That's a "whatever" — and
the "whatever" is load-bearing, not dismissive. Fidelity is the wrong
axis; arguing whether box-drawing art matches a dagre layout is
benchmaxxing for diagrams. The art is **predictably adequate**: it raises
the floor (every viewer, every time) without raising the ceiling. The
metric that matters is *"can the next person read this in any tool, six
months from now,"* and by that metric the renderer-dependent default
fails and the text version wins. The fidelity gap is the price of
adequacy, paid up front.

## What it is, what it isn't

It **is** a batch renderer for terminal-native, git-diffable diagrams —
bake, inject, verify. It **is** a positioning of state diagrams as the
right formalism for agent–human system design talk, because state
diagrams express constraints as *missing edges* and flowcharts hide them
by only showing permitted paths. It **is** an attempt to make the
practice cheap enough to reach for.

It **isn't** a browser-based live preview. That's a different product for
a different audience (browser editors, not terminal editors), and WASM is
the right answer there because the browser can't shell out to a native
binary. We've parked it. For batch rendering, the bake step is the
anti-WASM move: it eliminates the problem WASM solves, by solving it once
at authoring time instead of every page load. Credit to Simon Willison,
whose `grok-mermaid` WASM port of the same renderer took the direction we
play against — the contrast clarified the move.

It **isn't** an attempt to win a fidelity contest. We will lose every
fidelity contest we enter, and we will enter none of them.

## Get it

```bash
# from source (Rust)
cargo build --release
echo 'graph TD\n  A --> B --> C' | ./target/release/mermaid-tui

# npm (precompiled platform binaries)
npx mermaid-to-md < diagram.mmd > out.md

# curl | sh — binary only, no toolchain
curl -fsSL https://raw.githubusercontent.com/pjsvis/mermaid-to-md/main/install.sh | sh
```

Three modes, one principle:

```bash
# bake — render source → markdown with art + source
mermaid-to-md diagram.mmd -o diagram.md

# inject — render ```mmd blocks in an existing markdown file, in place
mermaid-to-md --inject doc.md

# verify — re-render and diff; exit 0 if fresh, 1 if stale
mermaid-to-md --verify doc.md
```

The diagram should be the file. The source should be preserved. The cache
should be checked. That's the whole pitch. The only surprising thing
about it is that it isn't already how every diagram in every repo works.

— Peter, 2026-07-27
