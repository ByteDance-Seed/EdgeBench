//! Cloud relay attach — connect to a remote factory via CAS Cloud WebSocket
//!
//! Opens a WebSocket to the cloud's terminal relay channel, sends user.attach,
//! receives PTY frames and renders in the local terminal, forwards keystrokes.

use anyhow::{Result, bail};
use base64::Engine;
use crossterm::event::{self, Event, KeyCode, KeyModifiers};
use crossterm::terminal::{self, disable_raw_mode, enable_raw_mode};
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::io::{self, Write};
use std::time::Duration;
use tokio_tungstenite::tungstenite::Message;

use crate::cloud::CloudConfig;
use crate::ui::components::{Formatter, Renderable, StatusLine};
use crate::ui::factory::phoenix::{encode_msg, ws_url};
use crate::ui::theme::ActiveTheme;

/// Execute cloud relay attach: connect to cloud, join terminal_relay channel,
/// forward I/O between local terminal and remote factory.
pub fn execute_cloud_attach(factory_id: &str) -> Result<()> { todo!() }

async fn relay_loop(endpoint: &str, token: &str, factory_id: &str) -> Result<()> { todo!() }

async fn relay_io_loop<W, R>(
    write: &mut W,
    read: &mut R,
    topic: &str,
    _client_id: &str,
) -> Result<()>
where
    W: SinkExt<Message, Error = tokio_tungstenite::tungstenite::Error> + Unpin,
    R: StreamExt<Item = Result<Message, tokio_tungstenite::tungstenite::Error>> + Unpin,
{ todo!() }

/// Handle an incoming relay message from the cloud
fn handle_relay_message(text: &str) -> Result<()> { todo!() }

/// Convert a key event to terminal bytes (simplified version of client.rs key_to_bytes)
fn key_to_bytes(key: &crossterm::event::KeyEvent) -> Vec<u8> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    // Phoenix protocol tests (ws_url, encode_msg) are in ui::factory::phoenix::tests


}
