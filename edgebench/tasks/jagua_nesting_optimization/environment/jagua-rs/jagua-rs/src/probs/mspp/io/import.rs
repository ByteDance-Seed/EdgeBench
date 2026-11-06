use crate::entities::Item;
use crate::geometry::shape_modification::ShapeModifyConfig;
use crate::io::import::Importer;
use crate::probs::mspp::entities::{MSPInstance, MSPSolution, Strip};
use crate::probs::mspp::io::ext_repr::ExtMSPInstance;
use anyhow::{Result, ensure};
use itertools::Itertools;
use rayon::prelude::*;

/// Imports an instance into the library
pub fn import_instance(importer: &Importer, ext_instance: &ExtMSPInstance) -> Result<MSPInstance> {
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

    let ext_strip = &ext_instance.strips;

    let base_strip = Strip::new(
        ext_strip.max_width,
        ext_strip.height,
        importer.cde_config,
        ShapeModifyConfig {
            offset: importer.shape_modify_config.offset,
            simplify_tolerance: None,
            narrow_concavity_cutoff: None,
        },
        ext_strip.max_width,
    )?;

    Ok(MSPInstance::new(items, base_strip))
}

/// Imports a solution into the library.
#[must_use]
pub fn import_solution(_instance: &MSPInstance, _ext_solution: &ExtMSPInstance) -> MSPSolution {
    unimplemented!("not yet implemented")
}
