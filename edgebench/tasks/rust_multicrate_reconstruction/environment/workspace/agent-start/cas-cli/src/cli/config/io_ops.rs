use std::collections::HashMap;
use std::io::{self, Write};
use std::path::Path;

use crate::cli::Cli;
use crate::cli::config::{ConfigExportArgs, ConfigImportArgs};
use crate::config::Config;
use crate::ui::components::{Formatter, Renderable, StatusLine};
use crate::ui::theme::ActiveTheme;

pub(crate) fn execute_export(
    args: &ConfigExportArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_import(
    args: &ConfigImportArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }
