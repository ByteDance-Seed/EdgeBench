use itertools::Itertools;
use jagua_rs::collision_detection::CDEConfig;
use jagua_rs::entities::Instance;
use jagua_rs::io::import::Importer;
use jagua_rs::probs::spp;
use jagua_rs::probs::spp::entities::{SPInstance, SPPlacement, SPProblem};
use lbf::config::LBFConfig;
use lbf::io;
use lbf::opt::lbf_spp::LBFOptimizerSP;
use log::info;
use rand::SeedableRng;
use rand::prelude::{IteratorRandom, SmallRng};
use std::path::Path;

pub const SWIM_PATH: &str = "../assets/swim.json";
pub const N_ITEMS_REMOVED: usize = 5;

pub fn create_instance(cde_config: CDEConfig, poly_simpl_tolerance: Option<f32>) -> SPInstance {
    let ext_instance = io::read_spp_instance(Path::new(SWIM_PATH)).unwrap();
    let importer = Importer::new(cde_config, poly_simpl_tolerance, None, None);
    spp::io::import_instance(&importer, &ext_instance).unwrap()
}

/// Creates a Strip Packing Problem, fill the layout using with the LBF Optimizer and removes some items from the layout
/// Returns the problem and the removed items
/// Simulates a common scenario in iterative optimization algorithms: dense packing with a few items removed
pub fn create_lbf_problem(
    instance: SPInstance,
    config: LBFConfig,
    n_items_removed: usize,
) -> (SPProblem, Vec<SPPlacement>) {
    let mut lbf_optimizer =
        LBFOptimizerSP::new(instance.clone(), config, SmallRng::seed_from_u64(0));
    lbf_optimizer.solve();

    let mut problem = lbf_optimizer.problem;

    let mut rng = SmallRng::seed_from_u64(0);
    // Remove some items from the layout
    let placed_items_to_remove = problem
        .layout
        .placed_items
        .iter()
        .map(|(k, _)| k)
        .sample(&mut rng, n_items_removed);

    let p_opts = placed_items_to_remove
        .iter()
        .map(|k| {
            let pi = &problem.layout.placed_items[*k];
            SPPlacement {
                item_id: pi.item_id,
                d_transf: pi.d_transf,
            }
        })
        .collect_vec();

    for pkey in placed_items_to_remove {
        let item_id = problem.layout.placed_items[pkey].item_id;
        problem.remove_item(pkey);
        info!(
            "Removed item: {} with {} edges",
            item_id,
            lbf_optimizer.instance.item(item_id).shape_cd.n_vertices()
        );
    }

    {
        // let draw_options = SvgDrawOptions {
        //     quadtree: true,
        //     surrogate: true,
        //     ..SvgDrawOptions::default()
        // };
        // let svg = layout_to_svg(&problem.layout, &instance, draw_options ,"");
        // io::write_svg(&svg, Path::new("bench_layout.svg")).expect("Failed to save svg");
    }

    (problem, p_opts)
}

pub fn create_base_config() -> LBFConfig {
    LBFConfig::default()
}
