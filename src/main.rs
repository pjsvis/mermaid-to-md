mod mermaid;

use mermaid::{render, MermaidStyles, Style};
use std::io::{self, Read};

fn main() {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input).expect("read stdin");

    let styles = MermaidStyles {
        border: Style::default(),
        node_text: Style::default(),
        edge: Style::default(),
        edge_label: Style::default(),
        title: Style::default(),
    };

    let width = std::env::var("COLUMNS")
        .ok()
        .and_then(|s| s.parse().ok())
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
