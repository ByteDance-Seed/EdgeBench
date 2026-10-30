//! Factory application state and orchestration

use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::PathBuf;
use std::time::{Duration, Instant, SystemTime};

use cas_mux::{Mux, PaneKind};
use ratatui::layout::Rect;

use super::director::{
    DiffLine, DirectorData, DirectorEvent, DirectorEventDetector, PanelAreas, Prompt, SidecarFocus,
    ViewMode, generate_prompt,
};
use crate::store::open_prompt_queue_store;
use crate::types::Worktree;
use crate::ui::factory::input::{InputMode, LayoutSizes};
use crate::ui::factory::layout::{FactoryLayout, PaneGrid};
use crate::ui::factory::notification::Notifier;
use crate::ui::theme::ActiveTheme;
use crate::ui::widgets::TreeItemType;
use crate::worktree::WorktreeManager;

mod imports;
mod init;
mod panels_and_modes;
mod render_and_ops;
mod sidecar_and_selection;

// Re-export from cas-factory for backward compatibility
pub use cas_factory::{AutoPromptConfig, EpicState, FactoryConfig};

/// Booting state for a worker that is being spawned (after prepare, before finish)
#[derive(Debug, Clone)]
pub struct PendingWorkerState {
    /// Worker name
    pub name: String,
    /// When this worker entered the pending state
    pub started_at: Instant,
    /// Whether this spawn is using worktree isolation
    pub isolate: bool,
}

/// Worktree preparation data (can be sent to background thread)
pub struct WorktreePrep {
    pub worktree_path: PathBuf,
    pub branch_name: String,
    pub parent_branch: String,
    pub repo_root: PathBuf,
    pub cas_dir: PathBuf,
}

/// Data needed to spawn a worker (phase 1 output, can be sent to background thread)
pub struct WorkerSpawnPrep {
    pub worker_name: String,
    pub worktree_info: Option<WorktreePrep>,
}

/// Result of background worktree preparation (phase 2 output)
pub struct WorkerSpawnResult {
    pub worker_name: String,
    pub cwd: PathBuf,
    pub cas_root: Option<PathBuf>,
    pub worktree: Option<Worktree>,
}

impl WorkerSpawnPrep {
    /// Phase 2: Run the slow git operations (designed for spawn_blocking).
    pub fn run(self) -> anyhow::Result<WorkerSpawnResult> { todo!() }
}

