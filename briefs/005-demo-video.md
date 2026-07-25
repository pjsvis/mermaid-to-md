# brief: demo video — human and agent discussing a state diagram

**Created:** 2026-07-25
**Status:** pending
**Depends on:** nothing (can be produced with the current binary + Glow)
**Related:** `USAGE.md`, `agent-workflow-discussion.md`, `playbooks/diagrams-for-agent-human-discussion.md`

## What

A short demo video (60–90 seconds) showing the two-terminal workflow in
action: a human and an AI agent discussing a system design using a baked
state diagram. The video shows the draw → bake → view → discuss → redraw
cycle, with the diagram updating in Glow as the agent re-renders.

The tagline: **state diagrams for agent–human discussion.**

## Why

The tool's pitch is easier to *show* than to *tell*. `USAGE.md` describes
the two-terminal workflow, but a video makes it immediate — you see the
agent draw a diagram, you see Glow refresh on `R`, you see the human and
agent discuss a gap, you see the diagram update. That cycle is the product.
Prose can describe it; video proves it.

Simon Willison's `shot-scraper video` post (2026-06-30) shows the pattern:
agents producing demos of their own work. We should follow that pattern —
the agent produces the demo, the human reviews and ships it.

## The challenge: two terminals, not a browser

`shot-scraper video` records **browser** sessions via Playwright. Our demo
is **two terminals side by side** — that's not a browser session. This is
the core design decision the brief must resolve.

### Option A: screen recording (simple, honest)

Record the screen with macOS screen capture (`Cmd+Shift+5` or `ffmpeg`):
- Terminal 1: Pi (the agent) editing and rendering
- Terminal 2: Glow viewing the markdown, pressing `R` to refresh

**Pros:** shows exactly what the workflow looks like. No tooling gap.
**Cons:** manual — the human records while the agent works. Not
agent-produced. File size is larger (MP4). No automation.

### Option B: asciinema (terminal recording, web-embeddable)

Use `asciinema rec` to capture a terminal session, then embed the
asciinema player on a web page or GitHub README.

Two approaches:
1. **Single terminal** — record the agent's terminal only. The viewer sees
   the agent drawing Mermaid source, rendering with `mermaid-tui`, and the
   baked art appearing. The Glow side is described in voiceover or text
   overlay.
2. **Two recordings side by side** — record both terminals separately,
   compose them into a split-screen GIF or video. More complex but shows
   the full workflow.

**Pros:** lightweight, text-based recordings, embeddable, agent can produce
the recording. `asciinema` is `brew install asciinema` on macOS.
**Cons:** asciinema player is web-only (needs JavaScript). Can't show two
terminals in one recording natively. The Glow `R` refresh would need to be
in a separate recording or composed.

### Option C: shot-scraper + rendered markdown in browser (Simon's pattern)

Host the baked markdown on a web page (GitHub renders `text` blocks as
monospace), use `shot-scraper video` with a `storyboard.yml` to:
1. Load the GitHub page showing the diagram
2. Simulate the "update" by navigating to a revised version
3. Show the diagram changing

**Pros:** agent-producible (the whole point of Simon's post). Web-embeddable
MP4. Clean output.
**Cons:** doesn't show the *terminal* workflow, which is the whole pitch.
Shows a browser viewing markdown, not Glow refreshing on `R`. Dishonest —
the video would show a browser, but the pitch is "terminal-native." This
is the Derrida question: should this even be in our consideration set?
The answer is probably no — it misrepresents the product.

### Recommended: Option A (screen recording) for the first demo

The first demo should be honest: two terminals, real screen capture, real
`R` refresh. It's manual but it's real. A 60-second screen recording of
the actual workflow is more convincing than a polished browser simulation
that doesn't show the terminal.

The agent can prepare the storyboard (what to draw, what gaps to surface,
what to say), and the human records while executing it. The storyboard is
agent-produced; the recording is human-operated.

### Future: Option B (asciinema) for embeddable demos

Once the first demo proves the concept, produce an asciinema version for
web embedding. The asciinema player is lightweight and the recordings are
text-based (tiny file size). This could be agent-produced end-to-end — the
agent records its own terminal session. The challenge is showing the Glow
side; this may need a split-screen composition or a second recording.

## The storyboard

The video should tell a story, not just demo features. Proposed storyboard:

1. **(0:00–0:10) The setup** — two terminals side by side. Left: Pi. Right:
   Glow showing `agent-workflow-discussion.md`. The first diagram is
   visible.

2. **(0:10–0:25) The gap** — the human asks "does this diagram show what
   happens when we create an epic?" The agent reads the diagram, identifies
   the missing epic creation step. The agent writes Mermaid source for the
   epic lifecycle.

3. **(0:25–0:40) The render** — the agent runs `mermaid-tui`, bakes the new
   diagram into the markdown. Press `R` in Glow. The new diagram appears.
   The human sees it immediately.

4. **(0:40–0:55) The split** — the combined diagram is too complex for the
   renderer. The agent splits it into two small diagrams. Re-renders. Press
   `R`. Both diagrams appear, clean.

5. **(0:55–0:01:05) The result** — the human and agent discuss the gaps the
   split surfaces. "You can't hand off while blocked." "Phase isn't
   first-class in td." The diagram made these visible.

6. **(0:01:05–0:01:15) The tagline** — fade to: **mermaid-to-md — state
   diagrams for agent–human discussion.**

## Acceptance criteria

- [ ] A 60–90 second video showing the two-terminal workflow
- [ ] The video shows Glow refreshing on `R` after a re-render
- [ ] The video shows a state diagram being drawn, baked, and discussed
- [ ] The video shows the split-the-diagram lesson (complex → two small)
- [ ] The video ends with the tagline
- [ ] The video is hosted (GitHub release, YouTube, or asciinema.org)
- [ ] The video is referenced in the README

## Out of scope

- A full production video with voiceover, music, or graphics
- Automated agent-produced recording (Option B/C) — future work
- Multi-platform recording instructions — the first demo is macOS

## Relationship

- **`USAGE.md`** — the written guide; the video is the visual version
- **`agent-workflow-discussion.md`** — the worked example; the video shows
  it being produced (or a condensed version)
- **Simon Willison's `shot-scraper video` post** — the pattern of
  agent-produced demos. Our case is harder (terminals, not browser) but
  the principle is the same: the agent prepares the storyboard, the demo
  proves the work.
