use crate::ui::factory::daemon::imports::*;
use crate::ui::factory::director::AgentSummary;

impl FactoryDaemon {
    pub(super) fn handle_mux_event(&mut self, event: cas_mux::MuxEvent) { todo!() }

    /// Handle worker crash
    fn handle_worker_crash(
        &mut self,
        worker_name: &str,
        exit_code: Option<i32>,
    ) -> anyhow::Result<()> { todo!() }

    /// Process prompt queue
    pub(super) async fn process_prompt_queue(&mut self) -> anyhow::Result<()> { todo!() }

    /// Poll the spawn queue and enqueue individual actions (non-blocking).
    ///
    /// Instead of spawning workers synchronously (which blocks the TUI for seconds),
    /// this converts spawn requests into individual PendingSpawn items that are
    /// processed one-per-tick in the main loop.
    pub(super) fn enqueue_spawn_requests(&mut self) -> anyhow::Result<()> { todo!() }

    /// Process pending spawn actions without blocking the main loop.
    ///
    /// Git worktree creation (the slow part) runs on a background thread via
    /// `spawn_blocking`. Only one background spawn runs at a time. Each tick we
    /// either: (a) check if the in-flight spawn finished, or (b) start a new one.
    pub(super) async fn process_pending_spawns(&mut self) { todo!() }

    /// Process pending reminders (time-based and event-based)
    ///
    /// Called during the 2-second refresh cycle with the events detected in this tick.
    /// Time-based reminders fire when trigger_at <= now.
    /// Event-based reminders fire when a matching DirectorEvent is detected.
    /// Delivery uses both the supervisor notification queue (for structured data / web UI)
    /// and the prompt queue (for PTY injection into the supervisor's session).
    pub(super) fn process_reminders(&self, events: &[crate::ui::factory::director::DirectorEvent]) { todo!() }

    /// Handle epic state change
    ///
    /// Manages git branches when epic state transitions:
    /// - Started: Creates epic branch, workers branch from it
    /// - Completed: Merges worker branches to epic branch
    pub(super) async fn handle_epic_change(
        &mut self,
        change: EpicStateChange,
    ) -> anyhow::Result<()> { todo!() }
}

/// Fire a reminder by delivering it to both the notification queue
/// (for web UI / structured data) and the prompt queue (for PTY injection).
///
/// `agent_id_to_name` maps agent UUIDs to pane names that the prompt queue
/// can route to. Falls back to `"supervisor"` when the target agent ID is
/// not found in the map.
///
/// `triggering_event` is the DirectorEvent that caused this reminder to fire
/// (only set for event-based reminders). Its context is included in the
/// delivered prompt so the recipient knows what happened.
fn fire_reminder(
    reminder: &cas_store::Reminder,
    reminder_store: &std::sync::Arc<dyn cas_store::ReminderStore>,
    supervisor_queue: &Option<std::sync::Arc<dyn cas_store::SupervisorQueueStore>>,
    prompt_queue: &Option<std::sync::Arc<dyn cas_store::PromptQueueStore>>,
    session_name: &str,
    agent_id_to_name: &std::collections::HashMap<String, String>,
    triggering_event: Option<&crate::ui::factory::director::DirectorEvent>,
) { todo!() }

/// Check if a reminder's event filter matches a detected DirectorEvent.
///
/// Uses JSON subset matching: every key-value in the filter must appear
/// in the event's JSON representation. An empty or missing filter matches
/// any event of the correct type.
fn matches_event_filter(
    reminder: &cas_store::Reminder,
    event: &crate::ui::factory::director::DirectorEvent,
) -> bool { todo!() }

fn is_exact_agent_name_match(agent: &AgentSummary, worker_name: &str) -> bool { todo!() }

#[cfg(test)]
mod tests {
    use super::is_exact_agent_name_match;
    use crate::ui::factory::director::AgentSummary;
    use cas_types::AgentStatus;

}
