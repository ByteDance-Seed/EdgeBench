use serde::Serialize;
use std::io::Write;
use tiny_http::{Header, Response, StatusCode};

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct ErrorBody {
    schema_version: u32,
    error: ErrorInfo,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct ErrorInfo {
    code: String,
    message: String,
}

pub(crate) fn json_response<T: Serialize>(
    status: StatusCode,
    body: &T,
    cors_allow_origin: Option<&str>,
) -> Response<std::io::Cursor<Vec<u8>>> { todo!() }

pub(crate) fn json_response_bytes(
    status: StatusCode,
    body_bytes: Vec<u8>,
    cors_allow_origin: Option<&str>,
) -> Response<std::io::Cursor<Vec<u8>>> { todo!() }

pub(crate) fn error_response(
    status: StatusCode,
    code: &str,
    message: impl Into<String>,
    cors_allow_origin: Option<&str>,
) -> Response<std::io::Cursor<Vec<u8>>> { todo!() }

pub(crate) fn require_auth(
    req: &tiny_http::Request,
    token: Option<&str>,
    no_auth: bool,
) -> std::result::Result<(), &'static str> { todo!() }

pub(crate) fn url_decode(input: &str) -> String { todo!() }

pub(crate) fn parse_u64_query(query: &str, key: &str) -> Option<u64> { todo!() }

pub(crate) fn parse_string_query(query: &str, key: &str) -> Option<String> { todo!() }

pub(crate) fn parse_bool_query(query: &str, key: &str) -> Option<bool> { todo!() }

pub(crate) fn write_chunked<W: Write>(w: &mut W, data: &[u8]) -> std::io::Result<()> { todo!() }

pub(crate) fn write_chunked_end<W: Write>(w: &mut W) -> std::io::Result<()> { todo!() }
