//! Status command

use std::path::Path;

use clap::Parser;

use crate::config::Config;
use crate::store::{open_code_store, open_rule_store, open_store};
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;
use cas_core::Syncer;

use crate::cli::Cli;

#[derive(Parser)]
pub struct StatusArgs {
    /// Verbose output
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn execute(args: &StatusArgs, cli: &Cli, cas_root: &Path) -> anyhow::Result<()> { todo!() }
