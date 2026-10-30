use crate::entities::Item;
use crate::io::import::Importer;
use crate::probs::bpp::entities::{BPInstance, BPSolution, Bin};
use crate::probs::bpp::io::ext_repr::ExtBPInstance;
use itertools::Itertools;
use rayon::prelude::*;

use anyhow::{Result, ensure};

/// Imports an instance into the library
pub fn import_instance(importer: &Importer, ext_instance: &ExtBPInstance) -> Result<BPInstance> {
    let items = {
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
            "ExtBPInstance must have at least one item with positive demand"
        );

        items
    };

    let bins = {
        let mut bins: Vec<Bin> = ext_instance
            .bins
            .par_iter()
            .map(|ext_bin| {
                let container = importer.import_container(&ext_bin.base)?;
                Ok(Bin::new(container, ext_bin.stock, ext_bin.cost))
            })
            .collect::<Result<Vec<Bin>>>()?;

        bins.sort_by_key(|bin| bin.id);
        bins.retain(|bin| bin.stock > 0);
        ensure!(
            bins.iter().enumerate().all(|(i, bin)| bin.id == i),
            "All bins should have consecutive IDs starting from 0. IDs: {:?}",
            bins.iter().map(|bin| bin.id).sorted().collect_vec()
        );
        ensure!(
            !bins.is_empty(),
            "ExtBPInstance must have at least one bin with positive stock"
        );

        bins
    };

    Ok(BPInstance::new(items, bins))
}

/// Imports a solution into the library.
#[must_use]
pub fn import_solution(_instance: &BPInstance, _ext_solution: &ExtBPInstance) -> BPSolution {
    unimplemented!("not yet implemented")
}
