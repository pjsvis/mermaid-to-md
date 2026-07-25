# brief: mermaid-to-md — spin-off to standalone npm package

**Created:** 2026-07-23
**Status:** Phase 1 complete (repo created, code migrated, binary builds). Phase 2+3 pending (td epic td-6e3b3a).
**Depends on:** brief 001 (the tool design — bake/inject/verify wrapper)
**Depends on:** `mermaid-tui` Rust binary — ✅ built in this repo
**Sibling:** `scripts/mermaid-extract.sh` (moved with the spin-off)

## What

Spin `mermaid-to-md` and its sibling `mermaid-extract` out of `cool-pi-extensions` into a standalone repository, package the `mermaid-tui` Rust binary as a precompiled native binary distributed via npm, and publish as `mermaid-to-md` on the npm registry. The tool has no dependency on Pi, the Edinburgh Protocol, or this repo's infrastructure — it's a general-purpose CLI for anyone who writes markdown and reads it in a terminal.

## Why

### The tool is general-purpose

`mermaid-to-md` solves a problem that has nothing to do with Pi extensions: Mermaid diagrams in markdown are only viewable with a renderer (GitHub web, VSCode plugin, browser). This tool bakes the rendered art into the markdown file itself, so the diagram is visible in Glow, `cat`, or any text viewer — no renderer required. That's useful to anyone who writes markdown docs, not just Pi users. Keeping it in `cool-pi-extensions` buries it.

### npm is the right distribution channel

The target audience is "people who write markdown docs and view them in terminals." That's a broad developer population, not Rust developers specifically. npm is pre-installed on more machines than cargo. `npx mermaid-to-md` is the lowest-friction trial path that exists — zero install, zero toolchain, just run it.

The pattern is mature: `esbuild` (Go binary), `@biomejs/biome` (Rust), `@swc/core` (Rust), `oxlint` (Rust) all ship precompiled native binaries via npm using optional platform dependencies. The JS wrapper is ~40 lines that finds the right platform binary and execs it.

### The terminal-native path (not WASM)

Simon Willison adapted the same Rust renderer for WASM. That's technically neat but solves the wrong problem for this product. The bake step renders at authoring time with a compiled binary (<15ms, zero runtime). The result is static text in a `​```text` block — `<pre><code>` with a monospace font in every browser. WASM would ship a runtime to the browser to re-render the same source at view time, producing the exact same box-drawing characters that are already in the file. That's a runtime detour to reach a destination the file is already at.

The hardcore terminal path — compile once, bake the art, ship text — is simpler, faster, and viewer-agnostic. The browser displays the art identically to the terminal because box-drawing characters are standard Unicode covered by every monospace font. No runtime, no glue, no client-side computation. WASM is rejected for this product (see the WASM section below). The one scenario where WASM is justified — browser-based live preview — is a different product, parked separately.

## Repo structure

```
mermaid-to-md/                       # new standalone repo
├── Cargo.toml                       # the mermaid-tui binary (moved from cool-pi-extensions)
├── src/
│   ├── main.rs                      # CLI entry point
│   └── mermaid.rs                   # the renderer (5,238 lines, already decoupled from ratatui)
├── bin/
│   └── mermaid-to-md.js             # JS CLI wrapper (~40 lines, replaces bash for npm)
├── scripts/
│   ├── mermaid-to-md.sh             # bash version kept for non-npm / curl install
│   └── mermaid-extract.sh           # sibling tool (extracts mmd from markdown → terminal)
├── npm/
│   ├── darwin-arm64/package.json    # optional dep, ships the precompiled binary
│   ├── darwin-x64/package.json
│   ├── linux-x64/package.json
│   ├── linux-arm64/package.json
│   └── win32-x64/package.json
├── .github/
│   └── workflows/
│       ├── ci.yml                   # build + test on push
│       └── release.yml              # build matrix + npm publish + GitHub release
├── README.md
├── package.json                     # main package, depends on optional platform packages
├── install.sh                       # curl | sh escape hatch for non-npm users
└── LICENSE
```

