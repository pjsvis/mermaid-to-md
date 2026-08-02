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
// Art-first managed region (decisions/004): sentinel → ```text art → ```mmd
// source. The sentinel opens the region; a bare ```mmd is a fresh diagram.
// Idempotent. Sentinel: <!-- mermaid-to-md:art --> (decisions/002).
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
  let viaSentinel = false;
  for (const line of lines) {
    switch (state) {
      case 'TEXT':
        // Sentinel opens the managed region (004); a bare ```mmd is fresh.
        if (line === '<!-- mermaid-to-md:art -->') {
          state = 'AT_SENTINEL';
        } else if (line.startsWith('```mmd') || line.startsWith('```mermaid')) {
          state = 'IN_MMD'; buf = ''; viaSentinel = false;
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
      case 'AT_SENTINEL':   // sentinel consumed; expect ```text art to skip
        if (line === '```text') { state = 'SKIP_ART'; }
        else if (isBlank(line)) { /* tolerate */ }
        else { out += line + '\n'; state = 'TEXT'; }
        break;
      case 'SKIP_ART':      // discard existing art until its closing fence
        if (line === '```') { state = 'LOOK_FOR_SRC'; }
        break;
      case 'LOOK_FOR_SRC':  // old art dropped; expect ```mmd source to re-render
        if (line.startsWith('```mmd') || line.startsWith('```mermaid')) {
          state = 'IN_MMD'; buf = ''; viaSentinel = true;
        } else if (isBlank(line)) { /* consume */ }
        else if (line.startsWith('```')) { out += line + '\n'; state = 'IN_CODE'; }
        else { out += line + '\n'; state = 'TEXT'; }
        break;
      case 'IN_MMD':        // collect source; on close, emit the art-first region
        if (line === '```') {
          const art = render(buf);
          out += '<!-- mermaid-to-md:art -->\n```text\n' + art + '\n```\n\n```mmd\n' + buf + '```\n';
          state = viaSentinel ? 'TEXT' : 'AFTER_MMD';
          if (!viaSentinel) blanks = '';
        } else {
          buf += line + '\n';
        }
        break;
      case 'AFTER_MMD':     // bare-mmd region emitted; consume trailing OLD region
        if (line === '<!-- mermaid-to-md:art -->') {
          state = 'SKIP_SENTINEL';
        } else if (isBlank(line)) {
          blanks += line + '\n';
        } else if (line.startsWith('```mmd') || line.startsWith('```mermaid')) {
          out += blanks; state = 'IN_MMD'; buf = ''; viaSentinel = false;
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
// Sentinel-anchored freshness check (decisions/004). The sentinel opens the
// managed region: sentinel → ```text art → ```mmd source. A bare ```mmd with
// no preceding sentinel is `missing`. CI-friendly: no side effects.
// stderr: <file>:<line>: <status> (stale | missing | unclosed-mmd | unclosed-text)
if (mode === 'verify') {
  const file = verifyFile;
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    console.error(`Error: not found: ${file}`); process.exit(1);
  }
  const lines = readLines(file);
  let stale = 0, lineNo = 0, sentinelLine = 0;
  let state = 'TEXT', actual = '', buf = '', expected = '';
  for (const line of lines) {
    lineNo++;
    switch (state) {
      case 'TEXT':
        if (line === '<!-- mermaid-to-md:art -->') { state = 'IN_MANAGED'; sentinelLine = lineNo; }
        else if (line.startsWith('```mmd')) { console.error(`${file}:${lineNo}: missing`); stale = 1; state = 'SKIP_TO_CLOSE'; }
        else if (line.startsWith('```')) { state = 'IN_CODE'; }
        break;
      case 'IN_CODE':
        if (line === '```') state = 'TEXT';
        break;
      case 'SKIP_TO_CLOSE':  // consume orphan mmd block (already reported missing)
        if (line === '```') state = 'TEXT';
        break;
      case 'IN_MANAGED':     // after sentinel; expect ```text
        if (line === '```text') { state = 'IN_ART'; actual = ''; }
        else if (isBlank(line)) { /* skip */ }
        else if (line === '<!-- mermaid-to-md:art -->') { console.error(`${file}:${sentinelLine}: missing`); stale = 1; sentinelLine = lineNo; }
        else if (line.startsWith('```mmd')) { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'SKIP_TO_CLOSE'; }
        else if (line.startsWith('```')) { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'IN_CODE'; }
        else { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'TEXT'; }
        break;
      case 'IN_ART':         // collect actual art until its closing fence
        if (line === '```') { state = 'IN_MANAGED_SRC'; }
        else { actual += line + '\n'; }
        break;
      case 'IN_MANAGED_SRC': // after art close; expect ```mmd source
        if (line.startsWith('```mmd')) { state = 'IN_SRC'; buf = ''; }
        else if (isBlank(line)) { /* skip */ }
        else if (line === '<!-- mermaid-to-md:art -->') { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'IN_MANAGED'; sentinelLine = lineNo; }
        else if (line.startsWith('```')) { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'IN_CODE'; }
        else { console.error(`${file}:${sentinelLine}: missing`); stale = 1; state = 'TEXT'; }
        break;
      case 'IN_SRC':         // collect source until close; render expected, diff
        if (line === '```') {
          expected = render(buf);
          if (actual.endsWith('\n')) actual = actual.slice(0, -1);
          if (actual !== expected) { console.error(`${file}:${sentinelLine}: stale`); stale = 1; }
          state = 'TEXT';
        } else { buf += line + '\n'; }
        break;
    }
  }
  if (state === 'IN_MANAGED' || state === 'IN_MANAGED_SRC') { console.error(`${file}:${sentinelLine}: missing`); stale = 1; }
  if (state === 'IN_ART') { console.error(`${file}:${sentinelLine}: unclosed-text`); stale = 1; }
  if (state === 'IN_SRC') { console.error(`${file}:${sentinelLine}: unclosed-mmd`); stale = 1; }
  // SKIP_TO_CLOSE: orphan mmd already reported missing; silent at EOF.
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
// Art-first (decisions/004): sentinel → ```text art → ```mmd source. Same
// managed region as inject, so a baked file is a valid inject artifact —
// re-inject idempotent, --verify fresh. Source is a post-read checksum.
output += '<!-- mermaid-to-md:art -->\n```text\n' + art + '\n```\n\n```mmd\n' + src + '\n```\n';
writeOut(output);
process.exit(0);
