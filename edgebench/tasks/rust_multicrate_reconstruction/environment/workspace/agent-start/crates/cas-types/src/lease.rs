//! Task lease type definitions for multi-agent coordination
//!
//! Leases provide exclusive access to tasks with automatic expiration.

use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Status of a task lease
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum LeaseStatus {
    /// Lease is active and valid
    #[default]
    Active,
    /// Lease has expired (not renewed in time)
    Expired,
    /// Lease was explicitly released by the agent
    Released,
    /// Lease was revoked (e.g., agent died)
    Revoked,
}

impl fmt::Display for LeaseStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for LeaseStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A lease on a task that grants exclusive access to an agent
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskLease {
    /// Task ID this lease is for
    pub task_id: String,

    /// Agent ID that holds the lease
    pub agent_id: String,

    /// Current status of the lease
    pub status: LeaseStatus,

    /// When the lease was acquired
    pub acquired_at: DateTime<Utc>,

    /// When the lease expires (must be renewed before this time)
    pub expires_at: DateTime<Utc>,

    /// When the lease was last renewed
    pub renewed_at: DateTime<Utc>,

    /// Number of times this lease has been renewed
    #[serde(default)]
    pub renewal_count: u32,

    /// Epoch number for stale detection - incremented each time lease changes hands
    /// Used to detect and reject operations based on stale state
    #[serde(default)]
    pub epoch: u64,

    /// Optional reason for claiming the task
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub claim_reason: Option<String>,
}

impl TaskLease {
    /// Create a new lease for a task
    pub fn new(task_id: String, agent_id: String, duration_secs: i64) -> Self { todo!() }

    /// Create a new lease with incremented epoch (for reclaiming after expiry)
    pub fn new_with_epoch(
        task_id: String,
        agent_id: String,
        duration_secs: i64,
        previous_epoch: u64,
    ) -> Self { todo!() }

    /// Create a new lease with a claim reason
    pub fn with_reason(
        task_id: String,
        agent_id: String,
        duration_secs: i64,
        reason: String,
    ) -> Self { todo!() }

    /// Check if the lease is currently valid
    pub fn is_valid(&self) -> bool { todo!() }

    /// Check if the lease has expired
    pub fn is_expired(&self) -> bool { todo!() }

    /// Renew the lease with a new duration
    pub fn renew(&mut self, duration_secs: i64) { todo!() }

    /// Release the lease (graceful release)
    pub fn release(&mut self) { todo!() }

    /// Revoke the lease (forced revocation)
    pub fn revoke(&mut self) { todo!() }

    /// Mark the lease as expired
    pub fn mark_expired(&mut self) { todo!() }

    /// Get remaining time until expiration in seconds
    pub fn remaining_secs(&self) -> i64 { todo!() }

    /// Check if the lease needs renewal (less than 20% time remaining)
    pub fn needs_renewal(&self) -> bool { todo!() }
}

impl Default for TaskLease {
    fn default() -> Self { todo!() }
}

/// Result of attempting to claim a task
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ClaimResult {
    /// Successfully claimed the task
    Success(TaskLease),
    /// Task is already claimed by another agent
    AlreadyClaimed {
        task_id: String,
        held_by: String,
        expires_at: DateTime<Utc>,
    },
    /// Task doesn't exist
    TaskNotFound(String),
    /// Task is not in a claimable state (e.g., closed)
    NotClaimable { task_id: String, reason: String },
    /// Agent is not authorized to claim tasks
    Unauthorized(String),
}

impl ClaimResult {
    /// Check if the claim was successful
    pub fn is_success(&self) -> bool { todo!() }

    /// Get the lease if successful
    pub fn lease(&self) -> Option<&TaskLease> { todo!() }
}

/// A lease on a worktree that grants exclusive access to an agent
///
/// Similar to TaskLease but for worktrees. When an agent claims a worktree,
/// no other agent can work on that worktree until the lease expires or is released.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorktreeLease {
    /// Worktree ID this lease is for
    pub worktree_id: String,

    /// Agent ID that holds the lease
    pub agent_id: String,

    /// Current status of the lease
    pub status: LeaseStatus,

    /// When the lease was acquired
    pub acquired_at: DateTime<Utc>,

    /// When the lease expires (must be renewed before this time)
    pub expires_at: DateTime<Utc>,

    /// When the lease was last renewed
    pub renewed_at: DateTime<Utc>,

    /// Number of times this lease has been renewed
    #[serde(default)]
    pub renewal_count: u32,
}

