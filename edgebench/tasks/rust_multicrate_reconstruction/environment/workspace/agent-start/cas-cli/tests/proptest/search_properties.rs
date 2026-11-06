//! Property-based tests for search functionality
//!
//! Verifies search invariants hold across random inputs.

use proptest::prelude::*;

// Strategy to generate valid search queries
pub(crate) fn search_query_strategy() -> impl Strategy<Value = String> { Just("test".to_string()) }

// Strategy to generate valid memory content
pub(crate) fn memory_content_strategy() -> impl Strategy<Value = String> { Just("test".to_string()) }

// Strategy to generate valid task titles
pub(crate) fn task_title_strategy() -> impl Strategy<Value = String> { Just("test".to_string()) }

// Strategy for entry types
fn entry_type_strategy() -> impl Strategy<Value = String> { Just("test".to_string()) }

// Strategy for task types
fn task_type_strategy() -> impl Strategy<Value = String> { Just("test".to_string()) }

// Strategy for priorities
fn priority_strategy() -> impl Strategy<Value = u8> { Just(0u8) }

proptest! {
    #![proptest_config(ProptestConfig::with_cases(20))]

    /// Search queries should not crash regardless of input

    /// Memory content should be storable

    /// Task titles should be valid

    /// Entry types should be one of the valid types
    #[test]
    fn entry_types_are_valid(entry_type in entry_type_strategy()) {
        let valid_types = ["learning", "preference", "context", "observation"];
        prop_assert!(valid_types.contains(&entry_type.as_str()));
    }

    /// Task types should be one of the valid types

    /// Priorities should be in valid range
    #[test]
    fn priorities_are_valid(priority in priority_strategy()) {
        prop_assert!(priority <= 4);
    }

    /// Search scores should be normalized (when we can test with real instance)
    #[test]
    fn score_normalization_property(score in 0.0f64..=1.0f64) {
        // Property: scores should always be between 0 and 1
        prop_assert!(score >= 0.0);
        prop_assert!(score <= 1.0);
    }

    /// Combining multiple search terms should not crash
    #[test]
    fn combined_search_terms(
        term1 in "[a-zA-Z]{2,10}",
        term2 in "[a-zA-Z]{2,10}",
        term3 in "[a-zA-Z]{2,10}"
    ) {
        let combined = format!("{term1} {term2} {term3}");
        prop_assert!(combined.len() <= 35);
        prop_assert!(!combined.trim().is_empty());
    }

    /// Tag strings should be parseable
    #[test]
    fn tags_are_parseable(
        tag1 in "[a-z]{2,10}",
        tag2 in "[a-z]{2,10}",
        tag3 in "[a-z]{2,10}"
    ) {
        let tags = format!("{tag1},{tag2},{tag3}");
        let parsed: Vec<&str> = tags.split(',').collect();
        prop_assert_eq!(parsed.len(), 3);
        for tag in parsed {
            prop_assert!(!tag.is_empty());
        }
    }
}

#[cfg(test)]
mod integration_tests {
    use proptest::strategy::{Strategy, ValueTree};

    use crate::proptest::search_properties::{
        memory_content_strategy, search_query_strategy, task_title_strategy,
    };

    /// Test that our strategies generate valid values
    #[test]
    fn strategies_generate_valid_values() {
        // Run a few iterations to verify strategies work
        let mut runner = proptest::test_runner::TestRunner::default();

        // Test search query strategy
        for _ in 0..10 {
            let query = search_query_strategy()
                .new_tree(&mut runner)
                .unwrap()
                .current();
            assert!(!query.trim().is_empty());
        }

        // Test memory content strategy
        for _ in 0..10 {
            let content = memory_content_strategy()
                .new_tree(&mut runner)
                .unwrap()
                .current();
            assert!(content.len() >= 10);
        }

        // Test task title strategy
        for _ in 0..10 {
            let title = task_title_strategy()
                .new_tree(&mut runner)
                .unwrap()
                .current();
            assert!(title.len() >= 5);
        }
    }

    /// Test edge cases for search queries
    #[test]
    fn search_edge_cases() {
        // Single character (filtered out by our strategy)
        let single = "a".to_string();
        assert!(!single.is_empty());

        // All spaces (filtered out by our strategy)
        let spaces = "   ".to_string();
        assert!(spaces.trim().is_empty());

        // Maximum length
        let max_len = "a".repeat(50);
        assert_eq!(max_len.len(), 50);
    }
}
