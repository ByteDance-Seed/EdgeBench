use anyhow::{Context, Result};

use crate::bridge::server::http::{error_response, json_response};
use crate::bridge::server::types::{StartFactoryRequest, StartFactoryResponse};

pub(crate) fn handle_factory_start(
    start: StartFactoryRequest,
    cors_allow_origin: Option<&str>,
) -> Result<tiny_http::Response<std::io::Cursor<Vec<u8>>>> { todo!() }