/// The main factory application
pub struct FactoryApp {
    /// The terminal multiplexer
    pub mux: Mux,
    /// CAS directory for data loading
    cas_dir: PathBuf,
    /// Director panel data
    director_data: DirectorData,
    /// Current input mode
    pub input_mode: InputMode,
    /// Buffer for inject mode text input
    pub inject_buffer: String,
    /// Target pane for injection
    pub inject_target: Option<String>,
    /// Show help overlay
    pub show_help: bool,
    /// Show file changes dialog
    pub show_changes_dialog: bool,
    /// Selected file for changes dialog (source_path, file_path, source_name, agent_name)
    pub changes_dialog_file: Option<(PathBuf, String, String, Option<String>)>,
    /// Scroll offset for changes dialog diff
    pub changes_dialog_scroll: u16,
    /// Cached diff lines for changes dialog
    pub changes_dialog_diff: Vec<DiffLine>,
    /// Show task detail dialog
    pub show_task_dialog: bool,
    /// Selected task ID for task dialog
    pub task_dialog_id: Option<String>,
    /// Scroll offset for task dialog
    pub task_dialog_scroll: u16,
    /// Max scroll offset for task dialog (computed during render)
    pub task_dialog_max_scroll: u16,
    /// Show reminder detail dialog
    pub show_reminder_dialog: bool,
    /// Selected reminder index for reminder dialog
    pub reminder_dialog_idx: Option<usize>,
    /// Scroll offset for reminder dialog
    pub reminder_dialog_scroll: u16,
    /// Show terminal dialog (interactive shell)
    pub show_terminal_dialog: bool,
    /// Name of the shell pane in the mux
    pub terminal_pane_name: Option<String>,
    /// Show feedback dialog
    pub show_feedback_dialog: bool,
    /// Current feedback category
    pub feedback_category: super::input::FeedbackCategory,
    /// Feedback text buffer
    pub feedback_buffer: String,
    /// Last CAS data refresh time
    last_refresh: Instant,
    /// Refresh interval for CAS data
    refresh_interval: Duration,
    /// Last observed CAS DB file fingerprint used for cheap change detection
    last_db_fingerprint: Option<CasDbFingerprint>,
    /// Last git refresh time
    last_git_refresh: Instant,
    /// Interval for expensive git refresh operations
    git_refresh_interval: Duration,
    /// Theme for rendering
    theme: ActiveTheme,
    /// Worker names (for reference)
    worker_names: Vec<String>,
    /// Supervisor name (for reference)
    supervisor_name: String,
    /// Factory session name (for prompt queue isolation)
    factory_session: Option<String>,
    /// Supervisor CLI mode (claude/codex)
    supervisor_cli: cas_mux::SupervisorCli,
    /// Worker CLI mode (claude/codex)
    worker_cli: cas_mux::SupervisorCli,
    /// Error message to display (cleared on next key or after timeout)
    pub error_message: Option<String>,
    /// Number of workers currently being spawned (for loading indicator)
    pub spawning_count: usize,
    /// Workers currently in the spawning pipeline (after prepare, before finish).
    /// These appear as booting placeholder panes in the layout.
    pub pending_workers: Vec<PendingWorkerState>,
    /// When the error message was set (for auto-dismiss)
    error_set_at: Option<Instant>,
    /// Sidebar collapsed state
    pub sidecar_collapsed: bool,
    /// Worktree manager for worker isolation (None if worktrees disabled)
    worktree_manager: Option<WorktreeManager>,
    /// Index of the currently selected worker tab (0-based, used in tabbed mode)
    pub selected_worker_tab: usize,
    /// Use tabbed worker view instead of side-by-side (config preference)
    tabbed_workers: bool,
    /// Actual tabbed mode active (accounts for auto-switch due to space constraints)
    is_tabbed: bool,
    /// Custom layout percentages (None = use defaults)
    pub layout_sizes: Option<LayoutSizes>,
    /// Spatial grid for pane navigation (rebuilt on layout change)
    pane_grid: PaneGrid,
    /// Currently selected pane in pane select mode
    selected_pane: Option<String>,
    /// Event detector for CAS state changes
    event_detector: DirectorEventDetector,
    /// Notification manager
    notifier: Notifier,
    /// Current epic state
    epic_state: EpicState,
    /// Sidecar panel focus
    pub sidecar_focus: SidecarFocus,
    /// Sidecar panel scroll/collapse state
    pub panels: super::director::PanelRegistry,
    /// Panel areas for click detection (updated during render)
    panel_areas: PanelAreas,
    /// Current view mode for the sidecar
    pub view_mode: ViewMode,
    /// Scroll offset for detail views
    detail_scroll: u16,
    /// Agent filter (None = show all)
    pub agent_filter: Option<String>,
    /// Cached diff content for FileDiff view (used by search)
    diff_cache: Vec<DiffLine>,
    /// Scroll offset for diff view (legacy, used by search jump)
    diff_scroll: u16,
    /// Parsed diff metadata for DiffWidget rendering
    diff_metadata: Option<cas_diffs::FileDiffMetadata>,
    /// Syntax highlighter for diff rendering
    syntax_highlighter: cas_diffs::highlight::SyntaxHighlighter,
    /// Scroll/hunk navigation state for DiffWidget
    diff_view_state: cas_diffs::widget::DiffViewState,
    /// Diff display style (unified vs split)
    diff_display_style: cas_diffs::iter::DiffStyle,
    /// Inline diff highlighting mode
    diff_inline_mode: cas_diffs::LineDiffType,
    /// Whether to show line numbers in diff view
    diff_show_line_numbers: bool,
    /// Expanded hunk regions (for expanding collapsed context)
    diff_expanded_hunks: std::collections::HashMap<usize, cas_diffs::iter::HunkExpansionRegion>,
    /// Whether all collapsed regions are expanded
    diff_expand_all: bool,
    /// Whether diff search input mode is active
    diff_search_mode: bool,
    /// Current diff search query
    diff_search_query: String,
    /// Line indices that match the search query
    diff_search_matches: Vec<usize>,
    /// Current match index (for n/N navigation)
    diff_search_current: usize,
    /// Collapsed epic IDs (epics whose subtasks are hidden)
    collapsed_epics: HashSet<String>,
    /// Collapsed directory paths in changes panel
    collapsed_dirs: HashSet<String>,
    /// Tree item types for changes panel (for scroll bounds)
    changes_item_types: Vec<TreeItemType>,
    /// Layout areas for click detection (updated during render)
    worker_tab_bar_area: Option<Rect>,
    worker_content_area: Option<Rect>,
    worker_areas: Vec<Rect>,
    supervisor_area: Option<Rect>,
    sidecar_area: Option<Rect>,
    /// Stored terminal dimensions (for daemon mode where crossterm::terminal::size() doesn't work)
    terminal_cols: u16,
    terminal_rows: u16,
    /// Current text selection (for copy support)
    selection: super::selection::Selection,
    /// Auto-prompting configuration
    auto_prompt: AutoPromptConfig,
    /// Epic branch name (e.g., "epic/add-user-auth") - workers branch from this
    epic_branch: Option<String>,
    /// Whether recording is enabled for this session
    record_enabled: bool,
    /// Session ID for recordings (only set if record_enabled)
    recording_session_id: Option<String>,
    /// When recording started (for computing event timestamps)
    recording_start: Option<Instant>,
    /// Collected events during this session (for export)
    recorded_events: Vec<(Instant, DirectorEvent)>,
    /// UUID for the team lead's Claude Code session (for Teams config.json)
    lead_session_id: Option<String>,
    /// Project directory (for git operations)
    project_dir: PathBuf,
    /// Session ID to pane name mapping for interaction routing
    session_to_pane: HashMap<String, String>,
    /// Last time Ctrl+C was sent to a pane (debounce rapid repeated presses)
    pub last_interrupt_time: Option<Instant>,
    /// Top-level view mode (Panes vs Mission Control)
    pub factory_view_mode: crate::ui::factory::renderer::FactoryViewMode,
    /// Which panel has focus in Mission Control view
    pub mc_focus: crate::ui::factory::renderer::MissionControlFocus,
    /// Mission Control panel areas for click detection (updated during render)
    mc_workers_area: Rect,
    mc_tasks_area: Rect,
    mc_changes_area: Rect,
    mc_activity_area: Rect,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct CasDbFingerprint {
    db_mtime: Option<SystemTime>,
    wal_mtime: Option<SystemTime>,
}

impl CasDbFingerprint {
    fn from_cas_dir(cas_dir: &std::path::Path) -> Self { todo!() }
}

fn file_mtime(path: &std::path::Path) -> Option<SystemTime> { todo!() }

/// Convert a title to a branch-safe slug
fn slugify(title: &str) -> String { todo!() }

/// Create the epic branch name from a title
pub(crate) fn epic_branch_name(title: &str) -> String { todo!() }

impl FactoryApp {
    fn filter_director_agents_to_current_session(&mut self) { todo!() }

