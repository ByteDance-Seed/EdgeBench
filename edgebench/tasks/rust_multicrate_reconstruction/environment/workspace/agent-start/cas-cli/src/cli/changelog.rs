//! Changelog command.
//!
//! Fetches release notes from a configured release endpoint.

use std::time::Duration;

use anyhow::{Context, bail};
use clap::Args;
use serde::{Deserialize, Serialize};

use crate::cli::Cli;
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;

const REPO_OWNER: &str = "benchmark";
const REPO_NAME: &str = "cas";
const RELEASES_URL: &str = "https://example.invalid/cas/releases";
const RELEASES_PAGE_SIZE: u8 = 50;
const API_TIMEOUT_MS: u64 = 8_000;
const MAX_LIMIT: u8 = 20;

#[derive(Args, Debug, Clone)]
pub struct ChangelogArgs {
    /// Number of releases to show
    #[arg(long, default_value_t = 5, value_parser = clap::value_parser!(u8).range(1..=MAX_LIMIT as i64))]
    pub limit: u8,

    /// Show a specific release by version/tag (e.g. 0.5.6 or v0.5.6)
    #[arg(long)]
    pub version: Option<String>,

    /// Include pre-releases in output
    #[arg(long)]
    pub include_prerelease: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct GitHubRelease {
    tag_name: String,
    name: Option<String>,
    body: Option<String>,
    html_url: String,
    published_at: Option<String>,
    #[serde(default)]
    draft: bool,
    #[serde(default)]
    prerelease: bool,
}

pub fn execute(args: &ChangelogArgs, cli: &Cli) -> anyhow::Result<()> { todo!() }

fn fetch_releases(
    limit: usize,
    include_prerelease: bool,
    current_version: &str,
) -> anyhow::Result<Vec<GitHubRelease>> { todo!() }

fn fetch_release_by_tag(tag: &str, current_version: &str) -> anyhow::Result<GitHubRelease> { todo!() }

fn github_get(url: &str, current_version: &str) -> anyhow::Result<ureq::Response> { todo!() }

fn normalize_tag(version_or_tag: &str) -> String { todo!() }

fn print_release(release: &GitHubRelease, fmt: &mut Formatter) -> std::io::Result<()> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_tag_adds_v_prefix() {
        assert_eq!(normalize_tag("0.5.6"), "v0.5.6");
    }

}
