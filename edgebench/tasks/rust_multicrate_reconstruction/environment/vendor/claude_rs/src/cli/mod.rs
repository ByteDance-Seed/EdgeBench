//! CLI process management.
//!
//! This module handles spawning and communicating with the Claude CLI process.
//!
//! Two modes are supported:
//! - PTY mode: Used for prompt-based queries where we need real-time output streaming
//! - Piped mode: Used for streaming input mode where stdin must be a pipe (not TTY)

mod command;
mod executable;
mod parser;

pub use command::CommandBuilder;
pub use executable::find_executable;
pub use parser::Parser;

use crate::error::{Error, Result};
use crate::message::Message;
use portable_pty::{CommandBuilder as PtyCommand, PtySize, native_pty_system};
use std::collections::HashMap;
use std::io::{BufRead, BufReader, Write};
use std::sync::mpsc;
use std::thread;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt};
use tokio::process::Command as TokioCommand;
use tokio::sync::mpsc as tokio_mpsc;

/// Handle to a running Claude CLI process.
pub struct Cli {
    /// Channel to send input to the CLI
    stdin_tx: mpsc::Sender<CliInput>,
    /// Channel to receive messages from the CLI
    message_rx: tokio_mpsc::Receiver<Result<Message>>,
    /// Child process killer handle (PTY mode)
    pty_child: Option<Box<dyn portable_pty::Child + Send>>,
    /// Child process handle (piped mode)
    piped_child: Option<tokio::process::Child>,
    /// Keep the master PTY alive (only used in PTY mode)
    _master: Option<Box<dyn portable_pty::MasterPty + Send>>,
}

/// Input commands that can be sent to the CLI
enum CliInput {
    /// Write text to stdin
    Write(String),
    /// Send EOF (close stdin)
    Eof,
    /// Send interrupt signal
    Interrupt,
}

impl Cli {
    /// Spawn a new Claude CLI process.
    ///
    /// # Arguments
    /// * `args` - Command line arguments for the claude CLI
    ///
    /// # Returns
    /// A handle to communicate with the CLI process.
    pub fn spawn(args: Vec<String>) -> Result<Self> {
        Self::spawn_with_cwd(args, None, None)
    }

    /// Spawn a new Claude CLI process with an optional working directory.
    ///
    /// # Arguments
    /// * `args` - Command line arguments for the claude CLI
    /// * `cwd` - Optional working directory for the CLI process
    /// * `env` - Optional environment variables to set on the process
    ///
    /// # Returns
    /// A handle to communicate with the CLI process.
    pub fn spawn_with_cwd(
        args: Vec<String>,
        cwd: Option<&std::path::Path>,
        env: Option<&HashMap<String, String>>,
    ) -> Result<Self> {
        let executable = find_executable()?;

        // SDK-spawned sessions are independent processes, not nested sessions.
        // Remove the CLAUDECODE flag to prevent nested session detection.
        // SAFETY: No other thread reads CLAUDECODE concurrently during spawn.
        unsafe { std::env::remove_var("CLAUDECODE") };

        // Create PTY
        let pty_system = native_pty_system();
        let pair = pty_system
            .openpty(PtySize {
                rows: 24,
                cols: 80,
                pixel_width: 0,
                pixel_height: 0,
            })
            .map_err(|e| Error::cli(format!("Failed to open PTY: {e}")))?;

        // Build command
        let mut cmd = PtyCommand::new(&executable);
        cmd.args(&args);

        // Set working directory if specified
        if let Some(dir) = cwd {
            cmd.cwd(dir);
        }

        // Apply user environment variables
        if let Some(vars) = env {
            for (key, value) in vars {
                cmd.env(key, value);
            }
        }

        // Spawn process on the slave side
        let child = pair
            .slave
            .spawn_command(cmd)
            .map_err(|e| Error::cli(format!("Failed to spawn claude: {e}")))?;

        // Drop slave - the child process owns it now
        drop(pair.slave);

        // Get master for I/O
        let master = pair.master;

        // Create channels
        let (stdin_tx, stdin_rx) = mpsc::channel::<CliInput>();
        let (message_tx, message_rx) = tokio_mpsc::channel::<Result<Message>>(100);

        // Get reader and writer from master
        let reader = master
            .try_clone_reader()
            .map_err(|e| Error::cli(format!("Failed to clone reader: {e}")))?;
        let mut writer = master
            .take_writer()
            .map_err(|e| Error::cli(format!("Failed to get writer: {e}")))?;

        // Spawn reader thread
        let message_tx_clone = message_tx.clone();
        thread::spawn(move || {
            let mut parser = Parser::new();
            let mut buf_reader = BufReader::new(reader);
            let mut line = String::new();

            loop {
                line.clear();
                match buf_reader.read_line(&mut line) {
                    Ok(0) => break, // EOF
                    Ok(_) => {
                        // Strip ANSI and parse
                        let stripped = strip_ansi_escapes::strip_str(&line);
                        for msg in parser.parse_line(&stripped) {
                            if message_tx_clone.blocking_send(Ok(msg)).is_err() {
                                return;
                            }
                        }
                    }
                    Err(e) => {
                        let _ = message_tx_clone.blocking_send(Err(Error::Io(e)));
                        break;
                    }
                }
            }
        });

        // Spawn writer thread
        thread::spawn(move || {
            while let Ok(input) = stdin_rx.recv() {
                match input {
                    CliInput::Write(text) => {
                        if writer.write_all(text.as_bytes()).is_err() {
                            break;
                        }
                        let _ = writer.flush();
                    }
                    CliInput::Eof => {
                        // Send Ctrl+D
                        let _ = writer.write_all(&[4]);
                        let _ = writer.flush();
                    }
                    CliInput::Interrupt => {
                        // Send Ctrl+C
                        let _ = writer.write_all(&[3]);
                        let _ = writer.flush();
                    }
                }
            }
        });

        Ok(Self {
            stdin_tx,
            message_rx,
            pty_child: Some(child),
            piped_child: None,
            _master: Some(master),
        })
    }

