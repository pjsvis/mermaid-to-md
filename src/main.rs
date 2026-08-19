mod mermaid;

use mermaid::{render, MermaidStyles, Style};
use std::io::{self, Read};

const USAGE: &str = "mermaid-tui — render Mermaid source (stdin) to Unicode box-drawing art (stdout)

Usage:
  mermaid-tui [options] < source.mmd

Options:
  -w, --width <N>   Canvas width in columns (default: $COLUMNS, else 80)
  -h, --help        Print this help and exit
  -V, --version     Print version and exit

Reads Mermaid source from stdin; writes box-drawing art to stdout. Blank
input prints nothing. Malformed source renders best-effort, never crashes.

The bake/inject/verify modes live in the wrapper (mermaid-to-md), not here.";

fn main() {
    // Arg contract: the wrapper layer never passes args (it pipes stdin),
    // so flags are a human/CI convenience surface — strict by design.
    let mut width: Option<usize> = None;
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" => {
                println!("{USAGE}");
                return;
            }
            "-V" | "--version" => {
                println!("mermaid-tui {}", env!("CARGO_PKG_VERSION"));
                return;
            }
            "-w" | "--width" => match args.next() {
                Some(val) => match val.parse::<usize>() {
                    Ok(n) => width = Some(n),
                    Err(_) => {
                        eprintln!("error: --width wants a number, got {val:?}\n\n{USAGE}");
                        std::process::exit(2);
                    }
                },
                None => {
                    eprintln!("error: --width needs a value\n\n{USAGE}");
                    std::process::exit(2);
                }
            },
            other => {
                eprintln!("error: unknown option: {other}\n\n{USAGE}");
                std::process::exit(2);
            }
        }
    }

    let mut input = String::new();
    io::stdin().read_to_string(&mut input).expect("read stdin");

    let styles = MermaidStyles {
        border: Style::default(),
        node_text: Style::default(),
        edge: Style::default(),
        edge_label: Style::default(),
        title: Style::default(),
    };

    // Precedence: --width flag > $COLUMNS (terminal width when piped from
    // an interactive shell) > 80 (the historical default).
    let width = width
        .or_else(|| std::env::var("COLUMNS").ok().and_then(|s| s.parse().ok()))
        .or(Some(80));

    match render(&input, &styles, width) {
        Some(art) => {
            for line in &art.plain_lines {
                println!("{}", line);
            }
        }
        None => {
            // Blank input — print nothing
        }
    }
}
