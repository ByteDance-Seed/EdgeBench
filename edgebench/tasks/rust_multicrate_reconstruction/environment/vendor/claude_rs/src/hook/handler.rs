//! Hook handler trait.

use crate::hook::{HookInput, HookOutput};
use async_trait::async_trait;

/// Trait for hook handlers.
#[async_trait]
pub trait HookHandler: Send + Sync {
    /// Handle a hook event.
    async fn handle(&self, input: HookInput) -> HookOutput;
}

/// Handler that always approves.
pub struct ApproveHandler;

#[async_trait]
impl HookHandler for ApproveHandler {
    async fn handle(&self, _input: HookInput) -> HookOutput {
        HookOutput::approve()
    }
}

/// Handler that always denies.
pub struct DenyHandler {
    pub reason: String,
}

#[async_trait]
impl HookHandler for DenyHandler {
    async fn handle(&self, _input: HookInput) -> HookOutput {
        HookOutput::deny(&self.reason)
    }
}
