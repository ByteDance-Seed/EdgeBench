    #[test]
    fn test_sort_order_from_str() {
        assert_eq!("asc".parse::<SortOrder>().unwrap(), SortOrder::Asc);
        assert_eq!("DESC".parse::<SortOrder>().unwrap(), SortOrder::Desc);
        assert_eq!("ascending".parse::<SortOrder>().unwrap(), SortOrder::Asc);
        assert!("invalid".parse::<SortOrder>().is_err());
    }

    #[test]
    fn test_entry_sort_field_from_str() {
        assert_eq!(
            "created".parse::<EntrySortField>().unwrap(),
            EntrySortField::Created
        );
        assert_eq!(
            "importance".parse::<EntrySortField>().unwrap(),
            EntrySortField::Importance
        );
        assert_eq!(
            "title".parse::<EntrySortField>().unwrap(),
            EntrySortField::Title
        );
    }

    #[test]
    fn test_task_sort_field_default_order() {
        assert_eq!(TaskSortField::Priority.default_order(), SortOrder::Asc);
        assert_eq!(TaskSortField::Created.default_order(), SortOrder::Desc);
    }
