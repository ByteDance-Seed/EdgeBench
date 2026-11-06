use std::sync::OnceLock;

use cas_factory_protocol::{
    STYLE_BOLD, STYLE_FAINT, STYLE_INVERSE, STYLE_INVISIBLE, STYLE_ITALIC, STYLE_STRIKETHROUGH,
    STYLE_UNDERLINE, StyleRun as ProtoStyleRun,
};
use ghostty_vt::{CellStyle, Rgb, StyleRun};
use ratatui::style::{Color, Modifier, Style};

pub(crate) fn debug_log_enabled() -> bool { todo!() }

/// Convert ghostty_vt CellStyle flags to protocol flags
pub(crate) fn cell_style_to_flags(style: &CellStyle) -> u32 { todo!() }

/// Convert ghostty_vt StyleRuns to protocol StyleRuns
pub(crate) fn convert_style_runs_to_proto(
    text: &str,
    runs: &[StyleRun],
    total_cols: usize,
) -> Vec<ProtoStyleRun> { todo!() }

/// Convert ghostty_vt CellStyle to ratatui Style
pub(crate) fn cell_style_to_ratatui(cell: &CellStyle) -> Style { todo!() }

/// Check if an RGB color is the default (0, 0, 0)
fn is_default_color(rgb: &Rgb) -> bool { todo!() }

/// Check if two CellStyles are equal (for span grouping)
pub(crate) fn styles_equal(a: &CellStyle, b: &CellStyle) -> bool { todo!() }
