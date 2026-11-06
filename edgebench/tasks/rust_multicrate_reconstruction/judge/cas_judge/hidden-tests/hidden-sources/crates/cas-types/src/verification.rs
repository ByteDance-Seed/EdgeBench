    #[test]
    fn test_verification_status_from_str() {
        assert_eq!(
            VerificationStatus::from_str("approved").unwrap(),
            VerificationStatus::Approved
        );
        assert_eq!(
            VerificationStatus::from_str("rejected").unwrap(),
            VerificationStatus::Rejected
        );
        assert_eq!(
            VerificationStatus::from_str("error").unwrap(),
            VerificationStatus::Error
        );
        assert_eq!(
            VerificationStatus::from_str("skipped").unwrap(),
            VerificationStatus::Skipped
        );
        assert!(VerificationStatus::from_str("invalid").is_err());
    }

    #[test]
    fn test_verification_new() {
        let v = Verification::new("ver-a1b2".to_string(), "cas-1234".to_string());
        assert_eq!(v.id, "ver-a1b2");
        assert_eq!(v.task_id, "cas-1234");
        assert!(v.is_approved());
        assert_eq!(v.blocking_count(), 0);
    }

    #[test]
    fn test_verification_rejected() {
        let issues = vec![
            VerificationIssue::blocking(
                "src/main.rs".to_string(),
                Some(42),
                "todo_comment".to_string(),
                "// TODO: implement".to_string(),
                "TODO comment found".to_string(),
                Some("Implement the function".to_string()),
            ),
            VerificationIssue::warning(
                "src/lib.rs".to_string(),
                "hardcoded_value".to_string(),
                "Magic number detected".to_string(),
            ),
        ];

        let v = Verification::rejected(
            "ver-a1b2".to_string(),
            "cas-1234".to_string(),
            "Found incomplete work".to_string(),
            issues,
        );

        assert!(v.is_rejected());
        assert_eq!(v.blocking_count(), 1);
        assert_eq!(v.warning_count(), 1);
    }

    #[test]
    fn test_issue_severity() {
        assert_eq!(
            IssueSeverity::from_str("blocking").unwrap(),
            IssueSeverity::Blocking
        );
        assert_eq!(
            IssueSeverity::from_str("warning").unwrap(),
            IssueSeverity::Warning
        );
    }
