//! Long-lived local helper server for external orchestration tools.
//!
//! This is intended to replace repeated `cas ... --json` subprocess calls with a single
//! long-running process that reads/writes CAS stores directly.

mod factory;
mod http;
mod routes;
mod session;
mod sse;
mod types;

use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use anyhow::{Context, Result};
use tiny_http::{HTTPVersion, Header, Method, Response, Server};

use crate::bridge::server::factory::handle_factory_start;
use crate::bridge::server::http::{error_response, json_response, require_auth, url_decode};
use crate::bridge::server::routes::handle_session_routes;
use crate::bridge::server::sse::handle_session_events_sse_request;
use crate::bridge::server::types::{
    Health, ServeInfo, SessionListJson, StartFactoryRequest, session_json,
};
use crate::cli::bridge::ServeArgs;
use crate::cli::{Cli, ListArgs};

const STATUS_CACHE_TTL_MS: u64 = 250;

pub fn serve(args: &ServeArgs, cli: &Cli) -> Result<()> { todo!() }
