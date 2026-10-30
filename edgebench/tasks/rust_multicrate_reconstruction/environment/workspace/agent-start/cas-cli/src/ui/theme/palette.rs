//! Semantic color palette - what colors mean in context

use ratatui::style::Color;

use crate::ui::theme::colors::ColorPalette;

/// Semantic color palette mapping colors to UI meanings
#[derive(Debug, Clone)]
pub struct Palette {
    pub colors: ColorPalette,

    // Core UI
    pub bg_primary: Color,
    pub bg_secondary: Color,
    pub bg_elevated: Color,
    pub bg_overlay: Color,

    pub text_primary: Color,
    pub text_secondary: Color,
    pub text_muted: Color,
    pub text_disabled: Color,

    pub border_default: Color,
    pub border_focused: Color,
    pub border_muted: Color,

    // Interactive
    pub accent: Color,
    pub accent_dim: Color,
    pub selection_bg: Color,
    pub highlight_bg: Color,

    // Status indicators
    pub status_success: Color,
    pub status_warning: Color,
    pub status_error: Color,
    pub status_info: Color,
    pub status_neutral: Color,

    // Task status
    pub task_open: Color,
    pub task_in_progress: Color,
    pub task_blocked: Color,
    pub task_closed: Color,

    // Priority levels
    pub priority_critical: Color,
    pub priority_high: Color,
    pub priority_medium: Color,
    pub priority_low: Color,
    pub priority_backlog: Color,

    // Entity types
    pub entity_id: Color,
    pub entity_type: Color,
    pub entity_skill: Color,
    pub entity_rule: Color,
    pub entity_agent: Color,

    // Agent status
    pub agent_active: Color,
    pub agent_idle: Color,
    pub agent_dead: Color,

    // Skill status
    pub skill_enabled: Color,
    pub skill_disabled: Color,
    pub skill_draft: Color,

    // Rule status
    pub rule_draft: Color,
    pub rule_proven: Color,
    pub rule_stale: Color,
    pub rule_retired: Color,

    // Verification
    pub verification_approved: Color,
    pub verification_rejected: Color,
    pub verification_error: Color,
    pub verification_skipped: Color,

    // Worktree status
    pub worktree_active: Color,
    pub worktree_merged: Color,
    pub worktree_abandoned: Color,
    pub worktree_conflict: Color,
    pub worktree_removed: Color,
    pub worktree_orphaned: Color,

    // Feedback scores
    pub score_positive: Color,
    pub score_negative: Color,
    pub score_neutral: Color,

    // Dashboard metrics
    pub metric_value: Color,
    pub trend_positive: Color,
    pub trend_negative: Color,

    // Bar charts
    pub bar_default: Color,
    pub bar_success: Color,
    pub bar_warning: Color,
    pub bar_error: Color,
    pub bar_info: Color,

    // Heatmap
    pub heatmap_empty: Color,
    pub heatmap_low: Color,
    pub heatmap_medium: Color,
    pub heatmap_high: Color,
    pub heatmap_max: Color,

    // Contextual hints
    pub hint_key: Color,
    pub hint_key_primary: Color,
    pub hint_description: Color,
}

impl Palette {
    pub fn from_colors(colors: ColorPalette, is_dark: bool) -> Self { todo!() }

    fn dark_from_colors(colors: ColorPalette) -> Self { todo!() }

    fn light_from_colors(colors: ColorPalette) -> Self { todo!() }
}
