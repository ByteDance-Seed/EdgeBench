use jagua_rs::Instant;

use crate::ITEM_LIMIT;
use crate::config::LBFConfig;
use crate::opt::search::{item_placement_order, search};
use crate::util::assertions::strip_width_is_in_check;
use jagua_rs::collision_detection::hazards::filter::{HazKeyFilter, NoFilter};
use jagua_rs::entities::Instance;
use jagua_rs::probs::spp::entities::{SPInstance, SPPlacement, SPProblem, SPSolution};
use log::info;
use rand::prelude::SmallRng;
use thousands::Separable;

/// Left-Bottom-Fill (LBF) optimizer for Strip Packing problems.
pub struct LBFOptimizerSP {
    pub instance: SPInstance,
    pub problem: SPProblem,
    pub config: LBFConfig,
    /// SmallRng is a fast, non-cryptographic PRNG <https://rust-random.github.io/book/guide-rngs.html>
    pub rng: SmallRng,
    pub sample_counter: usize,
}

impl LBFOptimizerSP {
    pub fn new(instance: SPInstance, config: LBFConfig, rng: SmallRng) -> Self {
        assert!(config.n_samples > 0);
        let problem = SPProblem::new(instance.clone());
        Self {
            instance,
            problem,
            config,
            rng,
            sample_counter: 0,
        }
    }

    pub fn solve(&mut self) -> SPSolution {
        let start = Instant::now();

        'outer: for item_id in item_placement_order(&self.instance) {
            let item = self.instance.item(item_id);
            //place all items of this type
            while self.problem.item_demand_qtys[item_id] > 0 {
                let cde = self.problem.layout.cde();
                let placement = match &item.min_quality {
                    None => search(
                        cde,
                        item,
                        &self.config,
                        &mut self.rng,
                        &mut self.sample_counter,
                        &NoFilter,
                    ),
                    Some(min_quality) => {
                        let filter =
                            HazKeyFilter::from_irrelevant_qzones(*min_quality, &cde.hazards_map);
                        search(
                            cde,
                            item,
                            &self.config,
                            &mut self.rng,
                            &mut self.sample_counter,
                            &filter,
                        )
                    }
                };

                match placement {
                    Some((d_transf, _)) => {
                        self.problem.place_item(SPPlacement {
                            item_id: item.id,
                            d_transf,
                        });
                        info!(
                            "[LBF] placing item {}/{} with id {} at [{}]",
                            self.problem.layout.placed_items.len(),
                            self.instance.total_item_qty(),
                            item.id,
                            d_transf,
                        );
                        #[allow(clippy::absurd_extreme_comparisons)]
                        if self.problem.layout.placed_items.len() >= ITEM_LIMIT {
                            break 'outer;
                        }
                    }
                    None => {
                        // item does not fit anywhere, increase the strip width
                        self.problem
                            .change_strip_width(self.problem.strip.width * 1.1);
                        info!(
                            "[LBF] no placement found, extended strip by 10% to {:.3}",
                            self.problem.strip.width
                        );
                        assert!(
                            strip_width_is_in_check(&self.problem),
                            " strip width is running away, check if all items fit in the height of the strip"
                        )
                    }
                }
            }
        }

        self.problem.fit_strip();
        info!(
            "[LBF] fitted strip width to {:.3}",
            self.problem.strip.width
        );

        let solution = self.problem.save();

        info!(
            "[LBF] optimization finished in {:.3}ms ({} samples)",
            start.elapsed().as_secs_f64() * 1000.0,
            self.sample_counter.separate_with_commas()
        );

        info!(
            "[LBF] solution contains {} items with a density of {:.3}%",
            solution.layout_snapshot.placed_items.len(),
            solution.density(&self.instance) * 100.0
        );
        solution
    }
}
