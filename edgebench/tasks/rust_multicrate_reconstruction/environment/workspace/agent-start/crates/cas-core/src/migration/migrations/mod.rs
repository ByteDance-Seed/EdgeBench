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
mod m034_entries_add_updated_at;
mod m035_entries_add_indexed_at;
mod m036_entries_idx_pending_index;

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
mod m081_skills_add_disable_model_invocation;

// Agents subsystem (91-110)
mod m091_task_leases_add_epoch;
mod m092_agents_add_worktree_id;
mod m093_agents_add_branch;

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
mod m120_tasks_add_deliverables;

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
    m034_entries_add_updated_at::MIGRATION,
    m035_entries_add_indexed_at::MIGRATION,
    m036_entries_idx_pending_index::MIGRATION,
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
    m081_skills_add_disable_model_invocation::MIGRATION,
    // Agents
    m091_task_leases_add_epoch::MIGRATION,
    m092_agents_add_worktree_id::MIGRATION,
    m093_agents_add_branch::MIGRATION,
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
    m120_tasks_add_deliverables::MIGRATION,
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