    /// Check if we should refresh CAS data
    pub fn should_refresh(&self) -> bool { todo!() }

    /// Check if automatic prompting is globally enabled
    pub fn auto_prompt_enabled(&self) -> bool { todo!() }

    /// Get the auto-prompt configuration
    pub fn auto_prompt_config(&self) -> &AutoPromptConfig { todo!() }

    /// Refresh CAS data from stores and detect state changes
    ///
    /// Returns a tuple of (prompts, events) for further processing.
    pub fn refresh_data(&mut self) -> anyhow::Result<(Vec<Prompt>, Vec<DirectorEvent>)> { todo!() }

    /// Get the focused pane kind
    pub fn focused_kind(&self) -> Option<&PaneKind> { todo!() }

    /// Check if the supervisor pane is focused
    pub fn focused_is_supervisor(&self) -> bool { todo!() }

    /// Check if a worker pane is focused
    pub fn focused_is_worker(&self) -> bool { todo!() }

    /// Check if the focused pane accepts keyboard input
    ///
    /// Supervisor and worker panes accept keyboard input.
    pub fn focused_accepts_input(&self) -> bool { todo!() }

    /// Get all worker names for layout (real + pending booting workers)
    pub fn layout_worker_names(&self) -> Vec<String> { todo!() }

    /// Check if a worker name is pending (still booting)
    pub fn is_pending_worker(&self, name: &str) -> bool { todo!() }

    /// Add a worker to the pending set (called after prepare_worker_spawn succeeds)
    pub fn add_pending_worker(&mut self, name: String, isolate: bool) { todo!() }

    /// Remove a worker from the pending set (called on spawn success or failure)
    pub fn remove_pending_worker(&mut self, name: &str) { todo!() }

    /// Get worker names
    pub fn worker_names(&self) -> &[String] { todo!() }

    /// Get the number of active workers
    pub fn worker_count(&self) -> usize { todo!() }

    /// Select a worker tab by index (0-based)
    ///
    /// Returns true if the selection changed.
    pub fn select_worker_tab(&mut self, index: usize) -> bool { todo!() }

    /// Select a worker tab by 1-based number (for keyboard shortcuts)
    ///
    /// Returns true if the selection changed.
    pub fn select_worker_by_number(&mut self, number: usize) -> bool { todo!() }

    /// Get the currently selected worker name
    pub fn selected_worker(&self) -> Option<&str> { todo!() }

