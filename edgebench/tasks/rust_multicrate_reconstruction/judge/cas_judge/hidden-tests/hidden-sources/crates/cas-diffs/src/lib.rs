    #[test]
    fn change_type_variants() {
        let variants = [
            ChangeType::Change,
            ChangeType::RenamePure,
            ChangeType::RenameChanged,
            ChangeType::New,
            ChangeType::Deleted,
        ];
        for v in &variants {
            // Round-trip through serde
            let json = serde_json::to_string(v).unwrap();
            let back: ChangeType = serde_json::from_str(&json).unwrap();
            assert_eq!(*v, back);
        }
    }

    #[test]
    fn hunk_line_type_serde() {
        assert_eq!(
            serde_json::to_string(&HunkLineType::Context).unwrap(),
            "\"context\""
        );
        assert_eq!(
            serde_json::to_string(&HunkLineType::Addition).unwrap(),
            "\"addition\""
        );
    }

    #[test]
    fn parsed_patch_construction() {
        let patch = ParsedPatch {
            patch_metadata: Some("commit abc123\nAuthor: Test".into()),
            files: vec![FileDiffMetadata {
                name: "README.md".into(),
                prev_name: None,
                change_type: ChangeType::Change,
                hunks: vec![],
                split_line_count: 5,
                unified_line_count: 5,
                is_partial: true,
                deletion_lines: vec![],
                addition_lines: vec![],
            }],
        };
        assert!(patch.patch_metadata.is_some());
        assert_eq!(patch.files.len(), 1);
        assert_eq!(patch.files[0].name, "README.md");
    }
