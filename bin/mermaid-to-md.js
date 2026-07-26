#!/usr/bin/env node
// mermaid-to-md — JS CLI wrapper for the npm package.
// Functionally equivalent to scripts/mermaid-to-md.sh (bake/inject/verify).
// Resolves the platform-specific binary (an optional dependency, per the
// esbuild/biome pattern) and execs it for rendering. Cross-platform: no bash
// dependency, so inject/verify work on Windows too.

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// ── resolve the platform binary ─────────────────────────────────────────
const platformPackages = {
  'darwin-arm64': 'mermaid-to-md-darwin-arm64',
  'darwin-x64': 'mermaid-to-md-darwin-x64',
  'linux-x64': 'mermaid-to-md-linux-x64',
  'linux-arm64': 'mermaid-to-md-linux-arm64',
  'win32-x64': 'mermaid-to-md-win32-x64',
};

const platform = `${process.platform}-${process.arch}`;
const pkgName = platformPackages[platform];
if (!pkgName) {
  console.error(`Unsupported platform: ${platform}`);
  process.exit(1);
}

let binaryPath;
try {
  const pkgPath = require.resolve(`${pkgName}/package.json`);
  const exe = process.platform === 'win32' ? 'mermaid-tui.exe' : 'mermaid-tui';
  binaryPath = path.join(path.dirname(pkgPath), 'bin', exe);
} catch {
  console.error(`Platform package not installed: ${pkgName}`);
  console.error(`Install it with: npm install -g ${pkgName}`);
  process.exit(1);
}

// ── render helper: mermaid source (string) → art (string) ───────────────
// Mirror the bash `$(printf '%s' "$buf" | "$BIN" || true)` — command
// substitution strips trailing newlines; a failed render yields empty art.
function render(src) {
  try {
    return execFileSync(binaryPath, { input: src, encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 })
      .replace(/\n+$/, '');
  } catch {
    return '';
  }
}

// ── arg parsing ─────────────────────────────────────────────────────────
let mode = 'bake', injectFile = '', verifyFile = '', title = '', outfile = '', infile = '';
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--inject')      { mode = 'inject'; injectFile = args[++i]; if (!injectFile) { console.error('--inject needs a file'); process.exit(2); } }
  else if (a === '--verify') { mode = 'verify'; verifyFile = args[++i]; if (!verifyFile) { console.error('--verify needs a file'); process.exit(2); } }
  else if (a === '--title')  { title = args[++i]; if (title === undefined) { console.error('--title needs a value'); process.exit(2); } }
  else if (a === '-o' || a === '--output') { outfile = args[++i]; if (!outfile) { console.error('-o needs a value'); process.exit(2); } }
  else if (a === '-')         { infile = '-'; }
  else if (a.startsWith('-')) { console.error('Usage: mermaid-to-md [<file.mmd>|-] [--title T] [-o out] | --inject <file.md> [-o out] | --verify <file.md>'); process.exit(2); }
  else                        { infile = a; }
}

// ── helpers ─────────────────────────────────────────────────────────────
function readLines(file) {
  // Read file, split into lines, strip a single trailing \r (CRLF tolerance,
  // mirroring the bash `line="${line%$'\r'}"` fix, td-b8d0d9). A file ending
  // with \n yields a phantom trailing '' from split — drop it to match bash
  // `while IFS= read -r` semantics (which doesn't emit a final empty line).
  const content = fs.readFileSync(file, 'utf8');
  let lines = content.split('\n');
  if (content.endsWith('\n')) lines = lines.slice(0, -1);
  return lines.map(l => l.endsWith('\r') ? l.slice(0, -1) : l);
}

function isBlank(line) { return /^\s*$/.test(line); }

function writeOut(content) {
  if (outfile) fs.writeFileSync(outfile, content);
  else process.stdout.write(content);
}

// ── inject mode ─────────────────────────────────────────────────────────
// Render each ```mmd/```mermaid block, insert/replace the sentinel + ```text
// art block. Idempotent. Sentinel: <!-- mermaid-to-md:art --> (decisions/002).
if (mode === 'inject') {
  const file = injectFile;
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    console.error(`Error: not found: ${file}`); process.exit(1);
  }
  const lines = readLines(file);
  let out = '';
  let state = 'TEXT';
  let buf = '';
  let blanks = '';
  for (const line of lines) {
    switch (state) {
      case 'TEXT':
        if (line.startsWith('```mmd') || line.startsWith('```mermaid')) {
          out += '```mmd\n'; state = 'IN_MMD'; buf = '';
        } else if (line.startsWith('```')) {
          out += line + '\n'; state = 'IN_CODE';
        } else {
          out += line + '\n';
        }
        break;
      case 'IN_CODE':
        if (line === '```') { out += line + '\n'; state = 'TEXT'; }
        else { out += line + '\n'; }
        break;
      case 'IN_MMD':
        if (line === '```') {
          out += '```\n';
          const art = render(buf);
          out += '\n<!-- mermaid-to-md:art -->\n```text\n' + art + '\n```\n';
          state = 'AFTER_MMD'; blanks = '';
        } else {
          out += line + '\n'; buf += line + '\n';
        }
        break;
      case 'AFTER_MMD':
        if (line === '<!-- mermaid-to-md:art -->') {
          state = 'SKIP_SENTINEL';
        } else if (isBlank(line)) {
          blanks += line + '\n';
        } else if (line.startsWith('```mmd') || line.startsWith('```mermaid')) {
          out += blanks + '```mmd\n'; state = 'IN_MMD'; buf = '';
        } else if (line.startsWith('```')) {
          out += blanks + line + '\n'; state = 'IN_CODE';
        } else {
          out += blanks + line + '\n'; state = 'TEXT';
        }
        break;
      case 'SKIP_SENTINEL':
        if (line === '```text') { state = 'SKIP_TEXT'; }
        else if (isBlank(line)) { /* consume */ }
        else { out += line + '\n'; state = 'TEXT'; }
        break;
      case 'SKIP_TEXT':
        if (line === '```') { state = 'TEXT'; }
        break;
    }
  }
  if (state === 'AFTER_MMD' && blanks) out += blanks;

  if (outfile) fs.writeFileSync(outfile, out);
  else fs.writeFileSync(file, out);
  process.exit(0);
}

