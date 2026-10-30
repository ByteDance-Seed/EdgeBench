use jagua_rs::collision_detection::CDEConfig;
use jagua_rs::geometry::fail_fast::SPSurrogateConfig;
use jagua_rs::io::svg::SvgDrawOptions;
use serde::{Deserialize, Serialize};

/// Configuration for the LBF optimizer
#[derive(Debug, Serialize, Deserialize, Clone, Copy)]
#[serde(default)]
pub struct LBFConfig {
    /// Configuration of the Collision Detection Engine
    pub cde_config: CDEConfig,
    /// Max deviation from the original polygon area as a fraction. If undefined, the algorithm will run without simplification
    pub poly_simpl_tolerance: Option<f32>,
    /// Definition of what is considered a narrow concavity that will be closed
    /// See [`jagua_rs::geometry::shape_modification::ShapeModifyConfig`] for more details.
    /// If undefined, the algorithm will run without closing narrow concavities
    pub narrow_concavity_cutoff: Option<(f32, f32)>,
    /// Minimum distance between items and other hazards.
    /// If undefined, the algorithm will run without this constraint
    pub min_item_separation: Option<f32>,
    /// Seed for the PRNG. If undefined, the algorithm will run in non-deterministic mode using entropy
    pub prng_seed: Option<u64>,
    /// Total budget of samples per item per layout
    pub n_samples: usize,
    /// Fraction of `n_samples_per_item` used for the local search sampler, the rest is sampled uniformly.
    pub ls_frac: f32,
    /// Optional SVG drawing options
    pub svg_draw_options: SvgDrawOptions,
}

impl Default for LBFConfig {
    fn default() -> Self {
        Self {
            cde_config: CDEConfig {
                quadtree_depth: 5,
                cd_threshold: 16,
                item_surrogate_config: SPSurrogateConfig {
                    n_pole_limits: [(100, 0.0), (20, 0.75), (10, 0.90)],
                    n_ff_poles: 2,
                    n_ff_piers: 0,
                },
            },
            poly_simpl_tolerance: Some(0.001),
            narrow_concavity_cutoff: Some((0.01, 0.01)),
            min_item_separation: None,
            prng_seed: None,
            n_samples: 5000,
            ls_frac: 0.2,
            svg_draw_options: SvgDrawOptions::default(),
        }
    }
}
