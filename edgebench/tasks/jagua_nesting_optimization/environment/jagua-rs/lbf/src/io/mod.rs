use std::fs;
use std::fs::File;
use std::io::{BufReader, BufWriter};
use std::path::Path;

use crate::EPOCH;
use log::{Level, LevelFilter, info, log};
use serde::Serialize;
use svg::Document;

use anyhow::{Context, Result};
use jagua_rs::probs::bpp::io::ext_repr::ExtBPInstance;
use jagua_rs::probs::spp::io::ext_repr::ExtSPInstance;

pub mod cli;
pub mod output;

pub fn read_spp_instance(path: &Path) -> Result<ExtSPInstance> {
    let file = File::open(path).context("could not open instance file")?;
    serde_json::from_reader(BufReader::new(file))
        .context("not a valid strip packing instance (ExtSPInstance)")
}

pub fn read_bpp_instance(path: &Path) -> Result<ExtBPInstance> {
    let file = File::open(path).context("could not open instance file")?;
    serde_json::from_reader(BufReader::new(file))
        .context("not a valid bin packing instance (ExtBPInstance)")
}

pub fn write_json(json: &impl Serialize, path: &Path) -> Result<()> {
    let file = File::create(path)?;
    let writer = BufWriter::new(file);

    serde_json::to_writer_pretty(writer, &json)?;

    info!(
        "Solution JSON written to file://{}",
        fs::canonicalize(path)?.to_str().unwrap()
    );
    Ok(())
}

pub fn write_svg(document: &Document, path: &Path) -> Result<()> {
    svg::save(path, document)?;
    info!(
        "Solution SVG written to file://{}",
        fs::canonicalize(path)
            .expect("could not canonicalize path")
            .to_str()
            .unwrap()
    );
    Ok(())
}

pub fn init_logger(level_filter: LevelFilter) -> Result<()> {
    fern::Dispatch::new()
        // Perform allocation-free log formatting
        .format(|out, message, record| {
            let handle = std::thread::current();
            let thread_name = handle.name().unwrap_or("-");

            let duration = EPOCH.elapsed();
            let sec = duration.as_secs() % 60;
            let min = (duration.as_secs() / 60) % 60;
            let hours = (duration.as_secs() / 60) / 60;

            let prefix = format!(
                "[{}] [{:0>2}:{:0>2}:{:0>2}] <{}>",
                record.level(),
                hours,
                min,
                sec,
                thread_name,
            );

            out.finish(format_args!("{prefix:<27}{message}"))
        })
        // Add blanket level filter
        .level(level_filter)
        .chain(std::io::stdout())
        .apply()?;
    log!(Level::Info, "Epoch: {}", jiff::Timestamp::now());
    Ok(())
}
