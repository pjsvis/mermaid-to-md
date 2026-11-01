# Product statements

The canonical claims this product makes about itself. A statement belongs here
only if a command can falsify it; positioning without a prover lives in
`about.md`.

**How to use this file.** Standard docs (`README.md`, `about.md`, `USAGE.md`,
`DEPENDENCIES.md`) link here and quote these statements where the exact wording
matters. When a claim changes, change it here first, then reconcile the docs.
`scripts/check-docs.sh` enforces the link, the statement IDs, and the ban on
rot-prone counters.

**What does not belong here.** Test counts, roadmap, ambition, or any sentence
whose truth cannot be checked by running the prover. A count is output, not
documentation; run `just test` instead.

| ID | Statement | Prover |
|----|-----------|--------|
| S1 | mermaid-to-md renders Mermaid source to Unicode box-drawing art and bakes the art into markdown at authoring time. | `printf 'graph TD\n A-->B\n' \| mermaid-tui` |
| S2 | The diagram is the product; the source is reference material. Render once, ship text. | baked output is sentinel → art → source, and `mermaid-to-md --verify` accepts it |
| S3 | Bake: a `.mmd` source becomes a standalone markdown file containing the managed region (sentinel, `text` art, `mmd` source). | `scripts/test-inject.sh` bake assertions |
| S4 | Inject: every `mmd` or `mermaid` fence is rendered in place; re-running is idempotent. | `mermaid-to-md --inject doc.md` twice, then `--verify` |
| S5 | Verify: re-renders the managed regions and exits 1 on stale or missing art. | `mermaid-to-md --verify demo/mermaid-to-md-demo.md` |
| S6 | Source build is the only verified install today. npm packages and `install.sh` are packaged but unpublished; no GitHub release exists. | `curl -fsSL https://api.github.com/repos/pjsvis/mermaid-to-md/releases` returns `[]` |
| S7 | Platforms verified for install: macOS and Omarchy/Arch x86_64. Windows is unverified. | `DEPENDENCIES.md` install procedures |
| S8 | The renderer draws five families: `flowchart`/`graph`, `stateDiagram`, `classDiagram`, `erDiagram`, `sequenceDiagram`. Everything else returns framed source. | `src/mermaid.rs` dispatch chain; `gantt` fallback test |
| S9 | Baked art is plain text: no Mermaid renderer, plugin, or runtime is needed to view it. | `cat demo/mermaid-to-md-demo.md` |
| S10 | Rendering is deterministic: the same source yields the same bytes. | render the same source twice and `diff` the results |
| S11 | The wrapper layer is MIT; the renderer is Apache-2.0, carried from `xai-org/grok-build`. | `LICENSE`, `LICENSE-Apache-2.0.txt`, `NOTICE` |

## Supporting statements

These are true and useful, but they name internal mechanisms rather than
product claims. Keep them in the docs that own them.

- The wrapper emits to the file descriptor it was handed; it never reopens
  `/dev/stdout`. (See `scripts/mermaid-to-md.sh` and the caller-owned pipe
  assertion in `scripts/test-inject.sh`.)
- The release workflow names each binary `mermaid-tui-<platform>` so
  `install.sh` can select one. (See `.github/workflows/release.yml`.)
