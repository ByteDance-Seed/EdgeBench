//! Queue CLI commands for prompt queue operations.
//!
//! Used by native extensions to poll for messages and acknowledge delivery.

use std::io;

use clap::{Args, Subcommand};

use crate::store::{find_cas_root, open_prompt_queue_store};
use crate::ui::components::{Formatter, Renderable, StatusLine};
use crate::ui::theme::ActiveTheme;

#[derive(Subcommand)]
pub enum QueueCommands {
    /// Poll for pending messages targeted at an agent (marks as processed)
    Poll(QueuePollArgs),

    /// Acknowledge a message by ID
    Ack(QueueAckArgs),
}

#[derive(Args)]
pub struct QueuePollArgs {
    /// Target agent name to poll messages for
    #[arg(long)]
    pub target: String,

    /// Output format (json or text)
    #[arg(long, default_value = "text")]
    pub format: String,

    /// Maximum number of messages to return
    #[arg(long, default_value = "10")]
    pub limit: usize,
}

#[derive(Args)]
pub struct QueueAckArgs {
    /// Message ID to acknowledge
    #[arg(long)]
    pub id: i64,
}

pub fn execute(cmd: &QueueCommands, _cli: &super::Cli) -> anyhow::Result<()> { todo!() }
