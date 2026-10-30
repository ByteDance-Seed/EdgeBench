//! Config command - comprehensive configuration management
//!
//! Provides commands for viewing, modifying, and managing CAS configuration
//! with rich metadata, validation, and export/import capabilities.

mod docs_ops;
mod edit_ops;
mod io_ops;
mod read_ops;
mod util;

use std::path::Path;

use clap::{Parser, Subcommand};

use crate::cli::Cli;

#[derive(Subcommand)]
pub enum ConfigCommands {
    /// Get a config value
    Get(ConfigGetArgs),

    /// Set a config value
    Set(ConfigSetArgs),

    /// List all config options
    List(ConfigListArgs),

    /// Show detailed information about a config option
    Describe(ConfigDescribeArgs),

    /// Show differences from default configuration
    Diff(ConfigDiffArgs),

    /// Reset config option(s) to default
    Reset(ConfigResetArgs),

    /// Export configuration to file
    Export(ConfigExportArgs),

    /// Import configuration from file
    Import(ConfigImportArgs),

    /// Search config options by keyword
    Search(ConfigSearchArgs),

    /// Show full configuration documentation
    Docs(ConfigDocsArgs),

    /// Generate shell completion scripts for config keys
    Completions(ConfigCompletionsArgs),

    /// Interactive config editor (simple line-based)
    Edit(ConfigEditArgs),
}

#[derive(Parser)]
pub struct ConfigGetArgs {
    /// Config key to get
    pub key: String,
}

#[derive(Parser)]
pub struct ConfigSetArgs {
    /// Config key to set
    pub key: String,

    /// Value to set
    pub value: String,
}

#[derive(Parser)]
pub struct ConfigListArgs {
    /// Show only a specific section
    #[arg(short, long)]
    pub section: Option<String>,

    /// Show all options (including advanced)
    #[arg(short, long)]
    pub all: bool,

    /// Show only modified values
    #[arg(short, long)]
    pub modified: bool,
}

#[derive(Parser)]
pub struct ConfigDescribeArgs {
    /// Config key to describe
    pub key: String,
}

#[derive(Parser)]
pub struct ConfigDiffArgs {
    /// Show all differences (not just non-advanced)
    #[arg(short, long)]
    pub all: bool,
}

#[derive(Parser)]
pub struct ConfigResetArgs {
    /// Config key to reset (or 'all' for everything)
    pub key: String,

    /// Skip confirmation for reset all
    #[arg(short, long)]
    pub force: bool,
}

#[derive(Parser)]
pub struct ConfigExportArgs {
    /// Output file (defaults to stdout)
    #[arg(short, long)]
    pub output: Option<String>,

    /// Export format
    #[arg(short, long, default_value = "yaml")]
    pub format: String,
}

#[derive(Parser)]
pub struct ConfigImportArgs {
    /// Input file to import
    pub file: String,

    /// Overwrite existing values
    #[arg(short, long)]
    pub force: bool,

    /// Dry run - show what would change
    #[arg(long)]
    pub dry_run: bool,
}

#[derive(Parser)]
pub struct ConfigSearchArgs {
    /// Search query
    pub query: String,
}

#[derive(Parser)]
pub struct ConfigDocsArgs {
    /// Show only a specific section
    #[arg(short, long)]
    pub section: Option<String>,

    /// Output format: text, markdown, or man
    #[arg(short, long, default_value = "text")]
    pub format: String,
}

#[derive(Parser)]
pub struct ConfigCompletionsArgs {
    /// Shell to generate completions for
    #[arg(value_enum)]
    pub shell: CompletionShell,
}

#[derive(Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub enum CompletionShell {
    Bash,
    Zsh,
    Fish,
}

#[derive(Parser)]
pub struct ConfigEditArgs {
    /// Edit only a specific section
    #[arg(short, long)]
    pub section: Option<String>,

    /// Edit only modified values
    #[arg(short, long)]
    pub modified: bool,

    /// Include advanced options
    #[arg(short, long)]
    pub all: bool,
}

/// Execute a config command
///
/// cas_root is resolved once at CLI entry point and passed here.
pub fn execute_subcommand(cmd: &ConfigCommands, cli: &Cli, cas_root: &Path) -> anyhow::Result<()> { todo!() }
