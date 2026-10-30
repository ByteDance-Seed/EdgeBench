use std::collections::HashMap;
use std::path::Path;

use crate::cli::Cli;
use crate::cli::config::{
    ConfigDescribeArgs, ConfigDiffArgs, ConfigGetArgs, ConfigListArgs, ConfigResetArgs,
    ConfigSearchArgs, ConfigSetArgs,
};
use crate::config::{Config, registry};
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;

use crate::cli::config::util::{format_constraint, truncate_description};

pub(crate) fn execute_get(args: &ConfigGetArgs, cli: &Cli, cas_root: &Path) -> anyhow::Result<()> { todo!() }

fn execute_get_internal(config: &Config, key: &str, cli: &Cli) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_set(args: &ConfigSetArgs, cli: &Cli, cas_root: &Path) -> anyhow::Result<()> { todo!() }

fn execute_set_internal(
    config: &mut Config,
    key: &str,
    value: &str,
    cas_root: &std::path::Path,
    cli: &Cli,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_list(
    args: &ConfigListArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_describe(
    args: &ConfigDescribeArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_diff(
    args: &ConfigDiffArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_reset(
    args: &ConfigResetArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }

pub(crate) fn execute_search(
    args: &ConfigSearchArgs,
    cli: &Cli,
    cas_root: &Path,
) -> anyhow::Result<()> { todo!() }
