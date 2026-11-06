//! Shared test fixtures for CAS e2e tests
//!
//! Provides reusable test infrastructure.

mod cas_instance;
#[cfg(feature = "claude_rs_e2e")]
mod hook_instance;
mod mock_server;

pub use cas_instance::new_cas_instance;
#[cfg(feature = "claude_rs_e2e")]
pub use hook_instance::{HOOK_TEST_SESSION_ID, HookTestEnv};
