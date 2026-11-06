//! Device management CLI commands
//!
//! Provides commands to list, name, remove, and configure devices.

use std::io;

use clap::{Parser, Subcommand};

use crate::cli::Cli;
use crate::cloud::{CloudConfig, DeviceConfig};
use crate::ui::components::{Formatter, KeyValue, Renderable, StatusLine, Table};
use crate::ui::theme::ActiveTheme;

/// Device management commands
#[derive(Subcommand)]
pub enum DeviceCommands {
    /// List all registered devices
    List,

    /// Name the current device
    Name(DeviceNameArgs),

    /// Remove (deregister) a device
    Remove(DeviceRemoveArgs),

    /// Set SSH config for a device
    SshConfig(DeviceSshConfigArgs),

    /// Show current device info
    Info,

    /// Register this device with CAS Cloud
    Register,
}

#[derive(Parser)]
pub struct DeviceNameArgs {
    /// Name to assign to the current device
    pub name: String,
}

#[derive(Parser)]
pub struct DeviceRemoveArgs {
    /// Device ID to remove
    pub id: String,
}

#[derive(Parser)]
pub struct DeviceSshConfigArgs {
    /// Device name or ID
    pub device: String,

    /// SSH host (e.g., user@hostname)
    pub host: String,
}

/// Execute a device subcommand
pub fn execute(cmd: &DeviceCommands, cli: &Cli) -> anyhow::Result<()> { todo!() }

/// Helper: load cloud config and ensure logged in
fn require_cloud_config() -> anyhow::Result<CloudConfig> { todo!() }

/// Helper: make authenticated API request
#[allow(clippy::result_large_err)]
fn api_get(config: &CloudConfig, path: &str) -> Result<ureq::Response, ureq::Error> { todo!() }

#[allow(clippy::result_large_err)]
fn api_post(
    config: &CloudConfig,
    path: &str,
    body: &serde_json::Value,
) -> Result<ureq::Response, ureq::Error> { todo!() }

#[allow(clippy::result_large_err)]
fn api_patch(
    config: &CloudConfig,
    path: &str,
    body: &serde_json::Value,
) -> Result<ureq::Response, ureq::Error> { todo!() }

#[allow(clippy::result_large_err)]
fn api_delete(config: &CloudConfig, path: &str) -> Result<ureq::Response, ureq::Error> { todo!() }

// --- Command implementations ---

fn execute_list(cli: &Cli) -> anyhow::Result<()> { todo!() }

fn execute_name(args: &DeviceNameArgs, cli: &Cli) -> anyhow::Result<()> { todo!() }

fn execute_remove(args: &DeviceRemoveArgs, cli: &Cli) -> anyhow::Result<()> { todo!() }

fn execute_ssh_config(args: &DeviceSshConfigArgs, cli: &Cli) -> anyhow::Result<()> { todo!() }

fn execute_info(cli: &Cli) -> anyhow::Result<()> { todo!() }

fn execute_register(cli: &Cli) -> anyhow::Result<()> { todo!() }
