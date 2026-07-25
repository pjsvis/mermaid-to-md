# mermaid-to-md — demonstration

This file is what `mermaid-to-md` would produce: Mermaid source rendered to
Unicode box-drawing art, baked into a markdown file as a fenced code block.
Open it in Glow (or `cat` it) to see the diagrams. No Mermaid renderer
required — the art is plain text.

The source for each diagram is in a `​```mmd` block (NOT `​```mermaid`)
so GitHub renders it as plain text, not a second live diagram. The art is
the product — one diagram everywhere. The source is reference material
for regeneration, not a parallel render.

---

## 1. The pipeline (flowchart)

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

<details>
<summary>Mermaid source</summary>

```mmd
graph TD
  A[Source .mmd] --> B[mermaid-tui]
  B --> C[Unicode art]
  C --> D[Wrap in fence]
  D --> E[.md file]
  E --> F[Glow]
  F --> G[Reads correctly]
```

</details>

---

## 2. Brief lifecycle (state diagram)

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

<details>
<summary>Mermaid source</summary>

```mmd
stateDiagram-v2
  [*] --> Draft
  Draft --> Pending : submit
  Pending --> InProgress : approve
  InProgress --> Complete : finish
  Complete --> [*]
  Pending --> Draft : reject
```

</details>

---

## 3. The round-trip (sequence diagram)

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

<details>
<summary>Mermaid source</summary>

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

</details>

---

## Verdict

If you can read the three diagrams above in Glow, the pipeline works and the
tool is worth building. The brief is at
`briefs/2026-07-23-brief-mermaid-to-md.md`.
