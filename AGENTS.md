# mermaid-to-md

MANDATORY: Use td for Task Management

Run td usage --new-session at conversation start (or after /clear).
Use td usage -q after first read.

## What this repo is

A CLI tool that renders Mermaid diagrams to Unicode box-drawing art and bakes
the art into markdown files — so diagrams are visible in Glow, `cat`, or any
text viewer without a Mermaid renderer.

The Rust binary (`mermaid-tui`) is the engine. Shell/JS wrappers compose the
batch, inject, and verify modes.

## Silo discipline

This repo follows the Standard Mono-Repo Pattern (briefs → decisions →
debriefs, with playbooks). Process directories emerge from the work — don't
create empty ones.

Code layout follows Rust/npm conventions: `Cargo.toml` at root, `src/` for
Rust source, `bin/` for the JS wrapper, `scripts/` for shell scripts.

## Bounded tasks & session newup discipline

Work in bounded phases. At a phase boundary: `td handoff`, `/clear`, resume
from `td context`. Half a dozen newups in a long session is not excessive —
it's the difference between O(n²) and O(n) cost.
