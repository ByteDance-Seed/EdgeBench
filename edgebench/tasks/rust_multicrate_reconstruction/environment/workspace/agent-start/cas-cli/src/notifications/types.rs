//! Notification event types

use std::time::Instant;

/// Types of notification events
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NotificationEventType {
    // Task events
    TaskCreated,
    TaskStarted,
    TaskClosed,
    TaskUpdated,

    // Entry/memory events
    EntryAdded,
    EntryUpdated,
    EntryDeleted,

    // Rule events
    RuleCreated,
    RulePromoted,
    RuleDemoted,

    // Skill events
    SkillCreated,
    SkillEnabled,
    SkillDisabled,
}

impl NotificationEventType {
    /// Get a human-readable title for this event type
    pub fn title(&self) -> &'static str { todo!() }

    /// Get an icon/symbol for this event type
    pub fn icon(&self) -> &'static str { todo!() }

    /// Check if this is a positive/success event (for color coding)
    pub fn is_positive(&self) -> bool { todo!() }

    /// Check if this is a negative/warning event
    pub fn is_negative(&self) -> bool { todo!() }
}

/// A notification event to display in the TUI
#[derive(Debug, Clone)]
pub struct NotificationEvent {
    /// Type of event
    pub event_type: NotificationEventType,
    /// ID of the affected entity
    pub entity_id: String,
    /// Short description/message
    pub message: String,
    /// When the event occurred (for timeout tracking)
    pub timestamp: Instant,
}

impl NotificationEvent {
    /// Create a new notification event
    pub fn new(
        event_type: NotificationEventType,
        entity_id: impl Into<String>,
        message: impl Into<String>,
    ) -> Self { todo!() }

    /// Get the title for display
    pub fn title(&self) -> &'static str { todo!() }

    /// Get the icon for display
    pub fn icon(&self) -> &'static str { todo!() }

    // Convenience constructors for common events

    /// Task created notification
    pub fn task_created(id: &str, title: &str) -> Self { todo!() }

    /// Task started notification
    pub fn task_started(id: &str, title: &str) -> Self { todo!() }

    /// Task closed notification
    pub fn task_closed(id: &str, title: &str) -> Self { todo!() }

    /// Task updated notification
    pub fn task_updated(id: &str, title: &str) -> Self { todo!() }

    /// Entry added notification
    pub fn entry_added(id: &str, entry_type: &str) -> Self { todo!() }

    /// Entry updated notification
    pub fn entry_updated(id: &str) -> Self { todo!() }

    /// Entry deleted notification
    pub fn entry_deleted(id: &str) -> Self { todo!() }

    /// Rule created notification
    pub fn rule_created(id: &str) -> Self { todo!() }

    /// Rule promoted notification
    pub fn rule_promoted(id: &str) -> Self { todo!() }

    /// Rule demoted notification
    pub fn rule_demoted(id: &str) -> Self { todo!() }

    /// Skill created notification
    pub fn skill_created(id: &str, name: &str) -> Self { todo!() }

    /// Skill enabled notification
    pub fn skill_enabled(id: &str, name: &str) -> Self { todo!() }

    /// Skill disabled notification
    pub fn skill_disabled(id: &str, name: &str) -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::notifications::types::*;

    #[test]
    fn test_event_creation() {
        let event = NotificationEvent::task_created("cas-123", "Fix the bug");
        assert_eq!(event.event_type, NotificationEventType::TaskCreated);
        assert_eq!(event.entity_id, "cas-123");
        assert_eq!(event.message, "Fix the bug");
        assert_eq!(event.title(), "Task Created");
        assert_eq!(event.icon(), "+");
    }

    #[test]
    fn test_event_type_properties() {
        assert!(NotificationEventType::TaskClosed.is_positive());
        assert!(!NotificationEventType::TaskClosed.is_negative());

        assert!(!NotificationEventType::EntryDeleted.is_positive());
        assert!(NotificationEventType::EntryDeleted.is_negative());

        assert!(!NotificationEventType::TaskUpdated.is_positive());
        assert!(!NotificationEventType::TaskUpdated.is_negative());
    }
}
