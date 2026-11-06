use anyhow::{Context, Result};
use cas_store::{EventStore, SqliteEventStore};
use tiny_http::{Method, Response, StatusCode};

use crate::bridge::server::http::{error_response, json_response, json_response_bytes, url_decode};
use crate::bridge::server::session::{
    allowed_agent_names, cas_root_for_session_with_fallback, filter_events_for_session_agents,
    resolve_session_by_name, wait_for_supervisor_ack,
};
use crate::bridge::server::types::{
    ActivityJson, AgentLatestActivityJson, AgentSummaryJson, InboxAckJson, InboxAckRequest,
    InboxCountJson, InboxPeekJson, InboxPollJson, MessageRequest, MessageResponse, PingJson,
    StatusJson, TargetsJson, TaskSummaryJson, session_json,
};
use crate::store::{open_prompt_queue_store, open_supervisor_queue_store};

pub(crate) fn handle_session_routes(
    req: &mut tiny_http::Request,
    path: &str,
    query: &str,
    cors_allow_origin: Option<&str>,
    fallback_cas_root: Option<&std::path::Path>,
    status_cache: &std::sync::Mutex<
        std::collections::HashMap<String, (std::time::Instant, Vec<u8>)>,
    >,
    status_cache_ttl_ms: u64,
) -> Result<Response<std::io::Cursor<Vec<u8>>>> { todo!() }
