//! Terminal notifications for factory mode
//!
//! Supports multiple notification backends:
//! - Native cross-platform notifications via notify-rust (macOS, Linux, Windows)
//! - Terminal bell (\x07)
//! - iTerm2 inline notifications

use std::io::{self, Write};

use notify_rust::{Notification, Timeout, Urgency};

use crate::ui::factory::director::DirectorEvent;

// Re-export from cas-factory for backward compatibility
pub use cas_factory::{NotifyBackend, NotifyConfig};

/// Notification metadata for different event types
struct NotificationMeta {
    title: &'static str,
    icon: &'static str,
    urgency: Urgency,
}

/// Notification manager
pub struct Notifier {
    config: NotifyConfig,
}

impl Notifier {
    /// Create a new notifier with the given config
    pub fn new(config: NotifyConfig) -> Self { todo!() }

    /// Check if notifications are enabled
    pub fn is_enabled(&self) -> bool { todo!() }

    /// Get notification metadata for an event type
    fn event_meta(event: &DirectorEvent) -> Option<NotificationMeta> { todo!() }

    /// Send a notification for a director event
    pub fn notify_event(&self, event: &DirectorEvent) { todo!() }

    /// Send a custom notification
    pub fn notify(&self, title: &str, body: &str) { todo!() }

    /// Send a notification about a worker crash
    pub fn notify_crash(&self, worker: &str, exit_info: &str) { todo!() }

    /// Send the notification using the configured backend
    fn send(&self, title: &str, body: &str, urgency: Urgency, icon: &str) { todo!() }

    /// Send notification via notify-rust (cross-platform)
    fn send_native(
        &self,
        title: &str,
        body: &str,
        urgency: Urgency,
        icon: &str,
    ) -> Result<(), String> { todo!() }

    /// Send terminal bell
    fn send_bell(&self) { todo!() }

    /// Send iTerm2 notification
    fn send_iterm2(&self, title: &str, body: &str) { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::ui::factory::notification::*;

    #[test]
    fn test_notify_backend_detection() {
        let backend = NotifyBackend::detect();
        // Should detect a valid backend
        assert!(matches!(
            backend,
            NotifyBackend::Native | NotifyBackend::ITerm2 | NotifyBackend::Bell
        ));
    }


    #[test]
    fn test_event_notification_metadata() {
        let completed = DirectorEvent::TaskCompleted {
            task_id: "cas-123".to_string(),
            task_title: "Test".to_string(),
            worker: "swift-fox".to_string(),
        };
        let meta = Notifier::event_meta(&completed).unwrap();
        assert_eq!(meta.title, "Task Completed");
        assert!(matches!(meta.urgency, Urgency::Normal));

        // TaskAssigned should return None (no notification)
        let assigned = DirectorEvent::TaskAssigned {
            task_id: "cas-123".to_string(),
            task_title: "Test".to_string(),
            worker: "swift-fox".to_string(),
        };
        assert!(Notifier::event_meta(&assigned).is_none());
    }

    #[test]
    fn test_event_notification_content() {
        let event = DirectorEvent::TaskCompleted {
            task_id: "cas-123".to_string(),
            task_title: "Test Task".to_string(),
            worker: "swift-fox".to_string(),
        };
        assert!(event.description().contains("swift-fox"));
        assert!(event.description().contains("cas-123"));
    }
}
