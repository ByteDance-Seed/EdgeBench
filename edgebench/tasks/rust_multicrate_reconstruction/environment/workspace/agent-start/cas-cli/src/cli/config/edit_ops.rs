use std::collections::HashMap;
use std::path::Path;

use crate::cli::Cli;
use crate::cli::config::ConfigEditArgs;
use crate::config::{Config, registry};
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;

use crate::cli::config::util::truncate_description;

pub(crate) fn execute_edit(
    args: &ConfigEditArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_edit_line_based(
    args: &ConfigEditArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }
