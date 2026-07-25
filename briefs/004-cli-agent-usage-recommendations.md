# brief: mermaid-to-md CLI — agent usage recommendations

**Created:** 2026-07-25
**Status:** pending
**Depends on:** brief 001 (the wrapper script — `scripts/mermaid-to-md.sh`)
**Related:** `agent-workflow-discussion.md` (the dogfood artifact that surfaced these recommendations)

## What

The CLI's documentation (`--help`, README section, and an `AGENT-USAGE.md`
or equivalent) should include explicit recommendations for *agent* usage —
not just human usage. Agents are a first-class audience for this tool; they
author and consume markdown documents that contain diagrams, and they need
guidance on the conventions that make those documents work as a
communication channel between agent and human.

## Why

This session dogfooded the tool by producing `agent-workflow-discussion.md` —
a document where the agent and the human discussed a system design using
baked state diagrams as shared cognitive artifacts. The efficacy was
immediate: three workflow gaps surfaced from the first diagram, and a
meta-lesson (split the diagram when the renderer struggles) emerged from the
second. That experience produced conventions that should be captured so the
next agent doesn't have to rediscover them.

The tool's pitch is "the diagram is the product; the source is reference
material." For agents, the stronger pitch is: **a baked state diagram is a
low-entropy shared surface for agent–human system design talk.** The
agent-facing docs should say this explicitly.

## Recommendations to include

### 1. Fence convention: `mmd` for source, `text` for art

Source goes in `mmd` blocks (not `mermaid`), so GitHub renders it as plain
text, not a second live diagram. Art goes in `text` blocks. One diagram per
viewer. This is already in the README; the agent docs should state it as a
rule, not a preference.

### 2. When to bake vs inject vs verify

- **Bake** when creating a new document from a `.mmd` source file.
- **Inject** when updating an existing markdown file that has `mmd` blocks.
  Idempotent — re-running replaces, doesn't duplicate.
- **Verify** in CI or before commit to catch stale diagrams. Exit 0 if
  fresh, exit 1 if any art block doesn't match a re-render of its source.

### 3. State diagrams for workflows, flowcharts for pipelines

State diagrams surface constraints as missing edges — the impossible
transitions are the design constraints. Flowcharts hide constraints by only
showing permitted paths. For workflow design (agent–human process talk),
state diagrams are the right type. For pipelines (render → wrap → ship), a
flowchart is fine. The agent docs should recommend state diagrams for
workflow discussions and explain why.

### 4. The first diagram doesn't need to be right

Draw a diagram that portrays *some part* of the process. The gaps will
appear via dangling nodes or missing edges. The question to ask of the
diagram: does it tell me what is going on? If not, what needs added or
removed? Both agent and human reason about a diagram more easily than words
alone — the diagram is a shared cognitive artifact that commits to a
structure prose can hedge.

### 5. When the renderer struggles, split the diagram

A diagram the renderer can't lay out is a diagram trying to be two diagrams.
Don't persevere with complexity — split into smaller diagrams. This is the
same anti-entropy principle as the newup discipline: when the unit of work
is too big, split it. The tool is telling you the diagram is too complicated,
and it's right.

### 6. Bake the art, don't ship the renderer

For agent-authored documents, always bake. A live `mermaid` block requires a
renderer at view time — the human reading in Glow sees nothing. A baked
`text` block is visible in any viewer. The agent should never ship a
`mermaid` block in a document intended for terminal reading.

## Acceptance criteria

- [ ] `scripts/mermaid-to-md.sh --help` includes an "Agent usage" section
- [ ] README has an "For agents" section (or a separate `AGENT-USAGE.md`)
- [ ] The fence convention is stated as a rule, not a preference
- [ ] The bake/inject/verify guidance is concrete and actionable
- [ ] The state-diagrams-for-workflows recommendation explains *why*
- [ ] The split-the-diagram lesson is captured
- [ ] The docs reference `agent-workflow-discussion.md` as the worked example

## Out of scope

- The wrapper script itself (brief 001)
- npm packaging (brief 002)
- Pi extension integration (separate concern)

## Relationship

- **brief 001** — the wrapper script this documentation describes
- **`agent-workflow-discussion.md`** — the dogfood artifact that surfaced
  these recommendations. The docs should reference it as the worked example.