    /// Ensure selected_worker_tab is valid after workers change
    fn clamp_selected_worker_tab(&mut self) { todo!() }

    /// Get supervisor name
    pub fn supervisor_name(&self) -> &str { todo!() }

    /// Get factory session name (for prompt queue isolation)
    pub fn factory_session(&self) -> Option<&str> { todo!() }

    /// Set factory session name
    pub fn set_factory_session(&mut self, name: String) { todo!() }

    /// Get the worktree manager (if worktrees are enabled)
    pub fn worktree_manager(&self) -> Option<&WorktreeManager> { todo!() }

    /// Get the worktree manager mutably (if worktrees are enabled)
    pub fn worktree_manager_mut(&mut self) -> Option<&mut WorktreeManager> { todo!() }

    /// Check if worktree-based isolation is enabled
    pub fn worktrees_enabled(&self) -> bool { todo!() }

    /// Get the lead session ID (UUID for Teams config.json)
    pub fn lead_session_id(&self) -> Option<&str> { todo!() }

    /// Get the director data
    pub fn director_data(&self) -> &DirectorData { todo!() }

    /// Get the CAS directory path
    pub fn cas_dir(&self) -> &std::path::Path { todo!() }

    /// Get the theme
    pub fn theme(&self) -> &ActiveTheme { todo!() }

    /// Get the notifier
    pub fn notifier(&self) -> &Notifier { todo!() }

    /// Send notifications for detected events
    pub fn notify_events(&self, events: &[DirectorEvent]) { todo!() }

    /// Set an error message (auto-dismisses after 5 seconds)
    pub fn set_error(&mut self, msg: impl Into<String>) { todo!() }

    /// Clear the error message
    pub fn clear_error(&mut self) { todo!() }

    /// Check if error should be auto-dismissed (after 5 seconds)
    pub fn check_error_timeout(&mut self) { todo!() }

    /// Toggle between Panes and MissionControl factory view modes.
    pub fn toggle_factory_view_mode(&mut self) { todo!() }

    /// Toggle sidebar collapsed state
    pub fn toggle_sidecar_collapsed(&mut self) { todo!() }

    /// Handle resize event
    pub fn handle_resize(&mut self, cols: u16, rows: u16) -> anyhow::Result<()> { todo!() }

    /// Sync pane sizes with current terminal dimensions
    ///
    /// In daemon mode, crossterm::terminal::size() returns a default (80x24) instead
    /// of failing, so we prefer stored dimensions if they're set to something reasonable.
    pub fn sync_pane_sizes(&mut self) -> anyhow::Result<()> { todo!() }
}

fn merge_director_data_preserving_git(
    previous: &DirectorData,
    mut loaded: DirectorData,
    git_due: bool,
) -> DirectorData { todo!() }

pub(crate) fn queue_supervisor_intro_prompt(
    cas_dir: &std::path::Path,
    supervisor_name: &str,
    supervisor_cli: cas_mux::SupervisorCli,
    worker_names: &[String],
    factory_session: Option<&str>,
) { todo!() }

pub(crate) fn queue_codex_worker_intro_prompt(
    cas_dir: &std::path::Path,
    worker_name: &str,
    worker_cli: cas_mux::SupervisorCli,
) { todo!() }

/// A change in epic state
#[derive(Debug, Clone)]
pub enum EpicStateChange {
    /// An epic was started
    Started {
        epic_id: String,
        epic_title: String,
        previous_state: EpicState,
    },
    /// An epic was completed
    Completed { epic_id: String, epic_title: String },
}

/// Extract selected text from a terminal pane.
///
/// This function extracts text from the pane's terminal buffer based on
/// the selection coordinates. It handles single-line and multi-line
/// selections, respecting line boundaries.
fn extract_selected_text_from_pane(
    pane: &cas_mux::Pane,
    selection: &super::selection::Selection,
) -> Option<String> { todo!() }

/// Detect the initial epic state from loaded data
pub(crate) fn detect_epic_state(data: &DirectorData) -> EpicState { todo!() }

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use cas_factory::{FileChangeInfo, GitFileStatus, SourceChangesInfo};

    use super::{DirectorData, merge_director_data_preserving_git};

    fn data_with_changes(git_loaded: bool, changes: Vec<SourceChangesInfo>) -> DirectorData {
        DirectorData {
            ready_tasks: Vec::new(),
            in_progress_tasks: Vec::new(),
            epic_tasks: Vec::new(),
            agents: Vec::new(),
            activity: Vec::new(),
            agent_id_to_name: HashMap::new(),
            changes,
            git_loaded,
            reminders: Vec::new(),
            epic_closed_counts: HashMap::new(),
        }
    }


}
