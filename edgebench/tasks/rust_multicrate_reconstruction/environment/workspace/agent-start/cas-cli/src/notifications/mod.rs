//! Notification system for CAS TUI
//!
//! Provides real-time notifications for CAS events like task creation,
//! memory additions, and rule promotions.

mod channel;
mod types;

pub use channel::{ChannelNotifier, NotificationReceiver};
pub use types::{NotificationEvent, NotificationEventType};

use std::sync::Arc;

/// Trait for sending notifications
pub trait Notifier: Send + Sync {
    /// Send a notification event
    fn notify(&self, event: NotificationEvent);
}

/// Global notifier instance (set during TUI startup)
static GLOBAL_NOTIFIER: std::sync::OnceLock<Arc<dyn Notifier>> = std::sync::OnceLock::new();

/// Set the global notifier (called once during TUI initialization)
pub fn set_global_notifier(notifier: Arc<dyn Notifier>) { todo!() }

/// Get the global notifier if set
pub fn get_global_notifier() -> Option<Arc<dyn Notifier>> { todo!() }

/// Check if a global notifier is set
pub fn has_notifier() -> bool { todo!() }
