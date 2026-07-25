# Dependencies

## What you need

| Dependency | Why | Required? |
|-----------|-----|-----------|
| **Rust toolchain** (`cargo`) | Build the `mermaid-tui` binary | Yes — to build from source |
| **just** | Run the justfile recipes (`just orient`, `just demo`, etc.) | Optional — convenience commands |
| **glow** | Preview markdown with baked diagrams in the terminal | Optional — any markdown viewer works |

The baked diagrams are plain text in `text` code blocks. They render in
**any** markdown viewer — GitHub, Glow, `cat`, any email client, any
renderer. No Mermaid renderer, plugin, or runtime is required to *view* the
output. The dependencies above are for *building* and *previewing*, not for
viewing.

## macOS install (verified)

### Rust toolchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Verify:

```bash
cargo --version
```

### just

```bash
brew install just
```

Verify:

```bash
just --version
```

### glow

```bash
brew install glow
```

Verify:

```bash
glow --version
```

### Build and run

```bash
git clone https://github.com/pjsvis/mermaid-to-md.git
cd mermaid-to-md
cargo build --release
echo 'graph TD\n  A --> B --> C' | ./target/release/mermaid-tui
```

Preview the demo:

```bash
just demo
# or
glow demo/mermaid-to-md-demo.md
```

## Viewing without dependencies

The baked diagrams in this repo (e.g. `agent-workflow-discussion.md`,
`demo/mermaid-to-md-demo.md`) are plain text. You can view them anywhere:

- **GitHub** — renders `text` code blocks as monospace preformatted text
- **`cat`** — `cat agent-workflow-discussion.md`
- **Any markdown renderer** — the art is in a fenced code block, not a
  Mermaid block

You only need the dependencies above to *build* the binary or run the
justfile recipes. Viewing the output requires nothing.

---

## Appendix: Linux and Windows

Install instructions for Linux and Windows are not yet verified from this
repo. Contributions welcome — see below.

### Linux

The Rust toolchain installs via the same `rustup` script as macOS:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

`just` and `glow` are available via cargo install if your distribution does
not package them:

```bash
cargo install just
cargo install glow
```

Or via your distribution's package manager (e.g. `apt`, `dnf`, `pacman`).
The exact package names and availability vary by distribution.

**Contributing:** If you have verified install instructions for a specific
Linux distribution, please open a PR updating this section with the exact
commands and package names.

### Windows

The Rust toolchain installs via `rustup`:

```powershell
winget install Rustlang.Rustup
```

Or download from [https://rustup.rs](https://rustup.rs).

`just` and `glow` are available via cargo:

```powershell
cargo install just
cargo install glow
```

**Contributing:** If you have verified install instructions for Windows
(including PowerShell vs CMD differences, PATH configuration, and any
Windows-specific gotchas), please open a PR updating this section.

### Contributing install instructions

Open a PR against this file (`DEPENDENCIES.md`) with:

1. The platform and architecture (e.g. "Ubuntu 24.04 x86_64", "Windows 11 ARM64")
2. The exact install commands, verified by running them
3. The verify commands and their expected output
4. Any gotchas specific to that platform
