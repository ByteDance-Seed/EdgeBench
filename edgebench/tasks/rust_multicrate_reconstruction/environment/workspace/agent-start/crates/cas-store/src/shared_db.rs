//! Process-level shared SQLite connection pool.
//!
//! All SQLite stores in a process share ONE connection per database file,
//! dramatically reducing connection count and eliminating intra-process
//! write lock contention when many store types access the same `cas.db`.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, Weak};
use std::time::Duration;

use rusqlite::Connection;

use crate::SQLITE_BUSY_TIMEOUT;

/// Process-global pool of shared SQLite connections, keyed by canonical DB path.
///
/// Uses `Weak` references so connections are cleaned up when all stores are dropped.
static POOL: Mutex<Option<HashMap<PathBuf, Weak<Mutex<Connection>>>>> = Mutex::new(None);

/// Get or create a shared SQLite connection for the given database path.
///
/// All callers with the same canonical path share one underlying `Connection`.
/// PRAGMAs (WAL, busy_timeout, etc.) are configured exactly once per connection.
pub fn shared_connection(db_path: &Path) -> crate::Result<Arc<Mutex<Connection>>> { todo!() }

/// RAII guard for an IMMEDIATE transaction.
///
/// Unlike `rusqlite::Transaction` (which uses DEFERRED), this acquires the
/// write lock immediately, preventing the deadlock pattern where two readers
/// try to upgrade to writers simultaneously.
pub struct ImmediateTx<'a> {
    conn: &'a Connection,
    committed: bool,
}

impl<'a> ImmediateTx<'a> {
    /// Start a new IMMEDIATE transaction on the given connection.
    pub fn new(conn: &'a Connection) -> rusqlite::Result<Self> { todo!() }

    /// Commit the transaction.
    pub fn commit(mut self) -> rusqlite::Result<()> { todo!() }
}

impl<'a> Drop for ImmediateTx<'a> {
    fn drop(&mut self) { todo!() }
}

impl<'a> std::ops::Deref for ImmediateTx<'a> {
    type Target = Connection;
    fn deref(&self) -> &Connection { todo!() }
}

/// Check if a `rusqlite::Error` is a SQLITE_BUSY error.
pub fn is_busy_error(e: &rusqlite::Error) -> bool { todo!() }

/// Execute a fallible closure with retry on SQLITE_BUSY errors.
///
/// Uses exponential backoff: 50ms, 100ms, 200ms, 400ms, 800ms (5 retries).
/// Combined with the 5s busy_timeout, this gives a total max wait of ~26.5s
/// before giving up, but with jitter that reduces convoy effects.
pub fn with_write_retry<T, F>(f: F) -> crate::Result<T>
where
    F: Fn() -> crate::Result<T>,
{ todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use std::panic;
    use std::sync::Barrier;
    use tempfile::TempDir;

    // ── Connection pool basics ──────────────────────────────────────


    #[test]
    fn shared_connection_different_paths_different_instances() {
        let temp = TempDir::new().unwrap();
        let db1 = temp.path().join("a.db");
        let db2 = temp.path().join("b.db");

        let conn1 = shared_connection(&db1).unwrap();
        let conn2 = shared_connection(&db2).unwrap();

        assert!(!Arc::ptr_eq(&conn1, &conn2));
    }





    // ── Pool poisoning recovery ─────────────────────────────────────


    // ── Concurrent access ───────────────────────────────────────────

    #[test]
    fn concurrent_shared_connection_calls_return_same_instance() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("concurrent.db");

        let num_threads = 20;
        let barrier = Arc::new(Barrier::new(num_threads));
        let path = db_path.clone();

        let handles: Vec<_> = (0..num_threads)
            .map(|_| {
                let b = barrier.clone();
                let p = path.clone();
                std::thread::spawn(move || {
                    b.wait();
                    shared_connection(&p).unwrap()
                })
            })
            .collect();

        let conns: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

        // All threads should get the same Arc
        for conn in &conns[1..] {
            assert!(Arc::ptr_eq(&conns[0], conn));
        }
    }

    #[test]
    fn concurrent_writers_through_shared_connection() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("writers.db");

        let conn = shared_connection(&db_path).unwrap();
        {
            let guard = conn.lock().unwrap();
            guard
                .execute_batch(
                    "CREATE TABLE counters (id INTEGER PRIMARY KEY, val INTEGER DEFAULT 0)",
                )
                .unwrap();
            guard
                .execute("INSERT INTO counters (id, val) VALUES (1, 0)", [])
                .unwrap();
        }