### What moves from cool-pi-extensions

- `src/cli/mermaid-tui/` (the Rust binary: `Cargo.toml`, `src/main.rs`, `src/mermaid.rs`)
- `scripts/mermaid-extract.sh` (the sibling extractor)
- The `mermaid-to-md.sh` script (to be written per the parent brief, Phase 1)
- The demo file `mermaid-to-md-demo.md` (becomes the README example)

### What stays in cool-pi-extensions

- The briefs (`2026-07-23-brief-mermaid-*.md`) — they're part of this repo's decision record
- The `just mermaid` recipe (can call the npm-installed binary or the local build)
- Any Pi extension bridge (separate concern, gated on actual Pi integration demand)

## How — phased

### Phase 1: Repo creation + code migration

1. Create `mermaid-to-md` repo (GitHub, public, MIT license)
2. Copy `src/cli/mermaid-tui/` → root of new repo
3. Copy `scripts/mermaid-extract.sh` → `scripts/`
4. Write `scripts/mermaid-to-md.sh` per the parent brief (Phase 1: bake, Phase 2: inject/verify)
5. Write `bin/mermaid-to-md.js` — the Node wrapper that replaces bash for npm distribution
6. Write `README.md` with the demo file as the example
7. Verify: `cargo build --release` produces the binary; `mermaid-to-md.sh` and `mermaid-to-md.js` both work

**Done when:** the new repo builds and the CLI works from a clean clone.

### Phase 2: npm packaging

1. Write `package.json` with `bin` field pointing to `bin/mermaid-to-md.js`
2. Create platform packages under `npm/<platform>/` — each ships the precompiled binary as an optional dependency
3. The JS wrapper resolves the platform package at runtime and execs the binary
4. Test locally: `npm pack` + `npm install -g ./mermaid-to-md-*.tgz` + `mermaid-to-md --help`

**Done when:** `npm install -g mermaid-to-md` installs the correct platform binary and the CLI works.

### Phase 3: CI + release pipeline

1. `ci.yml` — build + test on push (cargo test, CLI smoke tests)
2. `release.yml` — on git tag:
   - Build the Rust binary for 5 targets (darwin-arm64, darwin-x64, linux-x64, linux-arm64, win32-x64) using a GitHub Actions matrix
   - Publish each platform package to npm
   - Publish the main package to npm
   - Create a GitHub Release with the binaries attached
3. Write `install.sh` — `curl -fsSL https://raw.githubusercontent.com/.../install.sh | sh` for non-npm users (downloads the right binary from GitHub releases, puts it on PATH)

**Done when:** tagging a release publishes to npm and GitHub, and `npx mermaid-to-md` works on all 5 platforms.

### WASM: rejected for this product

WASM is not deferred or gated — it is **rejected** for the baked-art product. The bake step is the anti-WASM move: render once at authoring time with a compiled binary, ship the result as static text. WASM would ship a ~100KB binary + JS glue to the browser to run the renderer at view time, producing the exact same box-drawing characters that are already in the file. That's a runtime detour to reach a destination the file is already at.

