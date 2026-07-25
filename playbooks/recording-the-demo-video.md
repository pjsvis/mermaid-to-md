# Playbook: recording the demo video

**For:** the human operator
**Goal:** record a 60–90 second demo of the two-terminal workflow
**Tool:** OBS Studio (installed) or native Mac screen capture as fallback
**Hardware:** MacBook (2560×1664) + external monitor (1920×1080)

## The setup

### Screen layout

```
┌─────────────────────────┐  ┌─────────────────────────┐
│ External monitor        │  │ MacBook built-in        │
│ (1920×1080)             │  │ (2560×1664)             │
│                         │  │                         │
│ ┌──────────┐ ┌────────┐ │  │ ┌─────────────────────┐ │
│ │ Terminal 1│ │Term 2  │ │  │ │ OBS Studio          │ │
│ │ Pi       │ │ Glow   │ │  │ │ (recording controls, │ │
│ │ (agent)  │ │ (view) │ │  │ │  storyboard, notes)  │ │
│ │          │ │        │ │  │ └─────────────────────┘ │
│ └──────────┘ └────────┘ │  │                         │
│                         │  │                         │
└─────────────────────────┘  └─────────────────────────┘
         ▲                              ▲
    RECORD THIS                   NOT THIS
```

**Why:** both terminals on the external monitor, side by side. OBS and
your storyboard/notes on the MacBook screen. You record only the external
monitor — clean, focused, no OBS chrome in the shot.

### Terminal sizing

On the external monitor (1920×1080), two terminals side by side:

- **Terminal 1 (Pi):** left half, ~960px wide
- **Terminal 2 (Glow):** right half, ~960px wide

In macOS, drag each terminal to its half and it'll snap (or use
Rectangle/Amethyst if you have them). Both terminals need to be the same
font size so the diagram renders at the same width in both.

**Critical:** set both terminals to the same column width (at least 100
columns). The baked art in `agent-workflow-discussion.md` is ~65 characters
wide — it needs room. If Glow wraps the art, the diagram breaks. Test by
viewing the file before recording.

### Font

Use a monospace font that has good box-drawing character support:
- **JetBrains Mono** (recommended — clean, has all the box-drawing chars)
- **SF Mono** (macOS default, works)
- **Menlo** (fallback)

Set both terminals to the same font and size (14pt is a good starting
point for video).

---

## OBS Studio setup

### 1. Create a scene

1. Open OBS Studio
2. In the **Scenes** panel (bottom left), click `+`, name it "Demo"
3. In the **Sources** panel, click `+` → **Display Capture**
4. Select the external monitor (1920×1080)
5. The external monitor's full content appears in the OBS preview

### 2. Crop to the two terminals (optional but cleaner)

If you want just the two terminals without desktop wallpaper:

1. Right-click the Display Capture source → **Transform** → **Edit Transform**
2. Or: delete Display Capture, add **Window Capture** for each terminal
   - Window Capture → select Terminal 1 (Pi)
   - Window Capture → select Terminal 2 (Glow)
   - Arrange them side by side in the OBS preview
3. Window Capture is cleaner — no desktop, no menu bar, just terminals

**Recommended:** two Window Capture sources, arranged side by side. This
gives you a clean 1920×1080 (or smaller) shot of just the terminals.

### 3. Output settings

1. **Settings** → **Output** → **Output Mode:** Simple
2. **Recording Path:** choose a folder with space (videos are large)
3. **Recording Format:** MP4 (or MKV, then convert — see below)
   - **Use MKV if you want crash safety.** OBS can crash or the recording
     can corrupt if the machine sleeps. MKV is safer; convert to MP4 after.
     `File → Remux Recordings` in OBS converts MKV→MP4 in seconds.
4. **Encoder:** Apple VT H264 (hardware encoder — fastest on Apple Silicon)
5. **Rate Control:** CBR, **Bitrate:** 8000–10000 Kbps (good quality for
   screen recording)
6. **Keyframe Interval:** 2

### 4. Video settings

