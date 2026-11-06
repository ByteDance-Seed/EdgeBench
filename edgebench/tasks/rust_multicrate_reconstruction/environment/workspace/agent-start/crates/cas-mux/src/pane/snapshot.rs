use crate::error::{Error, Result};
use crate::pane::Pane;
use crate::pane::style::{cell_style_to_flags, convert_style_runs_to_proto, debug_log_enabled};
use cas_factory_protocol::{CacheRow, CursorPosition, RowData, TerminalCell, TerminalSnapshot};

impl Pane {
    /// Get scrollback information from the terminal
    pub fn scrollback_info(&self) -> ghostty_vt::ScrollbackInfo { todo!() }

    /// Get the current scroll offset (lines from bottom, 0 = at bottom)
    pub fn scroll_offset(&self) -> u32 { todo!() }

    /// Get the total number of scrollback lines
    pub fn scrollback_lines(&self) -> u32 { todo!() }

    /// Get a full terminal snapshot for the current viewport
    pub fn get_full_snapshot(&self) -> Result<TerminalSnapshot> { todo!() }

    #[allow(clippy::type_complexity)]
    pub fn get_incremental_update(
        &mut self,
    ) -> Result<Option<(Vec<RowData>, Option<CursorPosition>, u64)>> { todo!() }

    pub fn create_snapshot_with_cache(
        &self,
        cache_window: u32,
    ) -> Result<(TerminalSnapshot, Vec<CacheRow>, Option<u32>)> { todo!() }

    pub fn create_snapshot_rows_with_cache(
        &self,
        cache_window: u32,
    ) -> Result<(Vec<RowData>, Vec<CacheRow>, Option<u32>)> { todo!() }

    pub fn get_viewport_rows_data(&self) -> Result<Vec<RowData>> { todo!() }
}
