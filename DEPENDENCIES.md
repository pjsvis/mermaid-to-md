# Dependencies

## Viewing — no dependencies required

The baked diagrams in this repo (e.g. `agent-workflow-discussion.md`,
`demo/mermaid-to-md-demo.md`) are plain text in `text` code blocks. They
render in **any** markdown viewer — no Mermaid renderer, plugin, or runtime
required:

- **GitHub** — renders `text` code blocks as monospace preformatted text
- **glow** — terminal markdown viewer with nice rendering
- **`cat`** — `cat agent-workflow-discussion.md`
- **Any markdown renderer** — the art is in a fenced code block, not a
  Mermaid block

View before you commit to installing anything. Browse the repo on GitHub,
or clone and `cat` a file. The output requires nothing.

## Building — what you need

| Dependency | Why | Required? |
|-----------|-----|-----------|
| **Rust toolchain** (`cargo`) | Build the `mermaid-tui` binary | Yes — to build from source |
| **just** | Run the justfile recipes (`just orient`, `just demo`, etc.) | Optional — convenience commands |
| **glow** | Preview markdown with baked diagrams in the terminal | Optional — any markdown viewer works |

The dependencies below are for *building* and *previewing*, not for viewing.

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
printf 'graph TD\n  A --> B --> C\n' | ./target/release/mermaid-tui
```

Preview the demo:

```bash
just demo
# or
glow demo/mermaid-to-md-demo.md
```

---

## Omarchy / Arch Linux install (verified)

Verified on Omarchy 4.0.6 (Arch-based, x86_64), 2026-11-01. The same
commands apply to Arch Linux; package names come from the official repos.

### Rust toolchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Verify:

```bash
cargo --version
```

### just and glow

Both are in the Arch/Omarchy repositories — no `cargo install` needed:

```bash
sudo pacman -S just glow
```

Verify:

```bash
just --version
glow --version
```

### Build and run

```bash
git clone https://github.com/pjsvis/mermaid-to-md.git
cd mermaid-to-md
cargo build --release
printf 'graph TD\n  A --> B --> C\n' | ./target/release/mermaid-tui
```

Preview the demo:

```bash
just demo
# or
glow demo/mermaid-to-md-demo.md
```

**Gotcha — `echo` does not expand `\n` under bash.** Macs default to zsh,
where `echo 'graph TD\n  A --> B'` emits real newlines; Omarchy defaults to
bash, where it emits a literal `\n` and the renderer boxes the source as an
unknown diagram. Always use `printf` for multi-line stdin (as above).

### Install the CLI on PATH (verified)

`just install-local` copies the binary and symlinks the wrapper into
`~/.local/bin`:

```bash
just install-local
mermaid-to-md --version
printf 'graph TD\n  A --> B\n' | mermaid-to-md -
```

The binary must be **copied**, not symlinked into the build tree: the wrapper
first looks for `../target/release/mermaid-tui` relative to itself (which does
not exist off the build tree), then falls back to `command -v mermaid-tui`.
The symlinked wrapper is live, so the clone stays part of the installation —
`git pull` there updates the installed wrapper.

**`install.sh` is not usable yet.** It downloads release assets, and no
GitHub release has been published. Until one is, build from source as above.
The release workflow now uploads platform-named binaries
(`mermaid-tui-linux-x64`, …) so `install.sh` can select the right asset once a
release exists; this path was exercised locally against a mock release, not
against GitHub.

---

## Appendix: Windows (unverified)

The Rust toolchain installs via `rustup`:

```powershell
winget install Rustlang.Rustup
```

Or download from [https://rustup.rs](https://rustup.rs).

`just` is a Rust crate and installs via cargo:

```powershell
cargo install just
```

`glow` is **not** a Rust crate (it is Charm's Go binary), so `cargo install
glow` does not work. Install the canonical Charm `glow` via a Windows
package manager:

```powershell
winget install charmbracelet.glow
scoop install glow
choco install glow
```

Or, with Go installed:

```powershell
go install github.com/charmbracelet/glow/v2@latest
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
