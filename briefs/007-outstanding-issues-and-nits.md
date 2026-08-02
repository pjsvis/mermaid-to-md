# brief: mermaid-to-md — outstanding issues and nits

**Created:** 2026-07-25
**Status:** resolved (2026-07-26) — all implementable items completed across three commits; E2/E3 remain genuinely deferred.
**Resolution:** `04942a7` (B1, B3), `538f9a9` (B2), `541c563` (B4, E1, N1-N3)
**Debrief:** `debriefs/005-session-2026-07-27.md` (post-resolution investigation — confirmed all items done, retired the brief)
**Depends on:** the shipped tool (bake/inject/verify wrapper, npm packaging, CI pipeline)
**Reference:** `debriefs/004` (deferred items), `td-6e3b3a` review (nits), `SYSTEM.md` (version@repo)

## What

A consolidation of every deferred item, flagged observation, and nit
accumulated across the build sessions. None are blocking — the tool ships,
the test suite passes (41/41), the npm packaging works end-to-end, and the
CI/release pipeline exists. This brief collects the loose ends so they don't
rot silently. Each item is small enough to be a task, not an epic.

Organised by severity: bugs first, then enhancements, then nits.

## Bugs

### B1: `--verify` misreports bake-output `mmd` blocks as `missing`

`--verify` flags every `mmd` block that has no following managed
sentinel+art region as `missing`. But bake-mode output embeds the `mmd`
source inside a `<details>` block (for reference), with no art after it —
that's by design, not drift. Running `--verify` on bake output (including
`demo/mermaid-to-md-demo.md`) reports `missing` at every baked diagram's
source block.

**Repro:** `scripts/mermaid-to-md.sh --verify demo/mermaid-to-md-demo.md`
→ exit 1, 3× `missing`.

**The question:** should `--verify` govern `mmd` blocks inside `<details>`
(bake output), or only `mmd` blocks in inject-mode files? The sentinel
convention (`decisions/002`) was designed for inject mode; bake output is a
different format. Options:
- (a) `--verify` skips `mmd` blocks inside `<details>` (recognise bake
  output structurally).
- (b) `--verify` only governs `mmd` blocks that have (or should have) a
  following sentinel — i.e., it's inject-mode-only, and bake output is out
  of scope by default.
- (c) A flag (`--verify --bake` or `--verify --strict`) controls the mode.

**Recommendation:** (b) — verify is inject-mode's drift detector; bake
output is a different artefact. But (a) is the less-surprising option if
verify-on-any-file is the intent. This is a design decision, not just a
fix — decide the semantics, then implement.

### B2: `while read` drops the last line if the file lacks a final newline

Both the bash wrapper (`while IFS= read -r line; do ... done < file`) and
the JS wrapper (`content.split('\n')` after dropping the phantom trailing
element) drop the last line of a file that doesn't end with a newline. This
is pre-existing (not introduced by the CRLF fix) and affects LF and CRLF
equally.

