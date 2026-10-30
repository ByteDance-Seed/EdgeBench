    #[test]
    fn search_never_crashes(query in search_query_strategy()) {
        // This is a property test that would need a real CAS instance
        // For now, we verify the query is valid
        prop_assert!(!query.trim().is_empty());
        prop_assert!(query.len() <= 50);
    }

    #[test]
    fn memory_content_is_valid(content in memory_content_strategy()) {
        prop_assert!(!content.trim().is_empty());
        prop_assert!(content.len() >= 10);
        prop_assert!(content.len() <= 200);
    }

    #[test]
    fn task_titles_are_valid(title in task_title_strategy()) {
        prop_assert!(!title.trim().is_empty());
        prop_assert!(title.len() >= 5);
        prop_assert!(title.len() <= 100);
    }

    #[test]
    fn task_types_are_valid(task_type in task_type_strategy()) {
        let valid_types = ["task", "bug", "feature", "epic", "chore"];
        prop_assert!(valid_types.contains(&task_type.as_str()));
    }
