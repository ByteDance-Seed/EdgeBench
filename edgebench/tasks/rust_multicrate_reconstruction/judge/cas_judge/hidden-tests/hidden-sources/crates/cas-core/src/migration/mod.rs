    #[test]
    fn test_migrations_table_creation() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("cas.db");
        let conn = Connection::open(&db_path).unwrap();

        ensure_migrations_table(&conn).unwrap();

        // Verify table exists
        let count: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='cas_migrations'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(count, 1);
    }
