//! Pre-composed styles for common UI patterns

use ratatui::style::{Modifier, Style};

use crate::ui::theme::palette::Palette;

/// Pre-composed styles for consistent UI rendering
#[derive(Debug, Clone)]
pub struct Styles {
    // Text hierarchy
    pub text_primary: Style,
    pub text_secondary: Style,
    pub text_muted: Style,
    pub text_disabled: Style,
    pub text_accent: Style,
    pub text_bold: Style,
    pub text_label: Style,

    // Status text
    pub text_success: Style,
    pub text_warning: Style,
    pub text_error: Style,
    pub text_info: Style,

    // Backgrounds
    pub bg_primary: Style,
    pub bg_secondary: Style,
    pub bg_elevated: Style,
    pub bg_selection: Style,

    // Borders
    pub border_default: Style,
    pub border_focused: Style,
    pub border_muted: Style,

    // List items
    pub list_item: Style,
    pub list_item_selected: Style,

    // Entity IDs
    pub entity_id: Style,
    pub entity_type: Style,

    // Headers
    pub header_title: Style,
    pub header_subtitle: Style,
    pub section_title: Style,

    // Tabs
    pub tab_inactive: Style,
    pub tab_active: Style,

    // Status bar
    pub status_bar: Style,
    pub status_bar_key: Style,

    // Input
    pub input_normal: Style,
    pub input_focused: Style,
    pub input_placeholder: Style,

    // Scores/feedback
    pub score_positive: Style,
    pub score_negative: Style,
    pub score_neutral: Style,

    // Task status
    pub task_open: Style,
    pub task_in_progress: Style,
    pub task_blocked: Style,
    pub task_closed: Style,

    // Priority
    pub priority_critical: Style,
    pub priority_high: Style,
    pub priority_medium: Style,
    pub priority_low: Style,
    pub priority_backlog: Style,

    // Agent status
    pub agent_active: Style,
    pub agent_idle: Style,
    pub agent_dead: Style,

    // Skill status
    pub skill_enabled: Style,
    pub skill_disabled: Style,
    pub skill_draft: Style,

    // Rule status
    pub rule_draft: Style,
    pub rule_proven: Style,
    pub rule_stale: Style,
    pub rule_retired: Style,

    // Verification
    pub verification_approved: Style,
    pub verification_rejected: Style,
    pub verification_error: Style,
    pub verification_skipped: Style,

    // Worktree
    pub worktree_active: Style,
    pub worktree_merged: Style,
    pub worktree_abandoned: Style,
    pub worktree_conflict: Style,
    pub worktree_removed: Style,
    pub worktree_orphaned: Style,

    // Dashboard metrics
    pub metric_value: Style,
    pub trend_positive: Style,
    pub trend_negative: Style,

    // Bar charts
    pub bar_default: Style,
    pub bar_success: Style,
    pub bar_warning: Style,
    pub bar_error: Style,
    pub bar_info: Style,

    // Heatmap
    pub heatmap_empty: Style,
    pub heatmap_low: Style,
    pub heatmap_medium: Style,
    pub heatmap_high: Style,
    pub heatmap_max: Style,

    // Contextual hints
    pub hint_key: Style,
    pub hint_key_primary: Style,
    pub hint_description: Style,

    // Markdown rendering
    pub md_h1: Style,
    pub md_h2: Style,
    pub md_h3: Style,
    pub md_code_inline: Style,
    pub md_code_block: Style,
    pub md_blockquote: Style,
    pub md_link: Style,
}

impl Styles {
    pub fn from_palette(p: &Palette) -> Self { todo!() }
}