The baked art is a `​```text` block — `<pre><code>` with a monospace font in every browser. The 16 non-ASCII characters used (box-drawing block U+2500–U+257F, geometric shapes U+25A0–U+25FF) are covered by every modern monospace font. The browser displays the art identically to the terminal, with no runtime, no renderer, no client-side computation. WASM adds cost to solve a problem the bake step already eliminated.

**The one narrow exception:** browser-based *live preview* (editing `.mmd` source in a web editor, seeing art update in real-time). The browser can't shell out to a native binary, so WASM is the only way to run the renderer client-side. But that's a different product (see `2026-07-23-brief-mermaid-live-preview.md`), a different audience (browser editors, not terminal editors), and it's parked. WASM is justified *there*, not here. Confusing the two is the error — the bake step makes WASM superfluous for batch rendering; only interactive browser preview needs it.

## Acceptance criteria

### Phase 1

- [ ] New `mermaid-to-md` repo exists, public, MIT licensed
- [ ] `cargo build --release` in the new repo produces the `mermaid-tui` binary
- [ ] `scripts/mermaid-to-md.sh` works (bake mode, per parent brief Phase 1)
- [ ] `bin/mermaid-to-md.js` works identically to the bash script
- [ ] `scripts/mermaid-extract.sh` works in the new repo
- [ ] README includes the demo (3 diagram types rendering in Glow)
- [ ] No references to Pi, Edinburgh Protocol, or `cool-pi-extensions` in the new repo

### Phase 2

- [ ] `package.json` has correct `bin` field and optional platform dependencies
- [ ] `npm pack` produces an installable tarball
- [ ] `npm install -g ./tarball` installs the correct platform binary
- [ ] `mermaid-to-md --help` works after npm install
- [ ] `mermaid-to-md --inject` and `--verify` modes work (per parent brief Phase 2)
- [ ] Platform packages ship only the binary (no source, no build step for the consumer)

### Phase 3

- [ ] `release.yml` builds 5 platform binaries via GitHub Actions matrix
- [ ] Tagging a release publishes all platform packages + main package to npm
- [ ] Tagging a release creates a GitHub Release with binaries attached
- [ ] `npx mermaid-to-md@latest < test.mmd` works on macOS (arm64 + x64) and Linux (x64 + arm64)
- [ ] `install.sh` downloads the correct binary from GitHub releases and puts it on PATH
- [ ] `install.sh` works on macOS and Linux (Windows deferred — PowerShell installer is a separate concern)

## Out of scope

- **WASM build** — rejected for this product (see above). The bake step renders at authoring time; the browser displays static text. WASM re-introduces a runtime to produce bytes that are already in the file. The only remaining WASM case is browser-based live preview — a different product, parked in `2026-07-23-brief-mermaid-live-preview.md`
- **Pi extension bridge** — the tool is standalone; any Pi integration is a separate brief in `cool-pi-extensions`
- **Homebrew tap** — npm + curl install covers the audience; Homebrew can be added later if demand exists
- **Windows `install.sh`** — a PowerShell installer is a separate concern; the npm path works on Windows already
- **Live-preview / watch mode** — regenerating on file save is composable via `entr` or `watchexec`; no need to build it in
- **Colour/ANSI in baked art** — plain text is the point (see parent brief)
- **Mermaid syntax validation** — bad syntax renders as a fallback box (the binary's behaviour)

## Relationship to existing briefs

- **`mermaid-to-md.md`** (parent): defines the tool's behaviour (bake, inject, verify). This brief defines the distribution. The parent brief's acceptance criteria still apply — this brief adds packaging and CI.
- **`mermaid-extract.md`** (sibling): moves to the new repo. Same binary, inverse operation. Ships in the same npm package (or as a separate command — `mermaid-to-md extract <file>` as a subcommand, or a separate `mermaid-extract` package).
- **`go-mermaid-renderer-01.md`**: the binary's origin brief. Stays in `cool-pi-extensions` as the decision record. The code moves.
- **`mermaid-diagrams-for-docs.md`**: stays in `cool-pi-extensions`. That brief is about authoring Mermaid *source* in this repo's docs. The spin-off doesn't affect it — if anything, the spin-off's `--inject` mode could be used to bake art into this repo's docs later.

## The Derrida question

"Should this even be in our consideration set?" Yes — but not here. The tool doesn't belong in `cool-pi-extensions` (a Pi tooling repo) and it doesn't depend on Pi. The spin-off is the correct silo. Keeping it here would be a category error — useful tool, wrong home.

## The moat question

"Can you name your secrets?" The secret is the 5,238-line Rust renderer — graph layout, edge routing, crossing minimisation, Mermaid parsing. It already exists, already works, already compiles standalone. The packaging (npm wrapper, CI matrix, platform binaries) is commodity infrastructure. The moat is the renderer; the distribution is the channel. This brief builds the channel.
