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
echo 'graph TD\n  A --> B --> C' | ./target/release/mermaid-tui
```

Preview the demo:

```bash
just demo
# or
glow demo/mermaid-to-md-demo.md
```

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

`just` is a Rust crate and installs via cargo:

```bash
cargo install just
```

`glow` is **not** a Rust crate — it is Charm's Go binary, so `cargo install
glow` does not work (the `glow` crate on crates.io is an unrelated OpenGL
bindings library). Install the canonical Charm `glow` via a package manager
or Go:

```bash
brew install glow          # Homebrew (macOS or Linux)
pacman -S glow             # Arch
sudo snap install glow     # Snap
# Debian/Ubuntu and Fedora/RHEL: use Charm's apt/yum repo — see
#   https://github.com/charmbracelet/glow#installation
# or, with Go installed:
go install github.com/charmbracelet/glow/v2@latest
```

Both `just` and `glow` are also packaged by many distributions
(e.g. `apt`, `dnf`, `pacman`); exact names and availability vary.

**Contributing:** If you have verified install instructions for a specific
Linux distribution, please open a PR updating this section with the exact
commands and package names.

### Windows

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
