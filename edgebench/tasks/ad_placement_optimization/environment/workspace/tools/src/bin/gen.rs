#![allow(non_snake_case)]

use clap::Parser;
use std::{io::prelude::*, path::PathBuf};
use tools::*;

#[derive(Parser, Debug)]
struct Cli {
    /// Path to seeds.txt
    seeds: String,
    /// Path to input directory
    #[clap(short = 'd', long = "dir", default_value = "in")]
    dir: PathBuf,
    #[clap(short, long)]
    /// Print input details in csv format
    verbose: bool,
}

fn main() {
    let cli = Cli::parse();
    if !std::path::Path::new(&cli.dir).exists() {
        std::fs::create_dir(&cli.dir).unwrap();
    }
    let f = std::fs::File::open(&cli.seeds).unwrap_or_else(|_| {
        eprintln!("no such file: {}", cli.seeds);
        std::process::exit(1)
    });
    let f = std::io::BufReader::new(f);
    let mut id = 0;
    if cli.verbose {
        println!("file,seed");
    }
    for line in f.lines() {
        let line = line.unwrap();
        let line = line.trim();
        if line.len() == 0 {
            continue;
        }
        let seed = line.parse::<u64>().unwrap_or_else(|_| {
            eprintln!("parse failed: {}", line);
            std::process::exit(1)
        });
        let input = gen(seed);
        if cli.verbose {
            println!("{:04},{}", id, seed);
        }
        let mut w = std::io::BufWriter::new(
            std::fs::File::create(cli.dir.join(format!("{:04}.txt", id))).unwrap(),
        );
        write!(w, "{}", input).unwrap();
        id += 1;
    }
}
