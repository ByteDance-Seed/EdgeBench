use std::io::{Read, Write};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use cas_store::{EventStore, SqliteEventStore};
use tiny_http::StatusCode;

use crate::bridge::server::http::{
    error_response, parse_bool_query, parse_string_query, parse_u64_query, write_chunked,
    write_chunked_end,
};
use crate::bridge::server::session::{
    allowed_agent_names, build_status_json, cas_root_for_session_with_fallback,
    filter_events_for_session_agents, resolve_session_by_name,
};
use crate::bridge::server::types::{ActivityJson, InboxPollJson, session_json};
use crate::store::open_supervisor_queue_store;

#[derive(Debug)]
struct SseSessionStream {
    cas_root: std::path::PathBuf,
    session: crate::ui::factory::SessionInfo,
    inbox_id: String,
    shutdown: Arc<AtomicBool>,
    poll_ms: u64,
    heartbeat_ms: u64,
    activity_limit: usize,
    inbox_limit: usize,
    status_interval_ms: u64,
    last_activity_id: i64,
    last_status_at: std::time::Instant,
    last_emit_at: std::time::Instant,
    buf: std::io::Cursor<Vec<u8>>,
    done: bool,
}

impl SseSessionStream {
    #[allow(clippy::too_many_arguments)]
    fn new(
        cas_root: std::path::PathBuf,
        session: crate::ui::factory::SessionInfo,
        inbox_id: String,
        shutdown: Arc<AtomicBool>,
        poll_ms: u64,
        heartbeat_ms: u64,
        activity_limit: usize,
        inbox_limit: usize,
        status_interval_ms: u64,
        last_activity_id: i64,
    ) -> Self { todo!() }

    fn push_sse_event(out: &mut Vec<u8>, event: &str, data: &str) { todo!() }

    fn push_heartbeat(out: &mut Vec<u8>) { todo!() }

    fn fill_next(&mut self) -> std::io::Result<()> { todo!() }
}

impl Read for SseSessionStream {
    fn read(&mut self, out_buf: &mut [u8]) -> std::io::Result<usize> { todo!() }
}

pub(crate) fn handle_session_events_sse_request(
    req: tiny_http::Request,
    path: String,
    query: String,
    cors_allow_origin: Option<String>,
    fallback_cas_root: Option<std::path::PathBuf>,
    shutdown: Arc<AtomicBool>,
) { todo!() }
