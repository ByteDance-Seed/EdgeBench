use std::io::{self, Write};

use crate::cli::Cli;
use crate::cli::config::{CompletionShell, ConfigCompletionsArgs, ConfigDocsArgs};
use crate::config::registry;
use crate::ui::components::{Formatter, Header, Renderable, StatusLine};
use crate::ui::theme::ActiveTheme;

use crate::cli::config::util::format_constraint;

pub(crate) fn execute_docs(args: &ConfigDocsArgs, cli: &Cli) -> anyhow::Result<()> { todo!() }

fn print_help_text(
    section_filter: &Option<String>,
    reg: &crate::config::ConfigRegistry,
    json: bool,
) -> io::Result<()> { todo!() }

fn print_help_markdown(
    section_filter: &Option<String>,
    reg: &crate::config::ConfigRegistry,
) -> io::Result<()> { todo!() }

fn print_help_man(
    section_filter: &Option<String>,
    reg: &crate::config::ConfigRegistry,
) -> io::Result<()> { todo!() }

pub(crate) fn execute_completions(args: &ConfigCompletionsArgs, _cli: &Cli) -> anyhow::Result<()> { todo!() }
