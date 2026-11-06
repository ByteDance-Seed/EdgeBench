    #[test]
    fn shared_connection_returns_same_instance() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");

        let conn1 = shared_connection(&db_path).unwrap();
        let conn2 = shared_connection(&db_path).unwrap();

        assert!(Arc::ptr_eq(&conn1, &conn2));
    }

    #[test]
    fn shared_connection_recreates_after_drop() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");

        let conn1 = shared_connection(&db_path).unwrap();
        let ptr1 = Arc::as_ptr(&conn1);
        drop(conn1);

        let conn2 = shared_connection(&db_path).unwrap();
        let ptr2 = Arc::as_ptr(&conn2);
        assert_ne!(ptr1, ptr2);
    }

    #[test]
    fn shared_connection_keeps_alive_while_any_arc_exists() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");

        let conn1 = shared_connection(&db_path).unwrap();
        let conn2 = shared_connection(&db_path).unwrap();
        let ptr = Arc::as_ptr(&conn1);

        // Drop one clone — the other keeps the connection alive
        drop(conn1);
        let conn3 = shared_connection(&db_path).unwrap();
        assert_eq!(ptr, Arc::as_ptr(&conn3));

        // Drop all — next call creates a new connection
        drop(conn2);
        drop(conn3);
        let conn4 = shared_connection(&db_path).unwrap();
        assert_ne!(ptr, Arc::as_ptr(&conn4));
    }

    #[test]
    fn shared_connection_pragmas_are_set() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");

        let conn = shared_connection(&db_path).unwrap();
        let guard = conn.lock().unwrap();

        let journal: String = guard
            .query_row("PRAGMA journal_mode", [], |r| r.get(0))
            .unwrap();
        assert_eq!(journal, "wal");

        let fk: i64 = guard
            .query_row("PRAGMA foreign_keys", [], |r| r.get(0))
            .unwrap();
        assert_eq!(fk, 1);

        let sync: i64 = guard
            .query_row("PRAGMA synchronous", [], |r| r.get(0))
            .unwrap();
        // NORMAL = 1
        assert_eq!(sync, 1);
    }

    #[test]
    fn shared_connection_data_persists_across_callers() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");

        // First caller creates a table and inserts data
        {
            let conn = shared_connection(&db_path).unwrap();
            let guard = conn.lock().unwrap();
            guard
                .execute_batch("CREATE TABLE persist_test (val TEXT)")
                .unwrap();
            guard
                .execute("INSERT INTO persist_test VALUES ('hello')", [])
                .unwrap();
        }

        // Second caller (same connection) can read it
        {
            let conn = shared_connection(&db_path).unwrap();
            let guard = conn.lock().unwrap();
            let val: String = guard
                .query_row("SELECT val FROM persist_test", [], |r| r.get(0))
                .unwrap();
            assert_eq!(val, "hello");
        }
    }

    #[test]
    fn pool_recovers_from_poisoned_mutex() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("poison.db");

        // Poison the POOL mutex by panicking while holding it
        let _ = panic::catch_unwind(|| {
            let mut guard = POOL.lock().unwrap();
            let _map = guard.get_or_insert_with(HashMap::new);
            panic!("intentional poison");
        });

        // shared_connection should still work via unwrap_or_else(into_inner)
        let conn = shared_connection(&db_path).unwrap();
        let guard = conn.lock().unwrap();
        guard.execute_batch("SELECT 1").unwrap();
    }

    #[test]
    fn concurrent_readers_dont_block() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("readers.db");

        let conn = shared_connection(&db_path).unwrap();
        {
            let guard = conn.lock().unwrap();
            guard
                .execute_batch("CREATE TABLE data (id INTEGER, val TEXT)")
                .unwrap();
            for i in 0..100 {
                guard
                    .execute(
                        "INSERT INTO data VALUES (?1, ?2)",
                        rusqlite::params![i, format!("value_{i}")],
                    )
                    .unwrap();
            }
        }

        // Open a second (separate) connection for reads — WAL allows concurrent reads
        let read_conn = Connection::open(&db_path).unwrap();
        read_conn.execute_batch("PRAGMA journal_mode=WAL").unwrap();

        let num_readers = 10;
        let barrier = Arc::new(Barrier::new(num_readers));
        let path = db_path.clone();

        let handles: Vec<_> = (0..num_readers)
            .map(|_| {
                let b = barrier.clone();
                let p = path.clone();
                std::thread::spawn(move || {
                    b.wait();
                    // Each reader opens its own connection (simulating separate processes)
                    let rc = Connection::open(&p).unwrap();
                    rc.execute_batch("PRAGMA journal_mode=WAL").unwrap();
                    let count: i64 = rc
                        .query_row("SELECT COUNT(*) FROM data", [], |r| r.get(0))
                        .unwrap();
                    assert_eq!(count, 100);
                })
            })
            .collect();

        for h in handles {
            h.join().unwrap();
        }
    }

    #[test]
    fn immediate_tx_multi_statement() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("multi.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch(
            "CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT);\
             CREATE TABLE log (msg TEXT);",
        )
        .unwrap();

        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO items VALUES (1, 'alpha')", [])
                .unwrap();
            tx.execute("INSERT INTO items VALUES (2, 'beta')", [])
                .unwrap();
            tx.execute("INSERT INTO log VALUES ('inserted 2 items')", [])
                .unwrap();
            tx.commit().unwrap();
        }

        let item_count: i64 = conn
            .query_row("SELECT COUNT(*) FROM items", [], |r| r.get(0))
            .unwrap();
        let log_count: i64 = conn
            .query_row("SELECT COUNT(*) FROM log", [], |r| r.get(0))
            .unwrap();
        assert_eq!(item_count, 2);
        assert_eq!(log_count, 1);
    }

    #[test]
    fn is_busy_error_detects_busy() {
        let busy = rusqlite::Error::SqliteFailure(
            rusqlite::ffi::Error {
                code: rusqlite::ffi::ErrorCode::DatabaseBusy,
                extended_code: 5,
            },
            Some("database is locked".to_string()),
        );
        assert!(is_busy_error(&busy));
    }

    #[test]
    fn multiple_stores_share_connection_and_operate_independently() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("multi_store.db");

        // Simulate two different stores both getting a shared connection
        let conn1 = shared_connection(&db_path).unwrap();
        let conn2 = shared_connection(&db_path).unwrap();
        assert!(Arc::ptr_eq(&conn1, &conn2));

        // "Store A" creates its table
        {
            let guard = conn1.lock().unwrap();
            guard
                .execute_batch("CREATE TABLE store_a (id INTEGER PRIMARY KEY, data TEXT)")
                .unwrap();
        }

        // "Store B" creates its table
        {
            let guard = conn2.lock().unwrap();
            guard
                .execute_batch("CREATE TABLE store_b (id INTEGER PRIMARY KEY, data TEXT)")
                .unwrap();
        }

        // Both stores write interleaved
        {
            let guard = conn1.lock().unwrap();
            guard
                .execute("INSERT INTO store_a VALUES (1, 'from_a')", [])
                .unwrap();
        }
        {
            let guard = conn2.lock().unwrap();
            guard
                .execute("INSERT INTO store_b VALUES (1, 'from_b')", [])
                .unwrap();
        }
        {
            let guard = conn1.lock().unwrap();
            guard
                .execute("INSERT INTO store_a VALUES (2, 'from_a_2')", [])
                .unwrap();
        }

        // Verify isolation between logical stores
        let guard = conn1.lock().unwrap();
        let a_count: i64 = guard
            .query_row("SELECT COUNT(*) FROM store_a", [], |r| r.get(0))
            .unwrap();
        let b_count: i64 = guard
            .query_row("SELECT COUNT(*) FROM store_b", [], |r| r.get(0))
            .unwrap();
        assert_eq!(a_count, 2);
        assert_eq!(b_count, 1);
    }
