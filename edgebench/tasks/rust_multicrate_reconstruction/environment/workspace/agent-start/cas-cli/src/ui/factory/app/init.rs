use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::time::{Duration, Instant};

use cas_mux::{Mux, MuxConfig};
use ratatui::layout::Rect;

use crate::config::Config;
use crate::orchestration::names::generate_unique;
use crate::store::find_cas_root;
use crate::ui::factory::app::{
    AutoPromptConfig, EpicState, FactoryApp, FactoryConfig, detect_epic_state, epic_branch_name,
    queue_codex_worker_intro_prompt, queue_supervisor_intro_prompt,
};
use crate::ui::factory::director::{
    DirectorData, DirectorEventDetector, PanelAreas, SidecarFocus, ViewMode,
};
use crate::ui::factory::input::{FeedbackCategory, InputMode};
use crate::ui::factory::layout::PaneGrid;
use crate::ui::factory::notification::Notifier;
use crate::ui::factory::selection::Selection;
use crate::ui::theme::ActiveTheme;
use crate::worktree::{WorktreeConfig, WorktreeManager};

impl FactoryApp {
    /// Create a new factory app with the given configuration.
    pub fn new(config: FactoryConfig) -> anyhow::Result<Self> { todo!() }

    /// Create a FactoryApp from daemon initialization result.
    #[allow(clippy::too_many_arguments)]
    pub fn from_init_result(
        cas_dir: PathBuf,
        mux: Mux,
        worktree_manager: Option<WorktreeManager>,
        director_data: DirectorData,
        supervisor_name: String,
        worker_names: Vec<String>,
        notify_config: crate::ui::factory::notification::NotifyConfig,
        tabbed_workers: bool,
        auto_prompt: AutoPromptConfig,
        supervisor_cli: cas_mux::SupervisorCli,
        worker_cli: cas_mux::SupervisorCli,
        cols: u16,
        rows: u16,
        record_enabled: bool,
        recording_session_id: Option<String>,
        lead_session_id: Option<String>,
        project_dir: PathBuf,
    ) -> anyhow::Result<Self> { todo!() }
}
