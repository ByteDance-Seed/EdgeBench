use std::fs;
use std::fs::File;
use std::io::BufReader;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use clap::Parser as ClapParser;
use jagua_rs::io::import::Importer;
use jagua_rs::io::svg::s_layout_to_svg;
use jagua_rs::probs::bpp::io::ext_repr::ExtBPInstance;
use jagua_rs::probs::spp::io::ext_repr::ExtSPInstance;
use jagua_rs::probs::{bpp, spp};
use lbf::config::LBFConfig;
use lbf::io::cli::{Cli, ProblemVariant};
use lbf::io::output::{BPOutput, SPOutput};
use lbf::io::{read_bpp_instance, read_spp_instance};
use lbf::opt::lbf_bpp::LBFOptimizerBP;
use lbf::opt::lbf_spp::LBFOptimizerSP;
use lbf::{EPOCH, io};
use log::{info, warn};
use rand::SeedableRng;
use rand::prelude::SmallRng;

//more efficient allocator
fn main() -> Result<()> {
    let args = Cli::parse();
    io::init_logger(args.log_level)?;

    let config = match args.config_file {
        None => {
            warn!("[MAIN] No config file provided, use --config-file to provide a custom config");
            LBFConfig::default()
        }
        Some(config_file) => {
            let file = File::open(config_file)?;
            let reader = BufReader::new(file);
            serde_json::from_reader(reader).context("incorrect config file format")?
        }
    };

    info!("Successfully parsed LBFConfig: {config:?}");

    let input_file_stem = args.input_file.file_stem().unwrap().to_str().unwrap();

    if !args.solution_folder.exists() {
        fs::create_dir_all(&args.solution_folder).unwrap_or_else(|_| {
            panic!(
                "could not create solution folder: {:?}",
                args.solution_folder
            )
        });
    }

    match args.prob_var {
        ProblemVariant::BinPackingProblem => {
            let ext_bp_instance = read_bpp_instance(args.input_file.as_path())?;
            main_bpp(
                ext_bp_instance,
                config,
                input_file_stem,
                args.solution_folder,
            )
        }
        ProblemVariant::StripPackingProblem => {
            let ext_sp_instance = read_spp_instance(args.input_file.as_path())?;
            main_spp(
                ext_sp_instance,
                config,
                input_file_stem,
                args.solution_folder,
            )
        }
    }
}

fn main_spp(
    ext_instance: ExtSPInstance,
    config: LBFConfig,
    input_stem: &str,
    output_folder: PathBuf,
) -> Result<()> {
    let importer = Importer::new(
        config.cde_config,
        config.poly_simpl_tolerance,
        config.min_item_separation,
        config.narrow_concavity_cutoff,
    );
    let rng = match config.prng_seed {
        Some(seed) => SmallRng::seed_from_u64(seed),
        None => rand::make_rng(),
    };
    let instance = spp::io::import_instance(&importer, &ext_instance)?;
    let sol = LBFOptimizerSP::new(instance.clone(), config, rng).solve();

    {
        let output = SPOutput {
            instance: ext_instance,
            solution: spp::io::export(&instance, &sol, *EPOCH),
            config,
        };

        let solution_path = output_folder.join(format!("sol_{input_stem}.json"));

        io::write_json(&output, Path::new(&solution_path))?;
    }

    {
        let svg_path = output_folder.join(format!("sol_{input_stem}.svg"));
        let svg = s_layout_to_svg(&sol.layout_snapshot, &instance, config.svg_draw_options, "");

        io::write_svg(&svg, Path::new(&svg_path))?;
    }

    Ok(())
}

fn main_bpp(
    ext_instance: ExtBPInstance,
    config: LBFConfig,
    input_stem: &str,
    output_folder: PathBuf,
) -> Result<()> {
    let importer = Importer::new(
        config.cde_config,
        config.poly_simpl_tolerance,
        config.min_item_separation,
        config.narrow_concavity_cutoff,
    );
    let rng = match config.prng_seed {
        Some(seed) => SmallRng::seed_from_u64(seed),
        None => rand::make_rng(),
    };
    let instance = bpp::io::import_instance(&importer, &ext_instance)?;
    let sol = LBFOptimizerBP::new(instance.clone(), config, rng).solve();

    {
        let output = BPOutput {
            instance: ext_instance,
            solution: bpp::io::export(&instance, &sol, *EPOCH),
            config,
        };

        let solution_path = output_folder.join(format!("sol_{input_stem}.json"));

        io::write_json(&output, Path::new(&solution_path))?;
    }

    {
        for (i, s_layout) in sol.layout_snapshots.values().enumerate() {
            let svg_path = output_folder.join(format!("sol_{input_stem}_{i}.svg"));
            let svg = s_layout_to_svg(s_layout, &instance, config.svg_draw_options, "");

            io::write_svg(&svg, Path::new(&svg_path))?;
        }
    }

    Ok(())
}