        let num_threads = 50;
        let barrier = Arc::new(Barrier::new(num_threads));

        let handles: Vec<_> = (0..num_threads)
            .map(|_| {
                let c = conn.clone();
                let b = barrier.clone();
                std::thread::spawn(move || {
                    b.wait();
                    let guard = c.lock().unwrap();
                    guard
                        .execute("UPDATE counters SET val = val + 1 WHERE id = 1", [])
                        .unwrap();
                })
            })
            .collect();

        for h in handles {
            h.join().unwrap();
        }

        let guard = conn.lock().unwrap();
        let val: i64 = guard
            .query_row("SELECT val FROM counters WHERE id = 1", [], |r| r.get(0))
            .unwrap();
        assert_eq!(val, num_threads as i64);
    }


    // ── ImmediateTx ────────────────────────────────────────────────

    #[test]
    fn immediate_tx_commits() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("CREATE TABLE t (x INTEGER)").unwrap();

        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (1)", []).unwrap();
            tx.commit().unwrap();
        }

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM t", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 1);
    }

    #[test]
    fn immediate_tx_rolls_back_on_drop() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("test.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("CREATE TABLE t (x INTEGER)").unwrap();

        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (1)", []).unwrap();
            // drop without commit
        }

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM t", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 0);
    }

    #[test]
    fn immediate_tx_rolls_back_on_panic() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("panic.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("CREATE TABLE t (x INTEGER)").unwrap();

        let _ = panic::catch_unwind(panic::AssertUnwindSafe(|| {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (42)", []).unwrap();
            panic!("simulated error");
        }));

        // The row should NOT be present after panic-triggered rollback
        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM t", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 0);
    }

    #[test]
    fn immediate_tx_deref_allows_queries() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("deref.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("CREATE TABLE t (x INTEGER)").unwrap();
        conn.execute("INSERT INTO t VALUES (99)", []).unwrap();

        let tx = ImmediateTx::new(&conn).unwrap();
        // Use Deref to call Connection methods directly on tx
        let val: i64 = tx.query_row("SELECT x FROM t", [], |r| r.get(0)).unwrap();
        assert_eq!(val, 99);
        tx.commit().unwrap();
    }

    #[test]
    fn immediate_tx_sequential_transactions() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("seq.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("CREATE TABLE t (x INTEGER)").unwrap();

        // First transaction — commit
        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (1)", []).unwrap();
            tx.commit().unwrap();
        }

        // Second transaction — rollback
        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (2)", []).unwrap();
            // drop without commit
        }

        // Third transaction — commit
        {
            let tx = ImmediateTx::new(&conn).unwrap();
            tx.execute("INSERT INTO t VALUES (3)", []).unwrap();
            tx.commit().unwrap();
        }

        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM t", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 2); // Only rows 1 and 3

        let sum: i64 = conn
            .query_row("SELECT SUM(x) FROM t", [], |r| r.get(0))
            .unwrap();
        assert_eq!(sum, 4); // 1 + 3
    }


    // ── is_busy_error ───────────────────────────────────────────────


    #[test]
    fn is_busy_error_rejects_other_errors() {
        let not_busy = rusqlite::Error::SqliteFailure(
            rusqlite::ffi::Error {
                code: rusqlite::ffi::ErrorCode::ConstraintViolation,
                extended_code: 19,
            },
            None,
        );
        assert!(!is_busy_error(&not_busy));

        let query_err = rusqlite::Error::QueryReturnedNoRows;
        assert!(!is_busy_error(&query_err));
    }

    // ── with_write_retry ────────────────────────────────────────────

    #[test]
    fn with_write_retry_succeeds_on_first_try() {
        let call_count = Arc::new(Mutex::new(0u32));
        let cc = call_count.clone();

        let result = with_write_retry(|| {
            *cc.lock().unwrap() += 1;
            Ok(42)
        });

        assert_eq!(result.unwrap(), 42);
        assert_eq!(*call_count.lock().unwrap(), 1);
    }

    #[test]
    fn with_write_retry_retries_on_busy_then_succeeds() {
        let call_count = Arc::new(Mutex::new(0u32));
        let cc = call_count.clone();

        let result = with_write_retry(|| {
            let mut count = cc.lock().unwrap();
            *count += 1;
            if *count <= 3 {
                // Simulate SQLITE_BUSY for first 3 calls
                Err(crate::error::StoreError::Database(
                    rusqlite::Error::SqliteFailure(
                        rusqlite::ffi::Error {
                            code: rusqlite::ffi::ErrorCode::DatabaseBusy,
                            extended_code: 5,
                        },
                        Some("database is locked".to_string()),
                    ),
                ))
            } else {
                Ok("success")
            }
        });

        assert_eq!(result.unwrap(), "success");
        assert_eq!(*call_count.lock().unwrap(), 4); // 3 retries + 1 success
    }

    #[test]
    fn with_write_retry_gives_up_after_max_retries() {
        let call_count = Arc::new(Mutex::new(0u32));
        let cc = call_count.clone();

        let result: crate::Result<()> = with_write_retry(|| {
            *cc.lock().unwrap() += 1;
            Err(crate::error::StoreError::Database(
                rusqlite::Error::SqliteFailure(
                    rusqlite::ffi::Error {
                        code: rusqlite::ffi::ErrorCode::DatabaseBusy,
                        extended_code: 5,
                    },
                    Some("database is locked".to_string()),
                ),
            ))
        });

        assert!(result.is_err());
        // 5 retries + 1 final attempt = 6 total calls
        assert_eq!(*call_count.lock().unwrap(), 6);
    }

    #[test]
    fn with_write_retry_does_not_retry_non_busy_errors() {
        let call_count = Arc::new(Mutex::new(0u32));
        let cc = call_count.clone();

        let result: crate::Result<()> = with_write_retry(|| {
            *cc.lock().unwrap() += 1;
            Err(crate::error::StoreError::Database(
                rusqlite::Error::SqliteFailure(
                    rusqlite::ffi::Error {
                        code: rusqlite::ffi::ErrorCode::ConstraintViolation,
                        extended_code: 19,
                    },
                    Some("UNIQUE constraint failed".to_string()),
                ),
            ))
        });

        assert!(result.is_err());
        // Should NOT retry — only 1 call
        assert_eq!(*call_count.lock().unwrap(), 1);
    }

    #[test]
    fn with_write_retry_does_not_retry_non_database_errors() {
        let call_count = Arc::new(Mutex::new(0u32));
        let cc = call_count.clone();

        let result: crate::Result<()> = with_write_retry(|| {
            *cc.lock().unwrap() += 1;
            Err(crate::error::StoreError::NotFound("gone".to_string()))
        });

        assert!(result.is_err());
        assert_eq!(*call_count.lock().unwrap(), 1);
    }

    // ── Cross-process write contention (simulated with separate connections) ──

    #[test]
    fn cross_connection_write_contention() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("contention.db");

        // Set up the database
        let setup_conn = Connection::open(&db_path).unwrap();
        setup_conn
            .execute_batch(
                "PRAGMA journal_mode=WAL;\
                 CREATE TABLE counter (id INTEGER PRIMARY KEY, val INTEGER)",
            )
            .unwrap();
        setup_conn
            .execute("INSERT INTO counter VALUES (1, 0)", [])
            .unwrap();
        drop(setup_conn);

        let num_threads = 20;
        let barrier = Arc::new(Barrier::new(num_threads));
        let successes = Arc::new(Mutex::new(0u32));

        let handles: Vec<_> = (0..num_threads)
            .map(|_| {
                let b = barrier.clone();
                let p = db_path.clone();
                let s = successes.clone();
                std::thread::spawn(move || {
                    // Each thread gets its own connection (simulating separate processes)
                    let conn = Connection::open(&p).unwrap();
                    conn.execute_batch("PRAGMA journal_mode=WAL").unwrap();
                    conn.busy_timeout(Duration::from_secs(5)).unwrap();

                    b.wait();

                    // Try to increment the counter
                    match conn.execute("UPDATE counter SET val = val + 1 WHERE id = 1", []) {
                        Ok(_) => *s.lock().unwrap() += 1,
                        Err(e) => panic!("Write failed: {e}"),
                    }
                })
            })
            .collect();

        for h in handles {
            h.join().unwrap();
        }

        // All writes should succeed thanks to busy_timeout + WAL
        assert_eq!(*successes.lock().unwrap(), num_threads as u32);

        let verify_conn = Connection::open(&db_path).unwrap();
        let val: i64 = verify_conn
            .query_row("SELECT val FROM counter WHERE id = 1", [], |r| r.get(0))
            .unwrap();
        assert_eq!(val, num_threads as i64);
    }

    // ── ImmediateTx under contention (separate connections) ─────────

    #[test]
    fn immediate_tx_contention_across_connections() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("imm_contention.db");

        let setup_conn = Connection::open(&db_path).unwrap();
        setup_conn
            .execute_batch(
                "PRAGMA journal_mode=WAL;\
                 CREATE TABLE ledger (account TEXT, balance INTEGER)",
            )
            .unwrap();
        setup_conn
            .execute("INSERT INTO ledger VALUES ('A', 1000)", [])
            .unwrap();
        setup_conn
            .execute("INSERT INTO ledger VALUES ('B', 1000)", [])
            .unwrap();
        drop(setup_conn);

        let num_threads = 10;
        let barrier = Arc::new(Barrier::new(num_threads));

        let handles: Vec<_> = (0..num_threads)
            .map(|i| {
                let b = barrier.clone();
                let p = db_path.clone();
                std::thread::spawn(move || {
                    let conn = Connection::open(&p).unwrap();
                    conn.execute_batch("PRAGMA journal_mode=WAL").unwrap();
                    conn.busy_timeout(Duration::from_secs(5)).unwrap();

                    b.wait();

                    // Transfer 10 from A to B using ImmediateTx
                    let tx = ImmediateTx::new(&conn).unwrap();
                    tx.execute(
                        "UPDATE ledger SET balance = balance - 10 WHERE account = 'A'",
                        [],
                    )
                    .unwrap();
                    tx.execute(
                        "UPDATE ledger SET balance = balance + 10 WHERE account = 'B'",
                        [],
                    )
                    .unwrap();
                    tx.commit().unwrap();

                    i // Return thread index for tracking
                })
            })
            .collect();

        let completed: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();
        assert_eq!(completed.len(), num_threads);

        // Verify totals are consistent (no lost updates)
        let verify = Connection::open(&db_path).unwrap();
        let a: i64 = verify
            .query_row("SELECT balance FROM ledger WHERE account = 'A'", [], |r| {
                r.get(0)
            })
            .unwrap();
        let b: i64 = verify
            .query_row("SELECT balance FROM ledger WHERE account = 'B'", [], |r| {
                r.get(0)
            })
            .unwrap();

        // Total should always be 2000 (no money created or destroyed)
        assert_eq!(a + b, 2000);
        // A should have lost 10 * num_threads
        assert_eq!(a, 1000 - (num_threads as i64 * 10));
        assert_eq!(b, 1000 + (num_threads as i64 * 10));
    }

    // ── Shared connection used by multiple "store-like" callers ─────


    // ── Edge case: empty/unusual paths ──────────────────────────────

    #[test]
    fn shared_connection_works_with_nested_path() {
        let temp = TempDir::new().unwrap();
        let nested = temp.path().join("a").join("b").join("c");
        std::fs::create_dir_all(&nested).unwrap();
        let db_path = nested.join("deep.db");

        let conn1 = shared_connection(&db_path).unwrap();
        let conn2 = shared_connection(&db_path).unwrap();
        assert!(Arc::ptr_eq(&conn1, &conn2));
    }

    // ── Stress test: many threads, mixed reads and writes ───────────

    #[test]
    fn stress_mixed_read_write_through_shared_connection() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("stress.db");

        let conn = shared_connection(&db_path).unwrap();
        {
            let guard = conn.lock().unwrap();
            guard
                .execute_batch(
                    "CREATE TABLE stress (id INTEGER PRIMARY KEY, thread_id INTEGER, val TEXT)",
                )
                .unwrap();
        }

        let num_writers = 30;
        let num_readers = 20;
        let barrier = Arc::new(Barrier::new(num_writers + num_readers));

        let mut handles = Vec::new();

        // Writer threads
        for i in 0..num_writers {
            let c = conn.clone();
            let b = barrier.clone();
            handles.push(std::thread::spawn(move || {
                b.wait();
                let guard = c.lock().unwrap();
                guard
                    .execute(
                        "INSERT INTO stress (thread_id, val) VALUES (?1, ?2)",
                        rusqlite::params![i as i64, format!("data_{i}")],
                    )
                    .unwrap();
            }));
        }

        // Reader threads
        for _ in 0..num_readers {
            let c = conn.clone();
            let b = barrier.clone();
            handles.push(std::thread::spawn(move || {
                b.wait();
                let guard = c.lock().unwrap();
                let _count: i64 = guard
                    .query_row("SELECT COUNT(*) FROM stress", [], |r| r.get(0))
                    .unwrap();
            }));
        }

        for h in handles {
            h.join().unwrap();
        }

        // Verify all writes landed
        let guard = conn.lock().unwrap();
        let count: i64 = guard
            .query_row("SELECT COUNT(*) FROM stress", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, num_writers as i64);
    }
}
