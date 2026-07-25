# decision: position on state diagrams for agent–human discussion, not "whiteboard"

**Created:** 2026-07-25
**Status:** decided
**Supersedes:** the tagline added in commits `709ea83` and `5e0fc1f` — *"A whiteboard for you and your agents. A whiteboard in your terminal."*
**Related:** `README.md`, `USAGE.md`, `briefs/005-demo-video.md`, `playbooks/recording-the-demo-video.md`, `playbooks/diagrams-for-agent-human-discussion.md`

## Context

The morning of 2026-07-25 added a two-clause tagline to `README.md` and
`USAGE.md`:

> *A whiteboard for you and your agents. A whiteboard in your terminal.*

The first clause named the *who* (human–agent collaboration); the second
named the *where* (terminal-native). On reflection, "whiteboard" is the wrong
noun in both clauses. This record replaces it.

## Decision

The positioning spine is **state diagrams for agent–human discussion**.
"Whiteboard" is retired from all user-facing copy. The tagline becomes:

> *State diagrams for agent–human discussion. Baked into markdown, visible
> anywhere.*

The first clause is the product — the act of drawing a state diagram with an
agent to surface design gaps. The second clause is supporting context (the
*how/where*), demoted from the headline.

## Rationale

Three reasons, in increasing weight.

**1. "Whiteboard" names the substrate; the value is the formality.** A
whiteboard is an unconstrained surface — doodles, org charts, shopping lists
all welcome. The product's value is the opposite: a *formal commitment
mechanism*. A whiteboard lets you hedge with a squiggle; a state diagram
refuses to let you draw an edge you can't justify. The repo's own thesis
(`agent-workflow-discussion.md`, the discussion playbook) names the mechanism
as commitment + completeness + Gestalt perception — none of which are
whiteboard properties. "Whiteboard" undersells the active ingredient.

**2. "Whiteboard" enters a saturated category we can't win.** Miro,
Excalidraw, tldraw, FigJam. The only axis we win on is "runs in a terminal,"
which nobody was shopping for. We get flattened to "terminal Miro" and
dismissed. The Derrida question applies to our own positioning: *should
"whiteboard" be in the consideration set of categories to position against?*
No.

**3. The secret is the practice, not the rendering.** The moat question —
*can you name your secrets?* — is decisive. The rendering (bake-to-text,
anti-WASM) is replicable in a weekend; it's the *how*. The secret is the
*practice*: an agent and a human drawing a state diagram together on one
surface, where the diagram's formality surfaces the gaps prose hides. A
tagline that says "whiteboard" names the substrate and hides the secret. A
tagline that says "state diagrams for agent–human discussion" points at the
practice.

## What we keep

The *intention* behind "whiteboard" was sound and is retained:

- **Shared surface** — both parties read the same file in the same viewer.
  The repo's phrase "shared cognitive artifact" carries this better than
  "whiteboard."
- **Approachability** — the first diagram needn't be right. This lives in a
  sentence that needs no whiteboard: *"the first diagram doesn't need to be
  right; it needs to portray some part of the process."* The warmth was
  never in the word; it was in that sentence.

Both good parts are detachable from "whiteboard." The bad part (wrong
category, misrepresents the mechanism) is not. So: keep both, drop the word.

## Consequences

- `README.md`, `USAGE.md`: tagline replaced.
- `briefs/005-demo-video.md`, `playbooks/recording-the-demo-video.md`: the
  demo's closing tagline overlay updated to match. The video is unbuilt
  (brief pending), so the change is cheap.
- The second tagline clause ("Baked into markdown, visible anywhere.") is
  the *where/how*, deliberately demoted. It is open to refinement; the
  headline is the part that is decided.
- No code changes. `mermaid-tui` and the planned wrapper are unaffected —
  this is a positioning decision, not a capability decision.

## What this is not

Not a rename of the project. The project is still `mermaid-to-md`; the
binary is still `mermaid-tui`. This decision is about the one-line pitch
under the title, not the package name.
