//! Individual migration definitions
//!
//! Each migration is in its own file for easier management and git history.
//! Files are named: m{ID:03}_{name}.rs

use crate::migration::Migration;

// Entries subsystem (1-50)
mod m001_entries_add_session_id;
mod m002_entries_add_source_tool;
mod m003_entries_add_pending_extraction;
mod m004_entries_add_observation_type;
mod m005_entries_add_stability;
mod m006_entries_add_access_count;
mod m007_entries_add_raw_content;
mod m008_entries_add_compressed;
mod m009_entries_add_memory_tier;
mod m010_entries_add_importance;
mod m011_entries_add_valid_from;
mod m012_entries_add_valid_until;
mod m013_entries_add_review_after;
mod m014_entries_add_pending_embedding;
mod m015_entries_add_belief_type;
mod m016_entries_add_confidence;
mod m017_entries_add_domain;
mod m018_entries_idx_session;
mod m019_entries_idx_pending;
mod m020_entries_idx_obs_type;
mod m021_entries_idx_stability;
mod m022_entries_idx_memory_tier;
mod m023_entries_idx_importance;
mod m024_entries_idx_pending_embedding;
mod m025_entries_idx_belief_type;
mod m026_entries_idx_confidence;
mod m027_entries_idx_domain;
mod m028_sessions_add_title;
mod m029_entries_add_branch;
mod m030_entries_idx_branch;
mod m031_sessions_add_branch;
mod m032_sessions_add_worktree_id;
mod m033_entries_add_scope;
mod m034_entries_add_team_id;
mod m038_entries_add_last_reviewed;
mod m039_entries_add_updated_at;
mod m040_entries_add_indexed_at;
mod m041_entries_idx_pending_index;
mod m042_sessions_add_outcome;
mod m043_sessions_add_friction_score;
mod m044_sessions_add_delight_count;

// Rules subsystem (51-70)
mod m051_rules_add_hook_command;
mod m052_rules_add_category;
mod m053_rules_add_priority;
mod m054_rules_add_surface_count;
mod m055_rules_idx_category;
mod m056_rules_idx_priority;
mod m057_rules_add_scope;
mod m058_rules_add_auto_approve_tools;
mod m059_rules_add_auto_approve_paths;
mod m060_rules_add_team_id;

// Skills subsystem (71-90)
mod m071_skills_add_summary;
mod m072_skills_add_preconditions;
mod m073_skills_add_postconditions;
mod m074_skills_add_validation_script;
mod m075_skills_add_invokable;
mod m076_skills_add_argument_hint;
mod m077_skills_add_context_mode;
mod m078_skills_add_agent_type;
mod m079_skills_add_allowed_tools;
mod m080_skills_add_hooks;
mod m081_skills_add_team_id;
mod m085_skills_add_disable_model_invocation;

// Agents subsystem (91-110)
mod m091_task_leases_add_epoch;
mod m092_agents_add_worktree_id;
mod m093_agents_add_branch;
mod m094_task_leases_add_task_fk;
mod m095_working_epics_create_table;
mod m096_agents_add_ppid;
mod m097_agents_add_cc_session_id;
mod m098_agents_idx_ppid;

// Worktrees subsystem (111-130)
mod m111_worktrees_create_table;
mod m112_worktrees_idx_task;
mod m113_worktrees_idx_branch;
mod m114_worktrees_idx_status;
mod m115_worktrees_idx_path;
mod m116_tasks_add_branch;
mod m117_tasks_add_worktree_id;
mod m118_tasks_idx_branch;
mod m119_tasks_idx_worktree;
mod m120_worktrees_add_epic_id;
mod m121_worktrees_idx_epic;
mod m122_tasks_add_pending_verification;
mod m123_tasks_add_pending_worktree_merge;
mod m124_tasks_add_team_id;
mod m129_worktree_leases_create_table;
mod m130_worktrees_add_jj_fields;

// Code subsystem (131-150)
mod m131_code_files_create_table;
mod m132_code_symbols_create_table;
mod m133_code_relationships_create_table;
mod m134_code_memory_links_create_table;
mod m135_code_files_idx_path;
mod m136_code_files_idx_language;
mod m137_code_symbols_idx_name;
mod m138_code_symbols_idx_file;
mod m139_code_symbols_idx_kind;
mod m140_code_relationships_idx_source;
mod m141_prompts_create_table;
mod m142_file_changes_create_table;
mod m143_commit_links_create_table;

// Blame v2 migrations (154-164)
mod m154_prompts_add_messages_json;
mod m155_prompts_add_model;
mod m156_prompts_add_tool_version;
mod m157_file_changes_add_line_attributions;
mod m158_file_changes_add_human_modified_lines;
mod m159_line_attributions_create_table;
mod m160_line_attributions_idx_prompt;
mod m161_line_attributions_idx_file;
mod m162_line_attributions_idx_content_hash;
mod m163_file_snapshots_create_table;
mod m164_file_snapshots_idx_session;

