use rusqlite::Connection;

use crate::cloud::sync_queue::SyncQueue;
use crate::error::CasError;

pub(super) const SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload TEXT,
    team_id TEXT,
    created_at TEXT NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    UNIQUE(entity_type, entity_id, team_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at);
CREATE INDEX IF NOT EXISTS idx_sync_queue_retry ON sync_queue(retry_count);
CREATE INDEX IF NOT EXISTS idx_sync_queue_team ON sync_queue(team_id);

CREATE TABLE IF NOT EXISTS sync_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
"#;

impl SyncQueue {
    /// Add team_id column to existing sync_queue tables.
    pub(super) fn migrate_team_id(&self, conn: &Connection) -> Result<(), CasError> { todo!() }
}
