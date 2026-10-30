use rusqlite::{OptionalExtension, params};
use std::collections::HashMap;

use crate::cloud::sync_queue::{EntityType, PendingByType, QueueStats, QueuedSync, SyncQueue};
use crate::error::CasError;

impl SyncQueue {
    /// Get items grouped by entity type for batched sync.
    pub fn pending_by_type(
        &self,
        limit: usize,
        max_retries: i32,
    ) -> Result<PendingByType, CasError> { todo!() }

    /// Get items grouped by entity type for a specific team.
    pub fn pending_by_type_for_team(
        &self,
        team_id: &str,
        limit: usize,
        max_retries: i32,
    ) -> Result<PendingByType, CasError> { todo!() }

    /// Get queue statistics.
    pub fn stats(&self, max_retries: i32) -> Result<QueueStats, CasError> { todo!() }

    fn group_pending_items(items: Vec<QueuedSync>) -> PendingByType { todo!() }
}
