//! Protocol types for CLI communication.
//!
//! These typed structs replace manual JSON construction for type safety.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// JSON response for permission results sent to CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "behavior", rename_all = "camelCase")]
pub enum PermissionJsonResponse {
    /// Allow the tool execution
    #[serde(rename = "allow")]
    Allow {
        #[serde(rename = "updatedInput")]
        updated_input: Value,
        #[serde(rename = "updatedPermissions", skip_serializing_if = "Option::is_none")]
        updated_permissions: Option<Value>,
    },
    /// Deny the tool execution
    #[serde(rename = "deny")]
    Deny { message: String, interrupt: bool },
}

/// JSON response for hook outputs sent to CLI.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HookJsonResponse {
    /// Whether to continue execution
    #[serde(rename = "continue")]
    pub continue_execution: bool,

    /// Whether to suppress output
    #[serde(rename = "suppressOutput", skip_serializing_if = "is_false")]
    pub suppress_output: bool,

    /// Reason to stop (if stopping)
    #[serde(rename = "stopReason", skip_serializing_if = "Option::is_none")]
    pub stop_reason: Option<String>,

    /// System message to inject
    #[serde(rename = "systemMessage", skip_serializing_if = "Option::is_none")]
    pub system_message: Option<String>,

    /// Generic reason field
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,

    /// Hook-specific output
    #[serde(rename = "hookSpecificOutput")]
    pub hook_specific_output: HookSpecificOutput,
}

/// Hook-specific output section.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HookSpecificOutput {
    /// Event name for this hook
    #[serde(rename = "hookEventName")]
    pub hook_event_name: String,

    /// Permission decision (for PreToolUse hooks)
    #[serde(rename = "permissionDecision", skip_serializing_if = "Option::is_none")]
    pub permission_decision: Option<String>,

    /// Reason for permission decision
    #[serde(
        rename = "permissionDecisionReason",
        skip_serializing_if = "Option::is_none"
    )]
    pub permission_decision_reason: Option<String>,

    /// Updated tool input
    #[serde(rename = "updatedInput", skip_serializing_if = "Option::is_none")]
    pub updated_input: Option<Value>,
}

/// Helper for skip_serializing_if
fn is_false(b: &bool) -> bool {
    !*b
}

impl HookJsonResponse {
    /// Create from HookOutput and event name.
    pub fn from_hook_output(output: &crate::hook::HookOutput, event_name: &str) -> Self {
        Self {
            continue_execution: output.continue_execution,
            suppress_output: output.suppress_output,
            stop_reason: output.stop_reason.clone(),
            system_message: output.system_message.clone(),
            reason: output.reason.clone(),
            hook_specific_output: HookSpecificOutput {
                hook_event_name: event_name.to_string(),
                permission_decision: output.permission_decision.map(|d| d.to_string()),
                permission_decision_reason: output.permission_decision_reason.clone(),
                updated_input: output.updated_input.clone(),
            },
        }
    }
}

impl PermissionJsonResponse {
    /// Create an allow response.
    pub fn allow(updated_input: Value, updated_permissions: Option<Value>) -> Self {
        Self::Allow {
            updated_input,
            updated_permissions,
        }
    }

    /// Create a deny response.
    pub fn deny(message: String, interrupt: bool) -> Self {
        Self::Deny { message, interrupt }
    }
}

#[cfg(test)]
mod tests {
    use crate::protocol::*;
    use serde_json::json;

    #[test]
    fn test_permission_allow_serialization() {
        let response = PermissionJsonResponse::allow(json!({"foo": "bar"}), None);
        let json = serde_json::to_value(&response).unwrap();

        assert_eq!(json["behavior"], "allow");
        assert_eq!(json["updatedInput"]["foo"], "bar");
        assert!(json.get("updatedPermissions").is_none());
    }

    #[test]
    fn test_permission_deny_serialization() {
        let response = PermissionJsonResponse::deny("Not allowed".to_string(), true);
        let json = serde_json::to_value(&response).unwrap();

        assert_eq!(json["behavior"], "deny");
        assert_eq!(json["message"], "Not allowed");
        assert_eq!(json["interrupt"], true);
    }

    #[test]
    fn test_hook_response_serialization() {
        let response = HookJsonResponse {
            continue_execution: true,
            suppress_output: false,
            stop_reason: None,
            system_message: Some("Test message".to_string()),
            reason: None,
            hook_specific_output: HookSpecificOutput {
                hook_event_name: "PreToolUse".to_string(),
                permission_decision: Some("allow".to_string()),
                permission_decision_reason: None,
                updated_input: None,
            },
        };
        let json = serde_json::to_value(&response).unwrap();

        assert_eq!(json["continue"], true);
        assert!(json.get("suppressOutput").is_none()); // skipped because false
        assert_eq!(json["systemMessage"], "Test message");
        assert_eq!(json["hookSpecificOutput"]["hookEventName"], "PreToolUse");
        assert_eq!(json["hookSpecificOutput"]["permissionDecision"], "allow");
    }
}