    /// Spawn a new Claude CLI process using piped stdin/stdout.
    ///
    /// This mode is required for streaming input (`--input-format stream-json`)
    /// because the CLI's `--print` flag requires non-TTY stdin.
    ///
    /// # Arguments
    /// * `args` - Command line arguments for the claude CLI
    ///
    /// # Returns
    /// A handle to communicate with the CLI process.
    pub fn spawn_piped(args: Vec<String>) -> Result<Self> {
        Self::spawn_piped_with_cwd(args, None, None)
    }

    /// Spawn a new Claude CLI process using piped stdin/stdout with optional working directory.
    ///
    /// # Arguments
    /// * `args` - Command line arguments for the claude CLI
    /// * `cwd` - Optional working directory for the CLI process
    /// * `env` - Optional environment variables to set on the process
    ///
    /// # Returns
    /// A handle to communicate with the CLI process.
    pub fn spawn_piped_with_cwd(
        args: Vec<String>,
        cwd: Option<&std::path::Path>,
        env: Option<&HashMap<String, String>>,
    ) -> Result<Self> {
        let executable = find_executable()?;

        // Create channels
        let (stdin_tx, stdin_rx) = mpsc::channel::<CliInput>();
        let (message_tx, message_rx) = tokio_mpsc::channel::<Result<Message>>(100);

        // Build the command
        let mut command = TokioCommand::new(&executable);
        command
            .args(&args)
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::null());

        // SDK-spawned sessions are independent processes, not nested sessions.
        // Remove the CLAUDECODE flag to prevent nested session detection.
        command.env_remove("CLAUDECODE");

        // Apply user environment variables
        if let Some(vars) = env {
            command.envs(vars);
        }

        // Set working directory if specified
        if let Some(dir) = cwd {
            command.current_dir(dir);
        }

        // Spawn the process with piped stdin/stdout
        let mut child = command
            .spawn()
            .map_err(|e| Error::cli(format!("Failed to spawn claude: {e}")))?;

        // Take stdin and stdout handles
        let mut child_stdin = child
            .stdin
            .take()
            .ok_or_else(|| Error::cli("Failed to get stdin"))?;
        let child_stdout = child
            .stdout
            .take()
            .ok_or_else(|| Error::cli("Failed to get stdout"))?;

        // Spawn async reader task
        let message_tx_clone = message_tx.clone();
        tokio::spawn(async move {
            let mut parser = Parser::new();
            let mut reader = tokio::io::BufReader::new(child_stdout);
            let mut line = String::new();

            loop {
                line.clear();
                match reader.read_line(&mut line).await {
                    Ok(0) => break, // EOF
                    Ok(_) => {
                        // Strip ANSI and parse
                        let stripped = strip_ansi_escapes::strip_str(&line);
                        for msg in parser.parse_line(&stripped) {
                            if message_tx_clone.send(Ok(msg)).await.is_err() {
                                return;
                            }
                        }
                    }
                    Err(e) => {
                        let _ = message_tx_clone
                            .send(Err(Error::cli(format!("Read error: {e}"))))
                            .await;
                        break;
                    }
                }
            }
        });

        // Spawn writer thread (sync, to handle mpsc::Receiver)
        thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();

            rt.block_on(async move {
                while let Ok(input) = stdin_rx.recv() {
                    match input {
                        CliInput::Write(text) => {
                            if child_stdin.write_all(text.as_bytes()).await.is_err() {
                                break;
                            }
                            let _ = child_stdin.flush().await;
                        }
                        CliInput::Eof => {
                            // Drop stdin to signal EOF
                            drop(child_stdin);
                            break;
                        }
                        CliInput::Interrupt => {
                            // Can't easily send Ctrl+C to piped process
                            // Just drop stdin
                            drop(child_stdin);
                            break;
                        }
                    }
                }
            });
        });

        Ok(Self {
            stdin_tx,
            message_rx,
            pty_child: None,
            piped_child: Some(child),
            _master: None,
        })
    }

    /// Write text to the CLI's stdin.
    pub fn write(&self, text: &str) -> Result<()> {
        self.stdin_tx
            .send(CliInput::Write(text.to_string()))
            .map_err(|_| Error::cli("CLI process has terminated"))
    }

    /// Send EOF to close stdin.
    pub fn send_eof(&self) -> Result<()> {
        self.stdin_tx
            .send(CliInput::Eof)
            .map_err(|_| Error::cli("CLI process has terminated"))
    }

    /// Send interrupt signal (Ctrl+C).
    pub fn interrupt(&self) -> Result<()> {
        self.stdin_tx
            .send(CliInput::Interrupt)
            .map_err(|_| Error::cli("CLI process has terminated"))
    }

    /// Receive the next message from the CLI.
    pub async fn recv(&mut self) -> Option<Result<Message>> {
        self.message_rx.recv().await
    }

    /// Kill the CLI process.
    pub fn kill(&mut self) -> Result<()> {
        // Kill PTY child if present
        if let Some(mut child) = self.pty_child.take() {
            child
                .kill()
                .map_err(|e| Error::cli(format!("Failed to kill process: {e}")))?;
        }
        // Kill piped child if present
        if let Some(ref mut child) = self.piped_child {
            // Use start_kill for non-blocking kill
            let _ = child.start_kill();
        }
        Ok(())
    }
}

impl Drop for Cli {
    fn drop(&mut self) {
        let _ = self.kill();
    }
}
