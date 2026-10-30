//! Auto-prompting system for the Director
//!
//! Generates prompts based on detected CAS state changes and injects them
//! into the appropriate agent's terminal.

use crate::config::AutoPromptConfig;
use crate::ui::factory::director::data::DirectorData;
use crate::ui::factory::director::events::DirectorEvent;
use cas_mux::SupervisorCli;

/// A prompt to be injected into an agent's terminal
#[derive(Debug, Clone)]
pub struct Prompt {
    /// Target agent name (worker name or "supervisor")
    pub target: String,
    /// Prompt text to inject
    pub text: String,
}

/// Wrap a message with response instructions
///
/// Appends instructions telling the agent how to respond using the MCP message tool.
/// The command prefix differs by harness:
/// - Claude: `mcp__cas__`
/// - Codex: `mcp__cs__`
///
/// # Arguments
/// * `message` - The original message text
/// * `respond_to` - The target agent name for responses (e.g., "supervisor", "swift-fox")
/// * `receiver_cli` - CLI harness for the agent receiving this message
///
/// # Returns
/// The message with response instructions appended at the end
pub fn with_response_instructions(
    message: &str,
    respond_to: &str,
    receiver_cli: SupervisorCli,
) -> String { todo!() }

/// Generate a prompt for a detected event
///
/// Returns `Some(Prompt)` if a prompt should be sent for this event,
/// or `None` if no prompt is needed or if the event type is disabled in config.
pub fn generate_prompt(
    event: &DirectorEvent,
    data: &DirectorData,
    supervisor_name: &str,
    config: &AutoPromptConfig,
    supervisor_cli: SupervisorCli,
    worker_cli: SupervisorCli,
) -> Option<Prompt> { todo!() }

#[cfg(test)]
mod tests {
    use crate::ui::factory::director::data::TaskSummary;
    use crate::ui::factory::director::prompts::*;
    use cas_mux::SupervisorCli;
    use cas_types::{Priority, TaskStatus, TaskType};
    use std::collections::HashMap;

    fn make_data(ready_count: usize) -> DirectorData {
        let ready_tasks: Vec<TaskSummary> = (0..ready_count)
            .map(|i| TaskSummary {
                id: format!("task-{i}"),
                title: format!("Ready Task {i}"),
                status: TaskStatus::Open,
                priority: Priority::MEDIUM,
                assignee: None,
                task_type: TaskType::Task,
                epic: None,
                branch: None,
            })
            .collect();

        DirectorData {
            ready_tasks,
            in_progress_tasks: vec![],
            epic_tasks: vec![],
            agents: vec![],
            activity: vec![],
            agent_id_to_name: HashMap::new(),
            changes: vec![],
            git_loaded: true,
            reminders: vec![],
            epic_closed_counts: HashMap::new(),
        }
    }

    fn default_config() -> AutoPromptConfig {
        AutoPromptConfig::default()
    }

    fn codex() -> SupervisorCli {
        SupervisorCli::Codex
    }

    fn claude() -> SupervisorCli {
        SupervisorCli::Claude
    }


    #[test]
    fn test_task_completed_prompt() {
        let event = DirectorEvent::TaskCompleted {
            task_id: "task-123".to_string(),
            task_title: "Implement feature X".to_string(),
            worker: "swift-fox".to_string(),
        };
        let data = make_data(0);
        let config = default_config();

        let prompt =
            generate_prompt(&event, &data, "supervisor", &config, codex(), codex()).unwrap();

        assert_eq!(prompt.target, "supervisor");
        assert!(prompt.text.contains("swift-fox"));
        assert!(prompt.text.contains("task-123"));
        assert!(prompt.text.contains("completed"));
        // Should clarify verification ownership
        assert!(prompt.text.contains("workers close their own tasks"));
        assert!(prompt.text.contains("supervisors close epics"));
        // Response instructions should point to the worker
        assert!(prompt.text.contains("To respond to this message, use:"));
        assert!(prompt.text.contains("target=swift-fox"));
    }