**Impact:** a markdown file whose last line is a closing ```` ``` ```` with
no trailing newline would lose that fence → `unclosed-mmd` (verify) or a
missing art block (inject). Rare in practice (editors usually add a final
newline) but a real edge case.

**Fix (bash):** `while IFS= read -r line || [[ -n "$line" ]]; do` — the
`|| [[ -n "$line" ]]` processes the final non-empty line even when `read`
returns nonzero at EOF.

**Fix (JS):** don't drop the last element if the file doesn't end with `\n`
— only drop the phantom when `content.endsWith('\n')` (which the current
code does, so the JS wrapper may already be correct — verify).

### B3: `ci.yml` smoke test uses `printf` without `shell: bash` on Windows

The "Smoke test — render via stdin" step runs `printf 'graph TD\n...'`  but
doesn't specify `shell: bash`. On `windows-latest`, the default shell is
PowerShell, where `printf` doesn't exist. The step will fail on the Windows
runner.

**Fix:** add `shell: bash` to the step, or use a cross-shell approach
(`echo` with a here-string, or move the smoke test into a script).

### B4: `release.yml` missing `permissions: contents: write`

`softprops/action-gh-release@v2` creates a GitHub Release, which requires
`contents: write` permission. The workflow doesn't set a `permissions`
block. Depending on the repo's default token permissions, the release
creation may fail with a 403.

**Fix:** add `permissions: contents: write` to the `build-platform` job (or
the workflow root).

## Enhancements

### E1: Semver pre-release — single source of truth in `Cargo.toml`

The version `0.1.0` is hardcoded in `Cargo.toml`, `package.json`, all 5
platform `package.json` files, and referenced (indirectly) in
`SYSTEM.md`'s `1.1.1@mermaid-to-md`. That's 8+ places a version can rot.

**Goal:** `Cargo.toml` `version = "0.1.0"` as the single source of truth.
The npm `package.json` files read it at build/publish time (the release.yml
already syncs via `npm version "$VERSION"` from the git tag, so npm is
covered). `about.md`/`README.md` should reference the version generically
(`mermaid-tui 0.1`) or not at all — not hardcode a number that drifts.

**Scope:** decide whether `SYSTEM.md`'s `version@repo` Protocol version and
the crate's semver version are the same thing or different axes. They
probably are different (Protocol version vs. product version) — keep them
decoupled. This brief is about the *product* version.

### E2: `version@repo` reconciliation

The repo's `SYSTEM.md` is at `1.1.1@mermaid-to-md`; the canonical Protocol
source (`~/.pi/agent/AGENTS.md` / cool-pi-extensions) is at `1.1.0` with
the full lexicon. The repo's copy has drifted (trimmed 5 eval terms,
restored the moat question). The `version@repo` convention makes this drift
*identifiable* but doesn't reconcile it.

**Goal:** decide whether repo `SYSTEM.md` files should track the canonical
source exactly (and how to sync), or whether drift is permanent and
`version@repo` is the only mechanism. This is a Protocol-level decision,
not a mermaid-to-md decision — it affects every repo that carries a
`SYSTEM.md`. May belong in cool-pi-extensions, not here. **Defer until the
Protocol adopts a position** (see `briefs/006`).

### E3: `install.sh` Windows support

`install.sh` handles darwin/linux × arm64/x64. Windows is unsupported
("install via npm"). The brief 002 out-of-scope note defers Windows
`install.sh` as "a PowerShell installer is a separate concern." The npm
path works on Windows already. A PowerShell `install.ps1` would be the
escape-hatch equivalent for Windows users who don't have Node.

**Scope:** optional — npm covers Windows. Only pursue if demand exists.

## Nits

### N1: Platform packages expose a `bin` field

Each `npm/<platform>/package.json` has `"bin": { "mermaid-tui": "bin/..." }`.
This means `npm install mermaid-to-md-darwin-arm64` directly would put
`mermaid-tui` on PATH. For optional-dep usage (the intended pattern) this is
harmless — the main package's JS wrapper resolves the binary by path, not
via the `bin` symlink. But it's an unintended side-effect: a user who
installs a platform package directly gets a raw `mermaid-tui` command with
no wrapper (no inject/verify).

**Fix:** remove the `bin` field from platform packages. The binary is
resolved by the main package via `require.resolve`, not by npm's bin
symlink. (Or keep it if direct-binary access is a feature — document the
choice.)

### N2: `check-docs` allowlist references the wrong td id

`scripts/check-docs.sh` allowlist comment says "When td-6e3b3a Phase 3
ships publishing, drop this." But the allowlist is about *doc markers*
(`once published`, `npx mermaid-to-md`), which are legitimate until npm
publishing happens — and npm publishing is the release.yml's job (td-6e3b3a
Phase 3, now shipped). The allowlist should be reviewed when the first npm
publish actually happens (a release tag), not when the pipeline ships. The
comment is slightly misleading.

**Fix:** update the comment to "drop when the first npm release is
published" rather than referencing the td id.

### N3: `about.md` / `README.md` "From npm (once published)" is a stale-pending marker

The `check-docs` allowlist admits `once published` and `npx mermaid-to-md`.
These are legitimate today (npm not yet published). But they're the exact
kind of marker the check is meant to catch — they just happen to be
accurate *now*. When the first release publishes, these markers become
stale and the check (after the allowlist is dropped) will flag them.

**This is the allowlist working as designed** — not a nit to fix, but a
note that the first release has a doc-update obligation: change "once
published" to "installed" and remove the allowlist entry. Record it so it's
not forgotten at release time.

## Out of scope

- **WASM build** — rejected for this product (brief 002). The live-preview
  variant is a separate product (brief 003, parked).
- **Homebrew tap** — npm + curl install covers the audience (brief 002).
- **Colour/ANSI in baked art** — plain text is the point.
- **Pi extension bridge** — the tool is standalone.

## Acceptance criteria

- [x] B1: `--verify` on `demo/mermaid-to-md-demo.md` exits 0 — resolved by option (d), unify output shape. `04942a7`, `decisions/003-verify-scope.md`.
- [x] B2: a file with no trailing newline is processed correctly — bash wrapper fixed (`|| [[ -n "$line" ]]`), JS wrapper verified already-correct. `538f9a9`.
- [x] B3: `ci.yml` smoke test passes on Windows — `shell: bash` added. `04942a7`.
- [x] B4: `release.yml` has `permissions: contents: write`. `541c563`.
- [x] E1: version lives in `Cargo.toml` as single source; README references `<version>` generically; release.yml syncs npm + optionalDependencies from git tag. `541c563`.
- [x] N1: `bin` field removed from all 5 platform packages — they are binary providers, not standalone CLIs. `541c563`, recorded in `docs/release-checklist.md`.
- [x] N2: `check-docs` allowlist comment corrected to "when the first npm release is published". `541c563`.
- [x] N3: release-time doc-update obligation recorded in `docs/release-checklist.md`. `541c563`.

## The Derrida question

"Should this even be in our consideration set?" Mostly yes — B1-B4 are real
bugs that will surface on first CI run or first verify-on-bake use. E1 is
worth doing before the version rots across 8 files. E2 and E3 are genuinely
deferrable (Protocol-level / demand-gated). The nits are cheap to fix and
cheap to defer — do them when touching the relevant file, not as standalone
work.

## The moat question

"Can you name your secrets?" The moat is the renderer; these are channel
fixes. None of them touch the moat — they're distribution and CI hygiene.
The brief exists because deferred items without a brief are lost threads
(elision-and-deferral playbook: a deferred decision not written down dies
at the boundary). This brief is deferral's bookkeeping.

## Post-resolution addendum (2026-07-27)

All implementable items were resolved on 2026-07-26 across three commits:
`04942a7` → `538f9a9` → `541c563`. Each commit referenced the brief and
item codes. The remaining items are genuinely deferred:

- **E2** (`version@repo` reconciliation) — depends on a Protocol-level
decision (how repo `SYSTEM.md` copies track the canonical source). Not a
mermaid-to-md concern.
- **E3** (`install.sh` Windows support) — demand-gated. npm covers
Windows; a PowerShell `install.ps1` is only warranted if demand
materialises.

The brief was stale until this session (2026-07-27), when `debriefs/005`
investigated B1 and found the entire brief already resolved. The stale
brief is itself a lesson: commit discipline ≠ bookkeeping discipline.
Commit messages documented the resolution to git; the brief itself was
never updated. See `debriefs/005-session-2026-07-27.md`.
