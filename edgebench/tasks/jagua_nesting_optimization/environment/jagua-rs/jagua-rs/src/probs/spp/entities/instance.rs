use crate::entities::{Container, Instance, Item};
use crate::probs::spp::entities::Strip;
use crate::probs::spp::util::assertions;
use std::iter;

#[derive(Debug, Clone)]
/// Instance of the Strip Packing Problem.
pub struct SPInstance {
    /// The items to be packed and their demands
    pub items: Vec<(Item, usize)>,
    /// The strip in which to pack the items
    pub base_strip: Strip,
}

impl SPInstance {
    #[must_use]
    pub fn new(items: Vec<(Item, usize)>, base_strip: Strip) -> Self {
        assert!(
            assertions::instance_item_ids_correct(&items),
            "All items should have consecutive IDs starting from 0"
        );

        Self { items, base_strip }
    }

    #[allow(clippy::cast_precision_loss)]
    #[must_use]
    pub fn item_area(&self) -> f32 {
        self.items
            .iter()
            .map(|(item, qty)| item.shape_orig.area() * *qty as f32)
            .sum()
    }

    #[must_use]
    pub fn item_qty(&self, id: usize) -> usize {
        self.items[id].1
    }

    #[must_use]
    pub fn total_item_qty(&self) -> usize {
        self.items.iter().map(|(_, qty)| *qty).sum()
    }
}

impl Instance for SPInstance {
    fn items(&self) -> impl Iterator<Item = &Item> {
        self.items.iter().map(|(item, _qty)| item)
    }

    fn containers(&self) -> impl Iterator<Item = &Container> {
        iter::empty()
    }

    fn item(&self, id: usize) -> &Item {
        &self.items.get(id).unwrap().0
    }

    fn container(&self, _id: usize) -> &Container {
        panic!("no predefined containers for strip packing instances")
    }
}
