use crate::config::LBFConfig;
use crate::opt::loss::LBFLoss;
use crate::samplers::ls_sampler::LSSampler;
use crate::samplers::uniform_rect_sampler::UniformRectSampler;
use itertools::Itertools;
use jagua_rs::collision_detection::CDEngine;
use jagua_rs::collision_detection::hazards::filter::HazardFilter;
use jagua_rs::entities::{Instance, Item};
use jagua_rs::geometry::DTransformation;
use jagua_rs::geometry::geo_traits::TransformableFrom;
use log::debug;
use ordered_float::OrderedFloat;
use rand::Rng;
use std::cmp::{Ordering, Reverse};

/// Search the layout (i.e. CDE) for a valid placement of the item, with minimal loss.
pub fn search(
    cde: &CDEngine,
    item: &Item,
    config: &LBFConfig,
    rng: &mut impl Rng,
    sample_counter: &mut usize,
    filter: &impl HazardFilter,
) -> Option<(DTransformation, LBFLoss)> {
    let surrogate = item.shape_cd.surrogate();
    //create a clone of the shape which will we can use to apply the transformations
    let mut buffer = {
        let mut buffer = (*item.shape_cd).clone();
        buffer.surrogate = None; //remove the surrogate for faster transforms, we don't need it for the buffer shape
        buffer
    };

    let mut best: Option<(DTransformation, LBFLoss)> = None;

    //calculate the number of uniform and local search samples
    let ls_sample_budget = (config.n_samples as f32 * config.ls_frac) as usize;
    let uni_sample_budget = config.n_samples - ls_sample_budget;

    let mut bin_sampler = UniformRectSampler::new(cde.bbox(), item);

    for i in 0..uni_sample_budget {
        let d_transf = bin_sampler.sample(rng);
        let transf = d_transf.compose();
        if !cde.detect_surrogate_collision(surrogate, &transf, filter) {
            //if no collision is detected on the surrogate, apply the transformation
            buffer.transform_from(&item.shape_cd, &transf);
            let cost = LBFLoss::from_shape(&buffer);

            //only validate the sample if it possibly can replace the current best
            let worth_testing = match (best.as_ref(), &cost) {
                (Some((_, best_cost)), cost) => {
                    cost.partial_cmp(best_cost).unwrap() == Ordering::Less
                }
                (None, _) => true,
            };

            if worth_testing && !cde.detect_poly_collision(&buffer, filter) {
                //sample is valid and improves on the current best
                debug!("[UNI: {i}/{uni_sample_budget}] better: {} ", d_transf);

                best = Some((d_transf, cost));

                let tightened_sampling_bbox = cost.tighten_sample_bbox(bin_sampler.bbox);
                bin_sampler = UniformRectSampler::new(tightened_sampling_bbox, item);
            }
        }
    }

    *sample_counter += uni_sample_budget;

    //if a valid sample was found during the uniform sampling, perform local search around it
    let (best_sample, best_cost) = best.as_mut()?;

    /*
    The local search samples in a normal distribution.
    Throughout the course of the local search, the mean of the distribution is updated to the best found sample.
    And the standard deviation tightens, to focus the search around the best sample.
     */

    let mut ls_sampler = LSSampler::from_defaults(item, *best_sample, cde.bbox());

    for i in 0..ls_sample_budget {
        let d_transf = ls_sampler.sample(rng);
        let transf = d_transf.compose();
        if !cde.detect_surrogate_collision(surrogate, &transf, filter) {
            buffer.transform_from(&item.shape_cd, &transf);
            let cost = LBFLoss::from_shape(&buffer);

            //only validate the sample if it possibly can replace the current best
            let worth_testing = cost < *best_cost;

            if worth_testing && !cde.detect_poly_collision(&buffer, filter) {
                //sample is valid and improves on the current best
                ls_sampler.shift_mean(d_transf);
                debug!("[LS: {i}/{ls_sample_budget}] better: {}", d_transf);
                (*best_sample, *best_cost) = (d_transf, cost);
            }
        }
        let progress_pct = i as f32 / ls_sample_budget as f32;
        ls_sampler.decay_stddev(progress_pct);
    }

    *sample_counter += ls_sampler.n_samples;

    best
}

pub fn item_placement_order(instance: &impl Instance) -> Vec<usize> {
    //sort the items by descending diameter
    instance
        .items()
        .sorted_by_key(|item| Reverse(OrderedFloat(item.shape_cd.diameter)))
        .map(|item| item.id)
        .collect_vec()
}
