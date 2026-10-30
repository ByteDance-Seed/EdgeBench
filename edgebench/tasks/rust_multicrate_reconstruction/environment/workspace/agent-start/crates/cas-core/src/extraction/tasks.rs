//! Task knowledge extraction
//!
//! Extracts learnings from task close_reason and structured task notes.
//! This captures valuable knowledge that would otherwise be buried in closed tasks.

use cas_types::{Entry, EntryType, Task};

/// Result of extracting knowledge from a task
#[derive(Debug, Clone, Default)]
pub struct TaskExtractionResult {
    /// Learnings extracted from close_reason
    pub learnings: Vec<ExtractedLearning>,
    /// Discoveries from task notes
    pub discoveries: Vec<ExtractedLearning>,
    /// Decisions from task notes
    pub decisions: Vec<ExtractedDecision>,
    /// Suggested rules from patterns
    pub suggested_rules: Vec<SuggestedRule>,
}

/// A learning extracted from a task
#[derive(Debug, Clone)]
pub struct ExtractedLearning {
    pub content: String,
    pub importance: f32,
    pub tags: Vec<String>,
    pub source_task_id: String,
}

/// A decision extracted from task notes
#[derive(Debug, Clone)]
pub struct ExtractedDecision {
    pub decision: String,
    pub rationale: Option<String>,
    pub alternatives_rejected: Vec<String>,
    pub source_task_id: String,
}

/// A suggested rule from task patterns
#[derive(Debug, Clone)]
pub struct SuggestedRule {
    pub content: String,
    pub paths: Option<String>,
    pub confidence: f32,
    pub source_task_id: String,
}

/// Extract knowledge from task close_reason and notes
pub fn extract_from_task(task: &Task) -> TaskExtractionResult { todo!() }

/// Extract learnings from a task's close_reason
/// Parses numbered lists and converts each to a standalone learning
fn extract_from_close_reason(reason: &str, task_id: &str) -> Vec<ExtractedLearning> { todo!() }

/// Parse a single learning item from numbered/bulleted text
fn parse_learning_item(item: &str, task_id: &str) -> Option<ExtractedLearning> { todo!() }

/// Extract discoveries and decisions from structured task notes
fn extract_from_notes(
    notes: &str,
    task_id: &str,
) -> (Vec<ExtractedLearning>, Vec<ExtractedDecision>) { todo!() }

/// Convert extracted learnings to Entry objects ready for storage
pub fn learnings_to_entries(learnings: &[ExtractedLearning]) -> Vec<Entry> { todo!() }

/// Build AI prompt for enhanced task knowledge extraction
pub fn build_task_extraction_prompt(task: &Task) -> String { todo!() }

#[cfg(test)]
mod tests {
    use crate::extraction::tasks::*;
    use cas_types::{Priority, TaskStatus, TaskType};


    #[test]
    fn test_extract_from_close_reason_bullets() {
        let reason = r#"Fixed authentication:
- Updated JWT validation to check expiry
- Added refresh token rotation"#;

        let learnings = extract_from_close_reason(reason, "cas-5678");
        assert_eq!(learnings.len(), 2);
    }


    #[test]
    fn test_skip_trivial_items() {
        let reason = "1. OK\n2. Done\n3. This is a meaningful learning about the architecture";

        let learnings = extract_from_close_reason(reason, "cas-test");
        // Should only keep the meaningful one
        assert_eq!(learnings.len(), 1);
        assert!(learnings[0].content.contains("architecture"));
    }

    #[test]
    fn test_importance_detection() {
        let reason = "1. Always use hydrateRoot for SSR - critical for hydration\n2. Updated styles for dark mode support";

        let learnings = extract_from_close_reason(reason, "cas-test");
        assert_eq!(learnings.len(), 2);
        // First item should have high importance due to "Always" and "critical"
        assert!(learnings[0].importance >= 0.9);
        // Second item should have lower importance
        assert!(learnings[1].importance < 0.9);
    }

    #[test]
    fn test_learnings_to_entries() {
        let learnings = vec![ExtractedLearning {
            content: "Test learning".to_string(),
            importance: 0.8,
            tags: vec!["rust".to_string()],
            source_task_id: "cas-1234".to_string(),
        }];

        let entries = learnings_to_entries(&learnings);
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].content, "Test learning");
        assert_eq!(entries[0].entry_type, EntryType::Learning);
        assert_eq!(entries[0].importance, 0.8);
    }


    #[test]
    fn test_extract_from_task() {
        let task = Task {
            id: "cas-5678".to_string(),
            title: "Test task".to_string(),
            task_type: TaskType::Task,
            status: TaskStatus::Closed,
            priority: Priority::MEDIUM,
            close_reason: Some("1. Fixed the critical bug in component".to_string()),
            notes: "DISCOVERY: Found a new pattern for handling this".to_string(),
            ..Default::default()
        };

        let result = extract_from_task(&task);
        assert!(!result.learnings.is_empty());
        assert!(!result.discoveries.is_empty());
    }
}