// ── verify mode ─────────────────────────────────────────────────────────
// Re-render each ```mmd, diff against the sentinel-marked art. CI-friendly:
// no side effects. Exit 0 if all fresh, 1 if any stale/missing.
// stderr: <file>:<line>: <status> (stale | missing | unclosed-mmd | unclosed-text)
if (mode === 'verify') {
  const file = verifyFile;
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    console.error(`Error: not found: ${file}`); process.exit(1);
  }
  const lines = readLines(file);
  let stale = 0, lineNo = 0, mmdLine = 0;
  let state = 'TEXT', buf = '', expected = '', actual = '';
  for (const line of lines) {
    lineNo++;
    switch (state) {
      case 'TEXT':
        if (line.startsWith('```mmd')) { state = 'IN_MMD'; buf = ''; mmdLine = lineNo; }
        else if (line.startsWith('```')) { state = 'IN_CODE'; }
        break;
      case 'IN_CODE':
        if (line === '```') state = 'TEXT';
        break;
      case 'IN_MMD':
        if (line === '```') { expected = render(buf); state = 'AFTER_MMD'; }
        else { buf += line + '\n'; }
        break;
      case 'AFTER_MMD':
        if (line === '<!-- mermaid-to-md:art -->') { state = 'SKIP_SENTINEL'; }
        else if (isBlank(line)) { /* skip */ }
        else if (line.startsWith('```mmd')) { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'IN_MMD'; buf = ''; mmdLine = lineNo; }
        else if (line.startsWith('```')) { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'IN_CODE'; }
        else { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'TEXT'; }
        break;
      case 'SKIP_SENTINEL':
        if (line === '```text') { state = 'SKIP_TEXT'; actual = ''; }
        else if (isBlank(line)) { /* skip */ }
        else if (line.startsWith('```mmd')) { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'IN_MMD'; buf = ''; mmdLine = lineNo; }
        else if (line.startsWith('```')) { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'IN_CODE'; }
        else { console.error(`${file}:${mmdLine}: missing`); stale = 1; state = 'TEXT'; }
        break;
      case 'SKIP_TEXT':
        if (line === '```') {
          if (actual.endsWith('\n')) actual = actual.slice(0, -1);
          if (actual !== expected) { console.error(`${file}:${mmdLine}: stale`); stale = 1; }
          state = 'TEXT';
        } else { actual += line + '\n'; }
        break;
    }
  }
  if (state === 'AFTER_MMD' || state === 'SKIP_SENTINEL') { console.error(`${file}:${mmdLine}: missing`); stale = 1; }
  if (state === 'IN_MMD') { console.error(`${file}:${mmdLine}: unclosed-mmd`); stale = 1; }
  if (state === 'SKIP_TEXT') { console.error(`${file}:${mmdLine}: unclosed-text`); stale = 1; }
  process.exit(stale ? 1 : 0);
}

// ── bake mode: render a .mmd source file (or stdin) to standalone .md ────
// Mirror the bash `src="$(cat "$infile")"` — command substitution strips
// trailing newlines, so the mmd source block is clean.
let src, fname;
if (!infile || infile === '-') {
  src = fs.readFileSync(0, 'utf8'); fname = '';
} else {
  if (!fs.existsSync(infile) || !fs.statSync(infile).isFile()) {
    console.error(`Error: not found: ${infile}`); process.exit(1);
  }
  src = fs.readFileSync(infile, 'utf8');
  fname = path.basename(infile, '.mmd');
}
src = src.replace(/\n+$/, '');   // match bash command-substitution stripping
if (!title && fname) title = fname.replace(/-/g, ' ').replace(/_/g, ' ');

// blank input → valid (near-)empty markdown, no crash
if (src.trim() === '') {
  if (title) writeOut('# ' + title + '\n');
  process.exit(0);
}

const art = render(src);
let output = '';
if (title) output += '# ' + title + '\n\n';
// Source-first, with the sentinel — same managed pair as inject (decisions/003).
// A baked file is a valid inject artifact: re-inject idempotent, --verify fresh.
output += '```mmd\n' + src + '\n```\n\n<!-- mermaid-to-md:art -->\n```text\n' + art + '\n```\n';
writeOut(output);
process.exit(0);
