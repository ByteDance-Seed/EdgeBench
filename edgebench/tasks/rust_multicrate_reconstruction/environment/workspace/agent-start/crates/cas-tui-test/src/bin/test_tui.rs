//! Simple test TUI for e2e testing
//!
//! A minimal ratatui-based TUI application that responds to keyboard input,
//! displays menus, and navigates between screens.
//!
//! Build with: cargo build -p cas-tui-test --bin test_tui --features test-tui
//! Run with: cargo run -p cas-tui-test --bin test_tui --features test-tui

#[cfg(feature = "test-tui")]
use std::io;
#[cfg(feature = "test-tui")]
use std::io::Stdout;

#[cfg(feature = "test-tui")]
use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
#[cfg(feature = "test-tui")]
use ratatui::{
    Frame, Terminal,
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
};

#[cfg(not(feature = "test-tui"))]
fn main() -> std::io::Result<()> { todo!() }

#[cfg(feature = "test-tui")]
fn main() -> io::Result<()> { todo!() }

#[cfg(feature = "test-tui")]
fn run_app(terminal: &mut Terminal<CrosstermBackend<Stdout>>) -> io::Result<()> { todo!() }

#[cfg(feature = "test-tui")]
#[derive(Default)]
struct App {
    screen: Screen,
    menu_state: ListState,
    counter: i32,
    input_text: String,
    submitted_text: Option<String>,
}

#[cfg(feature = "test-tui")]
#[derive(Default, Clone, Copy, PartialEq)]
enum Screen {
    #[default]
    Menu,
    Counter,
    Input,
    About,
}

#[cfg(feature = "test-tui")]
impl App {
    fn menu_up(&mut self) { todo!() }

    fn menu_down(&mut self) { todo!() }

    fn menu_select(&mut self) { todo!() }

    fn go_back(&mut self) { todo!() }
}

#[cfg(feature = "test-tui")]
fn ui(f: &mut Frame, app: &mut App) { todo!() }

#[cfg(feature = "test-tui")]
fn render_menu(f: &mut Frame, app: &mut App, area: Rect) { todo!() }

#[cfg(feature = "test-tui")]
fn render_counter(f: &mut Frame, app: &App, area: Rect) { todo!() }

#[cfg(feature = "test-tui")]
fn render_input(f: &mut Frame, app: &App, area: Rect) { todo!() }

#[cfg(feature = "test-tui")]
fn render_about(f: &mut Frame, area: Rect) { todo!() }