    #[test]
    fn test_worker_idle_with_ready_tasks() {
        let event = DirectorEvent::WorkerIdle {
            worker: "swift-fox".to_string(),
        };
        let data = make_data(3); // 3 ready tasks
        let config = default_config();

        let prompt =
            generate_prompt(&event, &data, "supervisor", &config, codex(), codex()).unwrap();

        assert_eq!(prompt.target, "supervisor");
        assert!(prompt.text.contains("swift-fox"));
        assert!(prompt.text.contains("idle"));
        assert!(prompt.text.contains("3 ready tasks"));
    }

    #[test]
    fn test_worker_idle_no_ready_tasks() {
        let event = DirectorEvent::WorkerIdle {
            worker: "swift-fox".to_string(),
        };
        let data = make_data(0); // No ready tasks
        let config = default_config();

        let prompt =
            generate_prompt(&event, &data, "supervisor", &config, codex(), codex()).unwrap();

        assert_eq!(prompt.target, "supervisor");
        assert!(prompt.text.contains("No ready tasks"));
    }

    #[test]
    fn test_epic_completed_no_prompt() {
        let event = DirectorEvent::EpicCompleted {
            epic_id: "epic-456".to_string(),
        };
        let data = make_data(0);
        let config = default_config();

        let prompt = generate_prompt(&event, &data, "supervisor", &config, codex(), codex());

        assert!(
            prompt.is_none(),
            "EpicCompleted should not generate a prompt"
        );
    }

    #[test]
    fn test_worker_ready_prompt() {
        let event = DirectorEvent::AgentRegistered {
            agent_id: "agent-123".to_string(),
            agent_name: "calm-owl".to_string(),
        };
        let data = make_data(3);
        let config = default_config();

        let prompt =
            generate_prompt(&event, &data, "supervisor", &config, codex(), codex()).unwrap();

        assert_eq!(prompt.target, "supervisor");
        assert!(prompt.text.contains("calm-owl"));
        assert!(prompt.text.contains("ready"));
        assert!(prompt.text.contains("3 ready tasks"));
    }

    #[test]
    fn test_worker_ready_no_tasks() {
        let event = DirectorEvent::AgentRegistered {
            agent_id: "agent-123".to_string(),
            agent_name: "calm-owl".to_string(),
        };
        let data = make_data(0);
        let config = default_config();

        let prompt =
            generate_prompt(&event, &data, "supervisor", &config, codex(), codex()).unwrap();

        assert_eq!(prompt.target, "supervisor");
        assert!(prompt.text.contains("calm-owl"));
        assert!(prompt.text.contains("ready"));
        assert!(prompt.text.contains("No ready tasks"));
    }

    #[test]
    fn test_worker_ready_disabled() {
        let event = DirectorEvent::AgentRegistered {
            agent_id: "agent-123".to_string(),
            agent_name: "calm-owl".to_string(),
        };
        let data = make_data(0);
        let config = AutoPromptConfig {
            on_worker_ready: false,
            ..default_config()
        };

        let prompt = generate_prompt(&event, &data, "supervisor", &config, codex(), codex());
        assert!(prompt.is_none());
    }

    #[test]
    fn test_supervisor_registered_no_prompt() {
        // Supervisor registering should not notify itself
        let event = DirectorEvent::AgentRegistered {
            agent_id: "agent-sup".to_string(),
            agent_name: "supervisor".to_string(),
        };
        let data = make_data(0);
        let config = default_config();

        let prompt = generate_prompt(&event, &data, "supervisor", &config, codex(), codex());
        assert!(prompt.is_none());
    }

    #[test]
    fn test_config_disabled_globally() {
        let event = DirectorEvent::TaskAssigned {
            task_id: "task-123".to_string(),
            task_title: "Implement feature X".to_string(),
            worker: "swift-fox".to_string(),
        };
        let data = make_data(0);
        let config = AutoPromptConfig {
            enabled: false,
            ..default_config()
        };

        let prompt = generate_prompt(&event, &data, "supervisor", &config, codex(), codex());
        assert!(prompt.is_none());
    }



}
