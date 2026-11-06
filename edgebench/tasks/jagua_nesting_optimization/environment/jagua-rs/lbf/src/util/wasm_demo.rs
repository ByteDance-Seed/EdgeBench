#![cfg(target_arch = "wasm32")]

use rand::SeedableRng;
use wasm_bindgen::prelude::*;
pub use wasm_bindgen_rayon::init_thread_pool;

use crate::EPOCH;
use crate::config::LBFConfig;
use crate::io::output::BPOutput;
use crate::io::output::SPOutput;
use crate::opt::lbf_bpp::LBFOptimizerBP;
use crate::opt::lbf_spp::LBFOptimizerSP;
use console_error_panic_hook;
use jagua_rs::Instant;
use jagua_rs::io::import::Importer;
use jagua_rs::probs::bpp;
use jagua_rs::probs::bpp::io::ext_repr::ExtBPInstance;
use jagua_rs::probs::spp;
use jagua_rs::probs::spp::io::ext_repr::ExtSPInstance;
use log::{info, warn};
use rand::prelude::SmallRng;
use serde::Serialize;
use serde_wasm_bindgen::{from_value, to_value};

#[derive(Serialize)]
struct BPPWasmResult {
    output: BPOutput,
    svgs: Vec<(String, String)>,
    solve_time_ms: u128,
}

#[derive(Serialize)]
struct SPPWasmResult {
    output: SPOutput,
    svgs: Vec<(String, String)>,
    solve_time_ms: u128,
}

#[wasm_bindgen]
pub fn init_logger_wasm() {
    init_logger();
    info!("Logger initialized for WASM!!");
}

#[wasm_bindgen]
pub fn run_lbf_bpp_wasm(
    ext_bp_instance_json: JsValue,
    config_json: JsValue,
) -> Result<JsValue, JsValue> {
    // Deserialize input
    console_error_panic_hook::set_once();

    warn!("BPP Problem selected!!");

    let ext_instance: ExtBPInstance = if ext_bp_instance_json.is_null() {
        web_sys::console::warn_1(&"ExtBPInstance is null, using fallback 'baldacci1.json'!".into());
        let fallback_str = include_str!("../../../assets/baldacci1.json");
        serde_json::from_str(fallback_str).expect("Fallback baldacci1.json is invalid!")
    } else {
        match from_value(ext_bp_instance_json.clone()) {
            Ok(decoded) => decoded,
            Err(e) => {
                web_sys::console::warn_1(
                    &format!("ExtBPInstance decode error: {}, not using fallback!!", e).into(),
                );
                panic!("ExtBPInstance decode failed and fallback not used");
            }
        }
    };

    let config: LBFConfig = from_value(config_json).unwrap_or_else(|e| {
        warn!("Invalid config, using default. Reason: {}", e);
        LBFConfig::default()
    });

    let importer = Importer::new(
        config.cde_config,
        config.poly_simpl_tolerance,
        config.min_item_separation,
        config.narrow_concavity_cutoff,
    );

    let rng = match config.prng_seed {
        Some(seed) => SmallRng::seed_from_u64(seed),
        None => SmallRng::seed_from_u64(0x12345678),
    };

    // Import instance
    let instance = bpp::io::import_instance(&importer, &ext_instance)
        .map_err(|e| JsValue::from_str(&format!("Importer error: {}", e)))?;

    // Solve
    let start_time = Instant::now();
    let sol = LBFOptimizerBP::new(instance.clone(), config, rng).solve();
    let solve_time_ms = start_time.elapsed().as_millis();

    // Export solution
    let output = BPOutput {
        instance: ext_instance.clone(),
        solution: bpp::io::export(&instance, &sol, *EPOCH),
        config,
    };

    // Convert snapshots to SVG strings
    let mut svgs = vec![];
    for (i, s_layout) in sol.layout_snapshots.values().enumerate() {
        let svg =
            jagua_rs::io::svg::s_layout_to_svg(s_layout, &instance, config.svg_draw_options, "");
        let svg_string = svg.to_string();
        svgs.push((format!("sol_input_{}.svg", i), svg_string));
    }

    // Wrap in serializable struct
    let result = BPPWasmResult {
        output,
        svgs,
        solve_time_ms,
    };

    // Serialize and return
    to_value(&result).map_err(|e| JsValue::from_str(&format!("Result encode error: {}", e)))
}

#[wasm_bindgen]
pub fn run_lbf_spp_wasm(
    ext_sp_instance_json: JsValue,
    config_json: JsValue,
) -> Result<JsValue, JsValue> {
    // Deserialize input
    console_error_panic_hook::set_once();

    warn!("SPP Problem selected!!");

    let ext_instance: ExtSPInstance = if ext_sp_instance_json.is_null() {
        web_sys::console::warn_1(&"ExtSPInstance is null, using fallback 'swim.json'!".into());
        let fallback_str = include_str!("../../../assets/swim.json");
        serde_json::from_str(fallback_str).expect("Fallback swim.json is invalid")
    } else {
        match from_value(ext_sp_instance_json.clone()) {
            Ok(decoded) => decoded,
            Err(e) => {
                web_sys::console::warn_1(
                    &format!("ExtSPInstance decode error: {}, not using fallback!!", e).into(),
                );
                panic!("ExtSPInstance decode failed and fallback not used");
            }
        }
    };

    let config: LBFConfig = from_value(config_json).unwrap_or_else(|e| {
        warn!("Invalid config, using default. Reason: {}", e);
        LBFConfig::default()
    });

    let importer = Importer::new(
        config.cde_config,
        config.poly_simpl_tolerance,
        config.min_item_separation,
        config.narrow_concavity_cutoff,
    );

    let rng = match config.prng_seed {
        Some(seed) => SmallRng::seed_from_u64(seed),
        None => SmallRng::seed_from_u64(0x12345678),
    };

    // Import instance
    let instance = spp::io::import_instance(&importer, &ext_instance)
        .map_err(|e| JsValue::from_str(&format!("Importer error: {}", e)))?;

    // Solve
    let start_time = Instant::now();
    let sol = LBFOptimizerSP::new(instance.clone(), config, rng).solve();
    let solve_time_ms = start_time.elapsed().as_millis();

    // Export solution
    let output = SPOutput {
        instance: ext_instance.clone(),
        solution: spp::io::export(&instance, &sol, *EPOCH),
        config,
    };

    let mut svgs = vec![];
    let svg = jagua_rs::io::svg::s_layout_to_svg(
        &sol.layout_snapshot,
        &instance,
        config.svg_draw_options,
        "",
    );
    let svg_string = svg.to_string();
    svgs.push((format!("sol_input_spp.svg"), svg_string));

    // Wrap in serializable struct
    let result = SPPWasmResult {
        output,
        svgs,
        solve_time_ms,
    };

    // Serialize and return
    to_value(&result).map_err(|e| JsValue::from_str(&format!("Result encode error: {}", e)))
}

pub fn init_logger() {
    #[cfg(target_arch = "wasm32")]
    {
        console_log::init_with_level(log::Level::Info).expect("Failed to initialize logger");
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        env_logger::init();
    }
}
