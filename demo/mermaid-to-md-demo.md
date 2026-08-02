# mermaid-to-md — demonstration

This file is an inject-mode artifact: each ` ```mmd ` block is Mermaid
source, and the ` ```text ` block below it (marked by the
`<!-- mermaid-to-md:art -->` sentinel) is the same diagram rendered to
Unicode box-drawing art by `mermaid-tui`. Open it in Glow (or `cat` it) to
see the diagrams — no Mermaid renderer required, the art is plain text.

The source fence is ` ```mmd ` (not ` ```mermaid `) so GitHub renders it as
plain text, not a second live diagram. The art is the product — one diagram
everywhere. The source is reference material for regeneration, not a
parallel render.

Re-render after a renderer or source change with `just demo`, which re-runs
inject and displays the result. Check freshness with
`mermaid-to-md --verify demo/mermaid-to-md-demo.md`.

---

## 1. The pipeline (flowchart)

<!-- mermaid-to-md:art -->
```text
   ┌─────────────┐
   │ Source .mmd │
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ mermaid-tui │
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ Unicode art │
   └──────┬──────┘
          │
          ▼
  ┌───────────────┐
  │ Wrap in fence │
  └───────┬───────┘
          │
          ▼
    ┌──────────┐
    │ .md file │
    └─────┬────┘
          │
          ▼
      ┌──────┐
      │ Glow │
      └───┬──┘
          │
          ▼
 ┌─────────────────┐
 │ Reads correctly │
 └─────────────────┘
```

```mmd
graph TD
  A[Source .mmd] --> B[mermaid-tui]
  B --> C[Unicode art]
  C --> D[Wrap in fence]
  D --> E[.md file]
  E --> F[Glow]
  F --> G[Reads correctly]
```

---

## 2. Brief lifecycle (state diagram)

<!-- mermaid-to-md:art -->
```text
     ╭───╮
     │ ● │
     ╰─┬─╯
       │
       ▼
   ╭───────╮   reject
   │ Draft │◄─────────┐
   ╰───┬───╯          │
       │              │
       ▼submit        │
  ╭─────────╮         │
  │ Pending ├─────────┘
  ╰────┬────╯
       │
       ▼approve
╭────────────╮
│ InProgress │
╰──────┬─────╯
       │
       ▼finish
 ╭──────────╮
 │ Complete │
 ╰─────┬────╯
       │
       ▼
     ╭───╮
     │ ● │
     ╰───╯
```

```mmd
stateDiagram-v2
  [*] --> Draft
  Draft --> Pending : submit
  Pending --> InProgress : approve
  InProgress --> Complete : finish
  Complete --> [*]
  Pending --> Draft : reject
```

---

## 3. The round-trip (sequence diagram)

<!-- mermaid-to-md:art -->
```text
┌──────┐                  ┌─────┐           ┌────────┐
│ User │                  │ CLI │           │ Binary │
└───┬──┘                  └──┬──┘           └────┬───┘
    │                        │                   │
    │mermaid-to-md input.mmd │                   │
    ├───────────────────────▶│                   │
    │                        │                   │
    │                        │    pipe source    │
    │                        ├──────────────────▶│
    │                        │                   │
    │                        │    unicode art    │
    │                        │◄╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    │                        │                   │
    │                        ├──╮                │
    │                        │  │ wrap in fence  │
    │                        │◄─╯                │
    │                        │                   │
    │       output.md        │                   │
    │◄╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤                   │
    │                        │                   │
┌───┴──┐                  ┌──┴──┐           ┌────┴───┐
│ User │                  │ CLI │           │ Binary │
└──────┘                  └─────┘           └────────┘
```

```mmd
sequenceDiagram
  participant User
  participant CLI
  participant Binary
  User->>CLI: mermaid-to-md input.mmd
  CLI->>Binary: pipe source
  Binary-->>CLI: unicode art
  CLI->>CLI: wrap in fence
  CLI-->>User: output.md
```

---

## Verdict

If you can read the three diagrams above in Glow, the pipeline works and the
tool is worth building. The brief is at `briefs/001-mermaid-to-md.md`.
