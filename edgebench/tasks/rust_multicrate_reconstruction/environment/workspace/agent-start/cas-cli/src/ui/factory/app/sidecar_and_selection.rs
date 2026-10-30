use crate::ui::factory::app::imports::*;

impl FactoryApp {
    // ========================================================================
    // Sidecar navigation
    // ========================================================================

    /// Toggle sidecar focus (enter if None, exit if focused)
    pub fn toggle_sidecar_focus(&mut self) { todo!() }

    /// Move to next sidecar panel
    pub fn next_sidecar_panel(&mut self) { todo!() }

    /// Move to previous sidecar panel
    pub fn prev_sidecar_panel(&mut self) { todo!() }

    /// Focus a specific sidecar panel
    pub fn focus_sidecar_panel(&mut self, panel: SidecarFocus) { todo!() }

    /// Get the item count for a given panel focus.
    fn item_count_for_focus(&self, focus: SidecarFocus) -> usize { todo!() }

    /// Initialize selection for the currently focused panel
    fn init_panel_selection(&mut self) { todo!() }

    /// Scroll up in the current sidecar panel
    pub fn sidecar_scroll_up(&mut self) { todo!() }

    /// Scroll down in the current sidecar panel
    pub fn sidecar_scroll_down(&mut self) { todo!() }

    /// Check if sidecar is focused
    pub fn sidecar_is_focused(&self) -> bool { todo!() }

    /// Handle mouse click - focus the clicked panel, tab, or pane
    pub fn handle_click(&mut self, x: u16, y: u16) { todo!() }

    /// Calculate which tab was clicked based on x position
    fn calculate_clicked_tab(&self, x: u16, tab_bar: &Rect) -> Option<usize> { todo!() }

    /// Register a session ID to pane name mapping
    ///
    /// This is called when a Claude session is detected to enable
    /// interaction routing to the correct pane.
    pub fn register_session(&mut self, session_id: &str, pane_name: &str) { todo!() }

    /// Sync session_id → pane_name mappings from the agent store
    ///
    /// Queries registered agents and maps their session IDs to pane names.
    pub(super) fn sync_session_mappings(&mut self) { todo!() }

    /// Handle mouse scroll up
    pub fn handle_scroll_up(&mut self) { todo!() }

    /// Handle mouse scroll down
    pub fn handle_scroll_down(&mut self) { todo!() }

    /// Handle mouse up - finalize selection and copy to clipboard
    pub fn handle_mouse_up(&mut self) { todo!() }

    /// Start a text selection at the given screen position
    pub fn start_selection(&mut self, screen_x: u16, screen_y: u16) { todo!() }

    /// Update the selection end position during drag
    pub fn update_selection(&mut self, screen_x: u16, screen_y: u16) { todo!() }

    /// Extend the selection endpoint when scrolling while holding the mouse button.
    /// Moves the selection end row by `delta` lines (negative = up, positive = down).
    pub fn extend_selection_by_scroll(&mut self, delta: i32) { todo!() }

    /// Clear the current selection
    pub fn clear_selection(&mut self) { todo!() }

    /// Get the current selection reference
    pub fn selection(&self) -> &crate::ui::factory::selection::Selection { todo!() }

    /// Convert screen coordinates to pane-relative coordinates
    ///
    /// Returns (pane_name, row, col) if the coordinates are inside a pane.
    pub fn pane_at_screen(&self, x: u16, y: u16) -> Option<String> { todo!() }

    /// Convert screen coordinates to pane-relative coordinates
    ///
    /// Returns (pane_name, row, col) if the coordinates are inside a pane.
    fn screen_to_pane_coords(&self, x: u16, y: u16) -> Option<(String, u16, u16)> { todo!() }

    /// Get the currently selected text, if any.
    ///
    /// Returns None if no text is selected.
    pub fn get_selected_text(&self) -> Option<String> { todo!() }

    /// Scroll the supervisor pane by delta lines
    pub fn scroll_supervisor(&mut self, delta: i32) { todo!() }

    /// Scroll the focused pane by delta lines
    pub fn scroll_focused_pane(&mut self, delta: i32) { todo!() }

    /// Scroll the supervisor pane to bottom (most recent content)
    pub fn scroll_supervisor_to_bottom(&mut self) { todo!() }

    /// Handle Enter key - open detail dialog for selected item
    pub fn handle_enter(&mut self) { todo!() }

    /// Open the task detail dialog for the selected task
    pub fn open_task_dialog(&mut self) { todo!() }

    /// Close the task detail dialog
    pub fn close_task_dialog(&mut self) { todo!() }

    /// Open the reminder detail dialog for the selected reminder
    pub fn open_reminder_dialog(&mut self) { todo!() }

    /// Close the reminder detail dialog
    pub fn close_reminder_dialog(&mut self) { todo!() }

    /// Handle Escape key - return to overview or unfocus sidecar
    pub fn handle_escape(&mut self) -> bool { todo!() }

    /// Compute the total number of display items in the task panel.
    ///
    /// Must match the item count produced by `tasks::render_with_focus()`,
    /// including epic headers, subtasks (when not collapsed), separators, and standalone tasks.
    fn task_display_item_count(&self) -> usize { todo!() }

    /// Get the ID of the selected task (if any).
    ///
    /// Walks through display items (epic headers, subtasks, separators, standalone)
    /// to correctly map the selected display index to a task ID.
    fn get_selected_task_id(&self) -> Option<String> { todo!() }

    /// Get the selected task (if any).
    pub fn get_selected_task(&self) -> Option<&crate::ui::factory::director::TaskSummary> { todo!() }

    /// Scroll detail view up
    pub fn detail_scroll_up(&mut self) { todo!() }

    /// Scroll detail view down
    pub fn detail_scroll_down(&mut self) { todo!() }

    // ========================================================================
    // Mission Control navigation
    // ========================================================================

    /// Check if we are in Mission Control mode.
    pub fn is_mission_control(&self) -> bool { todo!() }

    /// Cycle Mission Control focus to the next panel.
    pub fn mc_focus_next(&mut self) { todo!() }

    /// Cycle Mission Control focus to the previous panel.
    pub fn mc_focus_prev(&mut self) { todo!() }

    /// Jump MC focus to a specific panel.
    pub fn mc_focus_panel(&mut self, panel: crate::ui::factory::renderer::MissionControlFocus) { todo!() }

    /// Initialize selection for the MC-focused panel.
    fn mc_init_panel_selection(&mut self) { todo!() }

    /// Scroll up in the MC-focused panel.
    pub fn mc_scroll_up(&mut self) { todo!() }

    /// Scroll down in the MC-focused panel.
    pub fn mc_scroll_down(&mut self) { todo!() }

    /// Handle Enter in Mission Control view.
    pub fn mc_handle_enter(&mut self) { todo!() }

    /// Handle Escape in Mission Control view. Returns true if something was closed.
    pub fn mc_handle_escape(&mut self) -> bool { todo!() }

    /// Enter inject mode from Mission Control.
    /// Targets the selected worker (if Workers panel focused), otherwise supervisor.
    pub fn mc_start_inject(&mut self) { todo!() }

    /// Toggle epic collapse from Mission Control Tasks panel.
    pub fn mc_toggle_collapse(&mut self) { todo!() }

    /// Toggle collapse for selected directory in changes panel (MC variant).
    fn toggle_selected_dir_collapse_mc(&mut self) { todo!() }
}
