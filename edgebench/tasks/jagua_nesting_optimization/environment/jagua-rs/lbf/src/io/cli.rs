use std::path::PathBuf;

use clap::{Parser, ValueEnum};
use log::LevelFilter;

#[derive(Parser, Debug)]
#[command(author, version, about)]
pub struct Cli {
    #[arg(short, long, value_name = "FILE")]
    pub input_file: PathBuf,
    #[arg(short, long, value_name = "FOLDER")]
    pub solution_folder: PathBuf,
    #[arg(short, long, value_name = "FILE")]
    pub config_file: Option<PathBuf>,
    #[arg(
        short,
        long,
        value_name = "[off, error, warn, info, debug, trace]",
        default_value = "info"
    )]
    pub log_level: LevelFilter,
    #[arg(short, long, value_enum, value_name = "TYPE OF PROBLEM")]
    pub prob_var: ProblemVariant,
}

#[derive(ValueEnum, Debug, Clone)]
pub enum ProblemVariant {
    #[clap(name = "bpp")]
    BinPackingProblem,
    #[clap(name = "spp")]
    StripPackingProblem,
}
