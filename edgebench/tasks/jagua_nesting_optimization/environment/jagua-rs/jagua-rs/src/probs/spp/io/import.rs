use crate::entities::{Instance, Item};
use crate::geometry::DTransformation;
use crate::geometry::shape_modification::ShapeModifyConfig;
use crate::io::import::{Importer, ext_to_int_transformation};
use crate::probs::spp::entities::{SPInstance, SPPlacement, SPProblem, SPSolution, Strip};
use crate::probs::spp::io::ext_repr::{ExtSPInstance, ExtSPSolution};
use anyhow::{Result, ensure};
use itertools::Itertools;
use rayon::prelude::*;

/// Imports an instance into the library
#[allow(clippy::cast_precision_loss)]
pub fn import_instance(importer: &Importer, ext_instance: &ExtSPInstance) -> Result<SPInstance> {
    let items: Vec<(Item, usize)> = {
        let mut items = ext_instance
            .items
            .par_iter()
            .map(|ext_item| {
                let item = importer.import_item(&ext_item.base)?;
                let demand = usize::try_from(ext_item.demand).unwrap();
                Ok((item, demand))
            })
            .collect::<Result<Vec<(Item, usize)>>>()?;

        items.sort_by_key(|(item, _)| item.id);
        items.retain(|(_, demand)| *demand > 0);

        ensure!(
            items.iter().enumerate().all(|(i, (item, _))| item.id == i),
            "All items should have consecutive IDs starting from 0. IDs: {:?}",
            items.iter().map(|(item, _)| item.id).sorted().collect_vec()
        );
        ensure!(
            !items.is_empty(),
            "ExtSPInstance must have at least one item with positive demand"
        );

        items
    };

    let total_item_area = items
        .iter()
        .map(|(item, demand)| item.area() * *demand as f32)
        .sum::<f32>();

    let fixed_height = ext_instance.strip_height;

    // Initialize the base width for 100% density
    let width = total_item_area / fixed_height;

    let base_strip = Strip::new(
        fixed_height,
        importer.cde_config,
        ShapeModifyConfig {
            offset: importer.shape_modify_config.offset,
            simplify_tolerance: None,
            narrow_concavity_cutoff: None,
        },
        width,
    )?;

    Ok(SPInstance::new(items, base_strip))
}

/// Imports a solution into the library.
#[must_use]
pub fn import_solution(instance: &SPInstance, ext_solution: &ExtSPSolution) -> SPSolution {
    let mut prob = SPProblem::new(instance.clone());
    prob.change_strip_width(ext_solution.strip_width);

    for ext_placement in ext_solution.layout.placed_items.iter().cloned() {
        let item_id = usize::try_from(ext_placement.item_id).unwrap();
        let d_transf = {
            let ext_transf = DTransformation::from(ext_placement.transformation);
            let item = &instance.item(item_id);
            ext_to_int_transformation(&ext_transf, &item.shape_orig.pre_transform)
        };
        prob.place_item(SPPlacement { item_id, d_transf });
    }

    prob.save()
}
