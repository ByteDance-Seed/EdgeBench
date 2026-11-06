use std::time::Instant;

use crate::cloud::syncer::{CloudSyncer, GroupedQueuedItems, SyncResult, TeamPushResponse};
use crate::cloud::{EntityType, QueuedSync, SyncOperation, get_project_canonical_id};
use crate::error::CasError;
use chrono::Utc;

impl CloudSyncer {
    pub fn push_team(&self, team_id: &str) -> Result<SyncResult, CasError> { todo!() }

    /// Group queued items by entity type and operation
    fn group_queued_items(&self, items: &[QueuedSync]) -> GroupedQueuedItems { todo!() }

    /// Send team delete requests for each entity type
    fn send_team_deletes(
        &self,
        team_id: &str,
        grouped: &GroupedQueuedItems,
        token: &str,
    ) -> (usize, Vec<String>) { todo!() }

    /// Send a single team delete request
    fn send_team_delete(
        &self,
        team_id: &str,
        entity_type: &str,
        cas_id: &str,
        token: &str,
    ) -> Result<(), CasError> { todo!() }
}
