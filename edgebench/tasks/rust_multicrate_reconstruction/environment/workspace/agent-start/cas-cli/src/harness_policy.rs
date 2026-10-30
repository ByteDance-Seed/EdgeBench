use std::str::FromStr;

use cas_mux::SupervisorCli;
use cas_types::TaskType;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerificationMode {
    Required,
    Bypassed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct VerificationPolicy {
    pub task_mode: VerificationMode,
    pub epic_mode: VerificationMode,
}

impl VerificationPolicy {
    pub fn task_required(self) -> bool { todo!() }

    pub fn epic_required(self) -> bool { todo!() }
}

pub fn parse_harness(value: &str) -> Option<SupervisorCli> { todo!() }

pub fn worker_harness_from_env() -> SupervisorCli { todo!() }

pub fn supervisor_harness_from_env() -> SupervisorCli { todo!() }

pub fn is_supervisor_from_env() -> bool { todo!() }

pub fn is_worker_from_env() -> bool { todo!() }

/// Factory verification matrix.
///
/// - Subtasks: required only when worker harness supports subagents.
/// - Epics: required only when supervisor harness supports subagents.
pub fn verification_policy(supervisor: SupervisorCli, worker: SupervisorCli) -> VerificationPolicy { todo!() }

pub fn verification_required_for_task_type(task_type: TaskType) -> bool { todo!() }

pub fn is_worker_without_subagents_from_env() -> bool { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn matrix_claude_claude() {
        let p = verification_policy(SupervisorCli::Claude, SupervisorCli::Claude);
        assert!(p.task_required());
        assert!(p.epic_required());
    }

    #[test]
    fn matrix_claude_codex() {
        let p = verification_policy(SupervisorCli::Claude, SupervisorCli::Codex);
        assert!(!p.task_required());
        assert!(p.epic_required());
    }


}