impl WorktreeLease {
    /// Create a new lease for a worktree
    pub fn new(worktree_id: String, agent_id: String, duration_secs: i64) -> Self { todo!() }

    /// Check if the lease is currently valid
    pub fn is_valid(&self) -> bool { todo!() }

    /// Check if the lease has expired
    pub fn is_expired(&self) -> bool { todo!() }

    /// Renew the lease with a new duration
    pub fn renew(&mut self, duration_secs: i64) { todo!() }

    /// Release the lease (graceful release)
    pub fn release(&mut self) { todo!() }

    /// Revoke the lease (forced revocation)
    pub fn revoke(&mut self) { todo!() }

    /// Mark the lease as expired
    pub fn mark_expired(&mut self) { todo!() }

    /// Get remaining time until expiration in seconds
    pub fn remaining_secs(&self) -> i64 { todo!() }
}

impl Default for WorktreeLease {
    fn default() -> Self { todo!() }
}

/// Result of attempting to claim a worktree
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WorktreeClaimResult {
    /// Successfully claimed the worktree
    Success(WorktreeLease),
    /// Worktree is already claimed by another agent
    AlreadyClaimed {
        worktree_id: String,
        held_by: String,
        expires_at: DateTime<Utc>,
    },
    /// Worktree doesn't exist
    WorktreeNotFound(String),
    /// Agent is not authorized to claim worktrees
    Unauthorized(String),
}

impl WorktreeClaimResult {
    /// Check if the claim was successful
    pub fn is_success(&self) -> bool { todo!() }

    /// Get the lease if successful
    pub fn lease(&self) -> Option<&WorktreeLease> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::lease::*;

    #[test]
    fn test_lease_status_from_str() {
        assert_eq!(
            LeaseStatus::from_str("active").unwrap(),
            LeaseStatus::Active
        );
        assert_eq!(
            LeaseStatus::from_str("expired").unwrap(),
            LeaseStatus::Expired
        );
        assert_eq!(
            LeaseStatus::from_str("released").unwrap(),
            LeaseStatus::Released
        );
        assert_eq!(
            LeaseStatus::from_str("revoked").unwrap(),
            LeaseStatus::Revoked
        );
        assert!(LeaseStatus::from_str("invalid").is_err());
    }

    #[test]
    fn test_lease_new() {
        let lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 600);
        assert_eq!(lease.task_id, "task-1");
        assert_eq!(lease.agent_id, "agent-1");
        assert_eq!(lease.status, LeaseStatus::Active);
        assert!(lease.is_valid());
        assert!(!lease.is_expired());
        assert_eq!(lease.renewal_count, 0);
    }


    #[test]
    fn test_lease_expiry() {
        let mut lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 1);
        assert!(lease.is_valid());

        // Simulate time passing
        lease.expires_at = Utc::now() - Duration::seconds(1);
        assert!(lease.is_expired());
        assert!(!lease.is_valid());
    }

    #[test]
    fn test_lease_renewal() {
        let mut lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 60);
        let old_expires = lease.expires_at;

        std::thread::sleep(std::time::Duration::from_millis(10));
        lease.renew(120);

        assert!(lease.expires_at > old_expires);
        assert_eq!(lease.renewal_count, 1);
        assert!(lease.is_valid());
    }

    #[test]
    fn test_lease_release() {
        let mut lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 600);
        assert!(lease.is_valid());

        lease.release();
        assert_eq!(lease.status, LeaseStatus::Released);
        assert!(!lease.is_valid());
    }

    #[test]
    fn test_remaining_secs() {
        let lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 600);
        let remaining = lease.remaining_secs();
        assert!(remaining > 590 && remaining <= 600);
    }

    #[test]
    fn test_needs_renewal() {
        let mut lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 100);
        assert!(!lease.needs_renewal()); // Fresh lease doesn't need renewal

        // Simulate time passing - set renewed_at to 100 seconds ago, expires in 15 seconds
        // This means we have 15% of the original 100 second duration remaining
        lease.renewed_at = Utc::now() - Duration::seconds(85);
        lease.expires_at = Utc::now() + Duration::seconds(15);
        // Total duration: 100s, remaining: 15s, threshold: 20s -> needs renewal
        assert!(lease.needs_renewal());
    }

    #[test]
    fn test_claim_result() {
        let lease = TaskLease::new("task-1".to_string(), "agent-1".to_string(), 600);
        let result = ClaimResult::Success(lease);
        assert!(result.is_success());
        assert!(result.lease().is_some());

        let result = ClaimResult::TaskNotFound("task-2".to_string());
        assert!(!result.is_success());
        assert!(result.lease().is_none());
    }
}