// Events subsystem (151-170)
mod m151_events_create_table;
mod m152_agents_add_role;
mod m153_supervisor_queue_create_table;

// Verification subsystem (165+)
mod m165_verifications_add_verification_type;

// Epic verification owner (166)
mod m166_tasks_add_epic_verification_owner;

// Recording text search (167)
mod m167_recording_text_fts5;

// Recordings subsystem (171-190)
mod m171_recordings_create_table;
mod m172_recording_agents_create_table;
mod m173_recording_events_create_table;
mod m174_recordings_fts_create;
mod m175_recordings_idx_session;
mod m176_recordings_idx_started;
mod m177_recording_agents_idx_name;
mod m178_recording_agents_idx_recording;
mod m179_recording_events_idx_recording;
mod m180_recording_events_idx_timestamp;
mod m181_tasks_add_deliverables;
mod m182_tasks_add_demo_statement;

/// All migrations in order. IDs must be sequential and never reused.
pub const MIGRATIONS: &[Migration] = &[
    // Entries
    m001_entries_add_session_id::MIGRATION,
    m002_entries_add_source_tool::MIGRATION,
    m003_entries_add_pending_extraction::MIGRATION,
    m004_entries_add_observation_type::MIGRATION,
    m005_entries_add_stability::MIGRATION,
    m006_entries_add_access_count::MIGRATION,
    m007_entries_add_raw_content::MIGRATION,
    m008_entries_add_compressed::MIGRATION,
    m009_entries_add_memory_tier::MIGRATION,
    m010_entries_add_importance::MIGRATION,
    m011_entries_add_valid_from::MIGRATION,
    m012_entries_add_valid_until::MIGRATION,
    m013_entries_add_review_after::MIGRATION,
    m014_entries_add_pending_embedding::MIGRATION,
    m015_entries_add_belief_type::MIGRATION,
    m016_entries_add_confidence::MIGRATION,
    m017_entries_add_domain::MIGRATION,
    m018_entries_idx_session::MIGRATION,
    m019_entries_idx_pending::MIGRATION,
    m020_entries_idx_obs_type::MIGRATION,
    m021_entries_idx_stability::MIGRATION,
    m022_entries_idx_memory_tier::MIGRATION,
    m023_entries_idx_importance::MIGRATION,
    m024_entries_idx_pending_embedding::MIGRATION,
    m025_entries_idx_belief_type::MIGRATION,
    m026_entries_idx_confidence::MIGRATION,
    m027_entries_idx_domain::MIGRATION,
    m028_sessions_add_title::MIGRATION,
    m029_entries_add_branch::MIGRATION,
    m030_entries_idx_branch::MIGRATION,
    m031_sessions_add_branch::MIGRATION,
    m032_sessions_add_worktree_id::MIGRATION,
    m033_entries_add_scope::MIGRATION,
    m034_entries_add_team_id::MIGRATION,
    m038_entries_add_last_reviewed::MIGRATION,
    m039_entries_add_updated_at::MIGRATION,
    m040_entries_add_indexed_at::MIGRATION,
    m041_entries_idx_pending_index::MIGRATION,
    m042_sessions_add_outcome::MIGRATION,
    m043_sessions_add_friction_score::MIGRATION,
    m044_sessions_add_delight_count::MIGRATION,
    // Rules
    m051_rules_add_hook_command::MIGRATION,
    m052_rules_add_category::MIGRATION,
    m053_rules_add_priority::MIGRATION,
    m054_rules_add_surface_count::MIGRATION,
    m055_rules_idx_category::MIGRATION,
    m056_rules_idx_priority::MIGRATION,
    m057_rules_add_scope::MIGRATION,
    m058_rules_add_auto_approve_tools::MIGRATION,
    m059_rules_add_auto_approve_paths::MIGRATION,
    m060_rules_add_team_id::MIGRATION,
    // Skills
    m071_skills_add_summary::MIGRATION,
    m072_skills_add_preconditions::MIGRATION,
    m073_skills_add_postconditions::MIGRATION,
    m074_skills_add_validation_script::MIGRATION,
    m075_skills_add_invokable::MIGRATION,
    m076_skills_add_argument_hint::MIGRATION,
    m077_skills_add_context_mode::MIGRATION,
    m078_skills_add_agent_type::MIGRATION,
    m079_skills_add_allowed_tools::MIGRATION,
    m080_skills_add_hooks::MIGRATION,
    m081_skills_add_team_id::MIGRATION,
    m085_skills_add_disable_model_invocation::MIGRATION,
    // Agents
    m091_task_leases_add_epoch::MIGRATION,
    m092_agents_add_worktree_id::MIGRATION,
    m093_agents_add_branch::MIGRATION,
    m094_task_leases_add_task_fk::MIGRATION,
    m095_working_epics_create_table::MIGRATION,
    m096_agents_add_ppid::MIGRATION,
    m097_agents_add_cc_session_id::MIGRATION,
    m098_agents_idx_ppid::MIGRATION,
    // Worktrees
    m111_worktrees_create_table::MIGRATION,
    m112_worktrees_idx_task::MIGRATION,
    m113_worktrees_idx_branch::MIGRATION,
    m114_worktrees_idx_status::MIGRATION,
    m115_worktrees_idx_path::MIGRATION,
    m116_tasks_add_branch::MIGRATION,
    m117_tasks_add_worktree_id::MIGRATION,
    m118_tasks_idx_branch::MIGRATION,
    m119_tasks_idx_worktree::MIGRATION,
    m120_worktrees_add_epic_id::MIGRATION,
    m121_worktrees_idx_epic::MIGRATION,
    m122_tasks_add_pending_verification::MIGRATION,
    m123_tasks_add_pending_worktree_merge::MIGRATION,
    m124_tasks_add_team_id::MIGRATION,
    m129_worktree_leases_create_table::MIGRATION,
    m130_worktrees_add_jj_fields::MIGRATION,
    // Code
    m131_code_files_create_table::MIGRATION,
    m132_code_symbols_create_table::MIGRATION,
    m133_code_relationships_create_table::MIGRATION,
    m134_code_memory_links_create_table::MIGRATION,
    m135_code_files_idx_path::MIGRATION,
    m136_code_files_idx_language::MIGRATION,
    m137_code_symbols_idx_name::MIGRATION,
    m138_code_symbols_idx_file::MIGRATION,
    m139_code_symbols_idx_kind::MIGRATION,
    m140_code_relationships_idx_source::MIGRATION,
    m141_prompts_create_table::MIGRATION,
    m142_file_changes_create_table::MIGRATION,
    m143_commit_links_create_table::MIGRATION,
    // Events
    m151_events_create_table::MIGRATION,
    // Agent roles (factory sessions)
    m152_agents_add_role::MIGRATION,
    m153_supervisor_queue_create_table::MIGRATION,
    // Blame v2
    m154_prompts_add_messages_json::MIGRATION,
    m155_prompts_add_model::MIGRATION,
    m156_prompts_add_tool_version::MIGRATION,
    m157_file_changes_add_line_attributions::MIGRATION,
    m158_file_changes_add_human_modified_lines::MIGRATION,
    m159_line_attributions_create_table::MIGRATION,
    m160_line_attributions_idx_prompt::MIGRATION,
    m161_line_attributions_idx_file::MIGRATION,
    m162_line_attributions_idx_content_hash::MIGRATION,
    m163_file_snapshots_create_table::MIGRATION,
    m164_file_snapshots_idx_session::MIGRATION,
    // Verification
    m165_verifications_add_verification_type::MIGRATION,
    // Epic verification owner
    m166_tasks_add_epic_verification_owner::MIGRATION,
    // Recording text search
    m167_recording_text_fts5::MIGRATION,
    // Recordings
    m171_recordings_create_table::MIGRATION,
    m172_recording_agents_create_table::MIGRATION,
    m173_recording_events_create_table::MIGRATION,
    m174_recordings_fts_create::MIGRATION,
    m175_recordings_idx_session::MIGRATION,
    m176_recordings_idx_started::MIGRATION,
    m177_recording_agents_idx_name::MIGRATION,
    m178_recording_agents_idx_recording::MIGRATION,
    m179_recording_events_idx_recording::MIGRATION,
    m180_recording_events_idx_timestamp::MIGRATION,
    m181_tasks_add_deliverables::MIGRATION,
    m182_tasks_add_demo_statement::MIGRATION,
];

#[cfg(test)]
mod tests {
    use crate::migration::migrations::*;
    use std::collections::HashSet;

    #[test]
    fn test_migration_ids_unique() {
        let mut seen = HashSet::new();
        for m in MIGRATIONS {
            assert!(
                seen.insert(m.id),
                "Duplicate migration ID: {} ({})",
                m.id,
                m.name
            );
        }
    }

    #[test]
    fn test_migration_names_unique() {
        let mut seen = HashSet::new();
        for m in MIGRATIONS {
            assert!(seen.insert(m.name), "Duplicate migration name: {}", m.name);
        }
    }

    #[test]
    fn test_all_migrations_have_detection() {
        for m in MIGRATIONS {
            assert!(
                m.detect.is_some(),
                "Migration {} ({}) missing detection query",
                m.id,
                m.name
            );
        }
    }

    #[test]
    fn test_migrations_ordered() {
        let mut last_id = 0;
        for m in MIGRATIONS {
            assert!(
                m.id > last_id,
                "Migration {} ({}) not in order (after {})",
                m.id,
                m.name,
                last_id
            );
            last_id = m.id;
        }
    }
}
