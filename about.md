# mermaid-to-md

A CLI tool that renders Mermaid diagrams to Unicode box-drawing art and bakes
the art into markdown files.

The canonical claims — each with the command that proves it — live in
[docs/statements.md](docs/statements.md). This page is the tour, not the ledger.

## The one-liner

Tell your coding agent to orient itself to the project. It will check
everything and walk you through the rest.

## Entry points

| Command | What it does | Audience |
|---------|-------------|----------|
| `just orient` | Agent orientation — git, tasks, entry points | Agents |
| `just about` | This page — what the project is | Humans |
| `just test` | Run the inject/verify regression suite | Both |
| `just mermaid FILE` | Render ```mmd blocks from a markdown file | Both |
| `cargo build --release` | Build the Rust binary | Developers |

## What's in the box

**`mermaid-tui`** — the Rust binary. Reads Mermaid source from stdin, prints
Unicode box-drawing art to stdout. The engine.

**`mermaid-to-md`** — the batch wrapper. Bakes rendered art into markdown
files. Inject and verify modes for in-place updates and drift detection.
`just test` runs the regression suite.

**`mermaid-extract.sh`** — the sibling. Extracts ```mmd blocks from
markdown and renders them to the terminal.

## What it draws

Five families: `flowchart`/`graph`, `stateDiagram`, `classDiagram`,
`erDiagram`, and `sequenceDiagram`. Every other Mermaid family returns its
source in a framed box — a declared exclusion, not a rendering failure. (S8 in
[docs/statements.md](docs/statements.md).)

## The principle

The diagram is the product. The source is reference material. Render once,
ship text, done.
