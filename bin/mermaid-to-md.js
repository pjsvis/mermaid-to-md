#!/usr/bin/env node
// mermaid-to-md — JS CLI wrapper for the npm package.
// Resolves the platform-specific binary and execs it.
// Placeholder — to be implemented in Phase 2 of the spin-off brief.

const { execFileSync } = require('child_process');
const path = require('path');

// Platform → package suffix mapping
const platformPackages = {
  'darwin-arm64': 'mermaid-to-md-darwin-arm64',
  'darwin-x64': 'mermaid-to-md-darwin-x64',
  'linux-x64': 'mermaid-to-md-linux-x64',
  'linux-arm64': 'mermaid-to-md-linux-arm64',
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
  const pkgDir = path.dirname(pkgPath);
  binaryPath = path.join(pkgDir, 'bin', 'mermaid-tui');
} catch {
  console.error(`Platform package not installed: ${pkgName}`);
  console.error(`Install it with: npm install -g ${pkgName}`);
  process.exit(1);
}

// Exec the binary, forwarding stdin/stdout/stderr
try {
  execFileSync(binaryPath, process.argv.slice(2), {
    stdio: 'inherit',
  });
} catch (err) {
  process.exit(err.status || 1);
}
