# release checklist

**Purpose:** the steps and obligations that fire at first npm release and every
release after. The tool is green and the pipeline exists (`release.yml`); this
is the bookkeeping that stops the docs or the package graph from quietly
drifting at the moment of publish. Resolves brief 007 items B4, E1, N1, N3.

## Version single-source (E1)

- **`Cargo.toml` is the source of truth** for the project version.
- The release tag (`v0.1.0`) must match `Cargo.toml`. Tag it; don't bump the
  package.json files by hand.
- `release.yml` derives every npm version from the tag: each platform package
  is `npm version`'d to `$VERSION` before publish, and the main package's
  `version` **and its `optionalDependencies` pins** are set to `$VERSION` in
  the `publish-main` step. The pins are the load-bearing part — `npm version`
  alone does not bump `optionalDependencies`, so the main package would
  otherwise republish with stale platform pins and resolve the wrong binary.
- Docs reference the version generically ("the latest release",
  `--version <version>`), not a hardcoded number that drifts.
- `SYSTEM.md`'s `version@repo` (e.g. `1.1.1@mermaid-to-md`) is a **different
  axis** — the Protocol version, not the project version. Keep decoupled (E2,
  deferred).

## Platform packages (N1)

- The five `npm/<platform>/package.json` files are **binary providers** for the
  main package, not standalone CLIs. They carry **no `bin` field** — installing
  one directly does not put anything on PATH.
- The main package's JS wrapper (`bin/mermaid-to-md.js`) resolves the platform
  binary by path (`require.resolve('<pkg>/package.json')` + `bin/<exe>`), not
  via PATH or a `bin` field. So the field is unnecessary, and omitting it
  prevents a confusing partial install (a raw `mermaid-tui` on PATH without the
  bake/inject/verify wrapper).
- The raw `mermaid-tui` renderer is reachable via `install.sh` (curl|sh) or
  `cargo build`; the npm entry point is the wrapper, `mermaid-to-md`.

## Release-time doc updates (N3)

At first npm publish (and each release), update the standard docs so
`just check-docs` stays green with an empty allowlist:

- [ ] `about.md` / `README.md`: change "once published" → "installed"; drop
      `npx mermaid-to-md` placeholders if the install command changed.
- [ ] `scripts/check-docs.sh`: drop the `ALLOW` entry
      (`once published|npm packaging is pending|npx mermaid-to-md`) once the
      markers are gone. An empty allowlist is the goal — leftover placeholder
      language then fails the check.
- [ ] Bump `Cargo.toml` version → tag `v<version>` → push the tag. `release.yml`
      does the rest: build per platform, publish platform packages, publish the
      main package with synced `optionalDependencies` pins, upload binaries to
      the release.

## permissions (B4)

`release.yml` carries `permissions: contents: write` at the workflow root —
`softprops/action-gh-release@v2` needs it to create the release. Without it,
release creation 403s on the default `GITHUB_TOKEN`.
