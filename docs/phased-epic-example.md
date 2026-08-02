# A phased td epic — worked example

td epics break large work into bounded phases, each tracked as a child
issue with dependencies. The phase boundary is the session boundary:
finish a phase, `td handoff`, start the next in a fresh context. This
keeps sessions O(n) instead of O(n²) — each context does one phase, not
the whole epic.

The diagram below is `td-a589a8` ("Art-first layout — flip the managed
region"), a four-phase epic. Phase 1 is complete (decision + brief
written this session); Phases 2-4 are sequential child issues with
dependencies — each blocks the next.

<!-- mermaid-to-md:art -->
```text
          ╭───╮
          │ ● │
          ╰─┬─╯
            │
            ▼
╭──────────────────────╮
│ Phase 1 — decision + │
│        brief         │
╰───────────┬──────────╯
            │
            ▼decision + brief written
╭──────────────────────╮
│ Phase 2 — wrappers + │
│        tests         │
╰───────────┬──────────╯
            │
            ▼wrappers + tests green
  ╭───────────────────╮
  │ Phase 3 — re-bake │
  │     artifacts     │
  ╰─────────┬─────────╯
            │
            ▼all artifacts re-baked
   ╭────────────────╮
   │ Phase 4 — docs │
   ╰────────┬───────╯
            │
            ▼docs updated, epic complete
          ╭───╮
          │ ● │
          ╰───╯
```

```mmd
stateDiagram-v2
    [*] --> Phase1
    Phase1 --> Phase2: decision + brief written
    Phase2 --> Phase3: wrappers + tests green
    Phase3 --> Phase4: all artifacts re-baked
    Phase4 --> [*]: docs updated, epic complete
    Phase1: Phase 1 — decision + brief
    Phase2: Phase 2 — wrappers + tests
    Phase3: Phase 3 — re-bake artifacts
    Phase4: Phase 4 — docs
```

## How to read it

- **`[*]` → Phase 1** — the epic starts with a decision and a brief.
  The decision records *what* and *why*; the brief scopes *how* in
  phases. Neither requires code changes — they're the map the rest of
  the epic navigates by.
- **Phase 1 → Phase 2** — the brief's acceptance criteria for Phase 1
  are met when the decision and brief exist and cross-reference. The
  transition is a `td handoff`: persist state, start a fresh context,
  `td context td-344dda` to resume.
- **Phase 2 → Phase 3** — Phase 2 (wrappers + tests) must be green
  before Phase 3 (re-bake) can run. The dependency is explicit:
  `td-0f8144 depends-on td-344dda`. You can't re-bake until the
  wrappers emit the new format.
- **Phase 3 → Phase 4** — Phase 3 (re-bake all artifacts) must complete
  before Phase 4 (docs) can update prose to match. `td-45ae59
  depends-on td-0f8144`.
- **Phase 4 → `[*]`** — docs updated, `check-docs` clean, epic
  complete. `td approve` closes the child; the epic closes when all
  children close.

## The td commands

```bash
td tree td-a589a8              # see the epic structure
td deps td-0f8144              # see what blocks a phase
td context td-344dda           # resume a phase in a fresh context
td handoff td-344dda           # persist state at a phase boundary
td approve td-344dda           # close a completed phase
```

## Why phases, not one big issue

A four-phase epic in one session is O(n²) — the context window fills
with the entire epic's detail, and each phase gets harder to reason
about as the session grows. Splitting into phases with dependencies is
O(n) — each context does one bounded phase, hands off, and the next
context starts clean. The dependency chain ensures phases execute in
order without a single session holding the whole epic's state.

The diagram makes the chain visible. A missing edge (e.g. Phase 2 →
Phase 4, skipping Phase 3) would be a conspicuous absence — the same
discipline state diagrams enforce everywhere: earn every permitted
path, leave the forbidden ones as gaps.