1. **Settings** → **Video**
2. **Base Resolution:** 1920×1080 (match the external monitor)
3. **Output Resolution:** 1920×1080 (don't downscale — text must stay sharp)
4. **FPS:** 30 (terminal content doesn't need 60fps; 30 keeps file size
   reasonable)

### 5. Audio (optional)

If you want voiceover live:

1. Add an **Audio Input Capture** source (your microphone)
2. Set levels — speak at normal volume, watch the meter, aim for the
   yellow zone (-20 to -10 dB)

**Recommendation:** record silent. Add voiceover or captions in
post-production. Live voiceover while operating two terminals and
directing an agent is a lot to juggle. A silent screen recording with
text overlays is cleaner and easier to produce.

---

## Native Mac screen capture (fallback)

If OBS is overkill, macOS built-in capture works:

1. Press `Cmd+Shift+5`
2. Choose **Record Selected Portion** (the rectangle icon)
3. Drag to select the area covering both terminals on the external monitor
4. Click **Record**
5. Press `Cmd+Shift+5` again, then **Stop** when done

The output is a `.mov` file on your Desktop. Convert to MP4:

```bash
ffmpeg -i screen-recording.mov -c:v libx264 -preset fast -crf 20 demo.mp4
```

**Pros of native capture:** zero setup, no configuration.
**Cons:** no scene management, no window cropping, no audio mixing, no
remux safety. Fine for a first take; OBS for polish.

---

## The recording session

### Pre-roll checklist

Before hitting record:

- [ ] Both terminals open on the external monitor, side by side
- [ ] Terminal 1: Pi, in the `mermaid-to-md` repo, agent ready
- [ ] Terminal 2: Glow, viewing `agent-workflow-discussion.md`, first
      diagram visible
- [ ] Font sizes match, column width ≥100, art doesn't wrap
- [ ] OBS scene configured, preview looks right
- [ ] Storyboard open on the MacBook screen (this playbook or the
      storyboard from brief 005)
- [ ] Notifications off (`Focus` mode or `Do Not Disturb`)
- [ ] Close Slack, email, anything that might pop a notification
- [ ] Dock auto-hidden (cleaner shot if you use Display Capture)

### The storyboard (from brief 005)

| Time | Terminal 1 (Pi) | Terminal 2 (Glow) | What to say/show |
|------|-----------------|-------------------|------------------|
| 0:00–0:10 | idle, ready | first diagram visible | The setup: two terminals, one agent, one viewer |
| 0:10–0:25 | agent draws epic lifecycle source | still showing diagram 1 | The human asks: "does this show epic creation?" Agent identifies the gap |
| 0:25–0:40 | agent renders, bakes into markdown | press R — new diagram appears | The render: source → art → Glow refresh |
| 0:40–0:55 | agent splits the diagram, re-renders | press R — two clean diagrams | The split: too complex → two small diagrams |
| 0:55–1:05 | agent writes commentary about gaps | showing the two diagrams | The result: gaps surfaced by the diagram |
| 1:05–1:15 | fade or hold | tagline overlay in post | "mermaid-to-md — state diagrams for agent–human discussion" |

### Recording

1. In OBS, click **Start Recording**
2. Wait 2 seconds (buffer)
3. Begin the storyboard — direct the agent in Terminal 1, press R in
   Terminal 2 at the right moments
4. When done, click **Stop Recording** in OBS
5. If you used MKV: **File → Remux Recordings** → convert to MP4

### Tips

- **Don't rush.** 90 seconds is plenty. Pauses between beats let the
  viewer absorb the diagram.
- **Press R deliberately.** Make it visible — the refresh is the visual
  climax. Pause for a beat after pressing R so the viewer sees the new
  diagram.
- **The agent's typing is part of the show.** Let the viewer see the
  Mermaid source being written and the render command being run. Don't
  hide the agent's work — it's the point.
- **If something goes wrong, stop and restart.** It's a demo, not a live
  performance. Retake until it's clean.
- **Record 2–3 takes.** Pick the best one in post.

---

## Post-production

### Trim and export

```bash
# Trim the first 2 seconds (buffer) and last 2 seconds
ffmpeg -i demo.mkv -ss 2 -to 75 -c:v libx264 -preset fast -crf 20 demo.mp4
```

### Add the tagline (optional)

The tagline can be:
- A text overlay added in a video editor (iMovie, DaVinci Resolve, ffmpeg)
- Or simply the last frame held with a text overlay

ffmpeg text overlay (simple):

```bash
ffmpeg -i demo.mp4 -vf "drawtext=text='mermaid-to-md — state diagrams for agent–human discussion':fontsize=36:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,65,75)'" -c:a copy demo-tagged.mp4
```

### File size

A 90-second 1080p screen recording at 8000 Kbps is ~90MB. If that's too
large for GitHub, downscale:

```bash
ffmpeg -i demo.mp4 -vf scale=1280:-2 -c:v libx264 -preset slow -crf 24 demo-small.mp4
```

This produces a ~30MB file at 720p, still sharp enough for terminal text.

---

## Hosting

- **GitHub release:** attach the MP4 to a release. Raw video, no player.
- **GitHub README:** GitHub doesn't embed MP4s in README directly, but you
  can link to the release asset or use an `<video>` tag (works on GitHub
  web):
  ```html
  <video controls src="https://github.com/pjsvis/mermaid-to-md/releases/download/v0.1.0/demo.mp4"></video>
  ```
- **YouTube:** unlisted video, embeddable. Best for discovery.
- **asciinema.org:** only for asciinema recordings (future, Option B from
  brief 005).

**Recommended:** GitHub release for the MP4 + YouTube unlisted for
discovery. The README links to both.

---

## Checklist (one page)

```
PRE-ROLL
  [ ] Both terminals on external monitor, side by side
  [ ] Pi in Terminal 1, Glow in Terminal 2
  [ ] Font + column width matched, art doesn't wrap
  [ ] OBS: two Window Capture sources, arranged side by side
  [ ] Output: MP4 (or MKV→remux), 1080p, 30fps, Apple VT H264
  [ ] Notifications off, dock hidden
  [ ] Storyboard visible on MacBook screen

RECORD
  [ ] Start recording (OBS or Cmd+Shift+5)
  [ ] 2s buffer
  [ ] Beat 1: setup (0:00–0:10)
  [ ] Beat 2: the gap — human asks, agent draws (0:10–0:25)
  [ ] Beat 3: render + R refresh (0:25–0:40)
  [ ] Beat 4: split the diagram (0:40–0:55)
  [ ] Beat 5: discuss gaps (0:55–1:05)
  [ ] Beat 6: tagline (1:05–1:15)
  [ ] Stop recording
  [ ] Remux if MKV

POST
  [ ] Trim buffer (ffmpeg -ss 2)
  [ ] Add tagline overlay (optional)
  [ ] Downscale if needed (1280 wide, crf 24)
  [ ] Upload to GitHub release + YouTube
  [ ] Embed in README
```
