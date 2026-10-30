use rmcp::schemars::JsonSchema;
use serde::Deserialize;

#[derive(Debug, Deserialize, JsonSchema)]
pub struct VerificationAddRequest {
    /// Task ID that was verified
    #[schemars(description = "ID of the task that was verified")]
    pub task_id: String,

    /// Verification status
    #[schemars(description = "Status: 'approved', 'rejected', 'error', 'skipped'")]
    pub status: String,

    /// Summary of the verification decision
    #[schemars(description = "Summary explaining the verification decision")]
    pub summary: String,

    /// Confidence score (0.0-1.0)
    #[schemars(description = "Confidence score from 0.0 to 1.0")]
    #[serde(default)]
    pub confidence: Option<f32>,

    /// Issues found during verification (JSON array of issue objects)
    #[schemars(
        description = "JSON array of issues: [{\"file\": \"src/main.rs\", \"line\": 42, \"severity\": \"blocking\", \"category\": \"todo_comment\", \"code\": \"// TODO\", \"problem\": \"Found TODO\", \"suggestion\": \"Implement it\"}]"
    )]
    #[serde(default)]
    pub issues: Option<String>,

    /// Files that were reviewed
    #[schemars(description = "Comma-separated list of files that were reviewed")]
    #[serde(default)]
    pub files_reviewed: Option<String>,

    /// Duration of verification in milliseconds
    #[schemars(description = "How long verification took in milliseconds")]
    #[serde(default)]
    pub duration_ms: Option<u64>,

    /// Verification type: 'task' (default) or 'epic'
    #[schemars(description = "Verification type: 'task' (default) or 'epic'")]
    #[serde(default)]
    pub verification_type: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct VerificationListRequest {
    /// Task ID to list verifications for
    #[schemars(description = "Task ID to list verifications for")]
    pub task_id: String,

    /// Maximum items to return
    #[schemars(description = "Maximum verifications to return (default: 10)")]
    #[serde(default)]
    pub limit: Option<usize>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct VerificationShowRequest {
    /// Verification ID
    #[schemars(description = "ID of the verification to show")]
    pub id: String,
}
