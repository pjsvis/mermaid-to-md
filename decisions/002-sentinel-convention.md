# decision: sentinel convention for injected art blocks

**Created:** 2026-07-25
**Status:** decided
**Resolves:** the open decision flagged in `debriefs/002` — *"The sentinel
convention is an open decision Phase 2 must make before implementing
idempotency."*
**Related:** `briefs/001-mermaid-to-md.md` (Phase 2/3 spec), `scripts/mermaid-to-md.sh`

## Context

Phase 2 inject mode (`td-fba03a`) renders each ```` ```mmd ```` source block
in a markdown file and inserts (or replaces) a ```` ```text ```` art block
immediately after it. To be idempotent — re-running `--inject` must replace
old art, not duplicate it — the tool must distinguish the art blocks *it
manages* from ```` ```text ```` blocks the user authored for other reasons.
That distinction is the sentinel's job. It also serves Phase 3 (`--verify`),
which must not false-positive on manually-authored art.

Brief 001 suggested ```` <!-- mermaid-to-md:art --> ```` as an example
sentinel but left the convention open. This record closes it.

## Decision

**A single HTML comment** — ```` <!-- mermaid-to-md:art --> ```` — **on its
own line, immediately preceding the** ```` ```text ```` **fence it manages.**

The managed region is the pair: the sentinel line plus the ```` ```text ````
```
fence block that follows it (blanks between sentinel and fence are tolerated
and normalised away on inject). Inject creates the pair; inject and verify
recognise the pair. A ```` ```text ```` block with no preceding sentinel is
user content — untouched by inject, ignored by verify.

Layout after inject:

````markdown
```mmd
graph TD
  A --> B
```
<!-- mermaid-to-md:art -->
```text
 ┌───┐   ┌───┐
 │ A │──▶│ B │
 └───┘   └───┘
```
````

## Rationale

**1. Single, not paired.** The alternative — open/close sentinels wrapping
the art block (`<!-- mermaid-to-md:art-start -->` … `<!-- mermaid-to-md:art-end -->`)
— was rejected. Paired sentinels add four lines of scaffolding noise per
diagram in the raw file. This tool's whole reason for existing is that the
diagram is readable in `cat`, Glow, any text viewer (brief 001: *"the diagram
is the product"*). Scaffolding noise that a terminal reader has to skip past
is entropy in the output. The single sentinel costs one line and sits above
the fence, out of the art itself.

**2. Before the fence, not inside it.** Putting the sentinel as the first
line inside the ```` ```text ```` block was rejected — it pollutes the art
block with a comment line, breaking copy-paste of the diagram and breaking
`--verify`'s diff (the art would carry the sentinel). The sentinel belongs
outside the rendered content.

**3. HTML comment, not a fence info string.** A fence info string
(``` ```text mermaid-to-md:art ```) was rejected: info-string semantics vary
across renderers, it's invisible to a human reading the raw file, and it
couples the marker to fence syntax. An HTML comment is plain, visible in the
raw file, renders as nothing in GitHub/Glow, and is unambiguous.

**4. The managed region is unambiguous without a close marker.** A ```` ```text ````
fence block has exactly one closing ```` ``` ````. The managed region is
sentinel → opening fence → content → closing fence. There is no ambiguity
about where it ends, so no close sentinel is needed. (Mermaid source and
Unicode box-art do not contain ```` ``` ````, so fence parsing is safe.)

## Contract

- **Inject** creates `sentinel + ```text + art + ```` after every ```` ```mmd ````
  (and after every ```` ```mermaid ```` , which is converted to ```` ```mmd ```` ).
  If a managed region already follows that ```` ```mmd ````, it is replaced;
  otherwise the pair is inserted.
- **Verify** re-renders each ```` ```mmd ```` source and diffs against the
  art in the following managed region. Stale art → exit 1. ```` ```text ````
  blocks without a sentinel are not checked (they are user content).
- **Unmarked** ```` ```text ```` blocks are never touched by either mode.

## Consequences

- `scripts/mermaid-to-md.sh` `--inject` implements the single-sentinel
  contract. `--verify` (Phase 3) reads the same convention.
- A markdown file with pre-sentinel ```` ```text ```` art blocks (authored
  before this convention existed) is **not** auto-migrated: inject will
  insert a *new* managed pair after the ```` ```mmd ````, leaving the old
  unmarked block in place. This is a one-time manual migration, not a
  recurring cost — and the safe default (inject never deletes user content).
- The sentinel string is the tool's name in a comment: `mermaid-to-md:art`.
  It is namespaced by the tool name, so it will not collide with other
  tools' HTML comments.

## What this is not

Not a decision about `--inject`'s output target (in-place vs `-o`), error
handling, or Phase 3's exit-code semantics. Those are implementation details
for `td-fba03a` and `td-18482f` respectively, governed by brief 001's
acceptance criteria.
