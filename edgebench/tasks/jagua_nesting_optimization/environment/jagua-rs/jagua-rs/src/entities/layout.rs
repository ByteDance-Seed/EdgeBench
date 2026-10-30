use crate::collision_detection::hazards::Hazard;
use crate::collision_detection::{CDESnapshot, CDEngine};
use crate::entities::Item;
use crate::entities::{Container, Instance};
use crate::entities::{PItemKey, PlacedItem};
use crate::geometry::DTransformation;
use crate::util::assertions;
use slotmap::SlotMap;

/// A [`Layout`] is a dynamic representation of items that have been placed in a container at specific positions.
/// Items can be placed and removed. The container can be swapped. Snapshots can be taken and restored to.
/// Each layout maintains a [`CDEngine`], which can be used to check for collisions before placing items.
#[derive(Clone)]
pub struct Layout {
    /// The container used for this layout
    pub container: Container,
    /// All the items that have been placed in this layout, indexed by a unique key
    pub placed_items: SlotMap<PItemKey, PlacedItem>,
    /// The collision detection engine for this layout
    cde: CDEngine,
}

impl Layout {
    #[must_use]
    pub fn new(container: Container) -> Self {
        let cde = container.base_cde.as_ref().clone();
        Layout {
            container,
            placed_items: SlotMap::with_key(),
            cde,
        }
    }

    #[must_use]
    pub fn from_snapshot(ls: &LayoutSnapshot) -> Self {
        let mut layout = Layout::new(ls.container.clone());
        layout.restore(ls);
        layout
    }

    /// Replaces the current container with a new one, rebuilding the collision detection engine accordingly.
    pub fn swap_container(&mut self, container: Container) {
        let cde_snapshot = self.cde.save();
        // rebuild the CDE
        self.container = container;
        self.cde = self.container.base_cde.as_ref().clone();
        for hazard in cde_snapshot.dynamic_hazards {
            // re-register all dynamic hazards from the previous CDE snapshot
            self.cde.register_hazard(hazard);
        }
    }

    /// Saves the current state of the layout to be potentially restored to later.
    #[must_use]
    pub fn save(&self) -> LayoutSnapshot {
        LayoutSnapshot {
            container: self.container.clone(),
            placed_items: self.placed_items.clone(),
            cde_snapshot: self.cde.save(),
        }
    }

    /// Restores the layout to a previous state using a snapshot.
    pub fn restore(&mut self, layout_snapshot: &LayoutSnapshot) {
        assert_eq!(self.container.id, layout_snapshot.container.id);

        self.placed_items.clone_from(&layout_snapshot.placed_items);
        self.cde.restore(&layout_snapshot.cde_snapshot);

        debug_assert!(assertions::layout_qt_matches_fresh_qt(self));
        debug_assert!(assertions::snapshot_matches_layout(self, layout_snapshot));
    }

    /// Places an item in the layout at a specific position by applying a transformation.
    /// Returns the unique key for the placed item.
    pub fn place_item(&mut self, item: &Item, d_transformation: DTransformation) -> PItemKey {
        let pk = self
            .placed_items
            .insert(PlacedItem::new(item, d_transformation));
        let pi = &self.placed_items[pk];
        let hazard = Hazard::new((pk, pi).into(), pi.shape.clone(), true);

        self.cde.register_hazard(hazard);

        debug_assert!(assertions::layout_qt_matches_fresh_qt(self));

        pk
    }

    /// Removes an item from the layout by its unique key and returns the removed [`PlacedItem`].
    pub fn remove_item(&mut self, pk: PItemKey) -> PlacedItem {
        let pi = self
            .placed_items
            .remove(pk)
            .expect("key is not valid anymore");

        // update the collision detection engine
        self.cde.deregister_hazard_by_entity((pk, &pi).into());

        debug_assert!(assertions::layout_qt_matches_fresh_qt(self));

        pi
    }

    /// True if no items are placed
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.placed_items.is_empty()
    }

    /// The current density of the layout defined as the ratio of the area of the items placed to the area of the container.
    /// Uses the original shapes of items and container to calculate the area.
    pub fn density(&self, instance: &impl Instance) -> f32 {
        self.placed_item_area(instance) / self.container.area()
    }

    /// The sum of the areas of the items placed in the layout (using the original shapes of the items).
    pub fn placed_item_area(&self, instance: &impl Instance) -> f32 {
        self.placed_items
            .iter()
            .map(|(_, pi)| instance.item(pi.item_id))
            .map(Item::area)
            .sum::<f32>()
    }

    /// Returns the collision detection engine for this layout
    #[must_use]
    pub fn cde(&self) -> &CDEngine {
        &self.cde
    }

    /// Returns true if all the items are placed without colliding
    #[must_use]
    pub fn is_feasible(&self) -> bool {
        self.placed_items.iter().all(|(pk, pi)| {
            let hkey = self
                .cde
                .haz_key_from_pi_key(pk)
                .expect("all placed items should be registered in the CDE");
            !self.cde.detect_poly_collision(&pi.shape, &hkey)
        })
    }
}

/// Immutable and compact representation of a [`Layout`].
/// Can be used to restore a [`Layout`] back to a previous state.
#[derive(Clone, Debug)]
pub struct LayoutSnapshot {
    /// A copy of the container used in the layout
    pub container: Container,
    /// A copy of the placed items in the layout
    pub placed_items: SlotMap<PItemKey, PlacedItem>,
    /// Snapshot of the collision detection engine
    pub cde_snapshot: CDESnapshot,
}

impl LayoutSnapshot {
    /// Equivalent to [`Layout::density`]
    pub fn density(&self, instance: &impl Instance) -> f32 {
        self.placed_item_area(instance) / self.container.area()
    }

    /// Equivalent to [`Layout::placed_item_area`]
    pub fn placed_item_area(&self, instance: &impl Instance) -> f32 {
        self.placed_items
            .iter()
            .map(|(_, pi)| instance.item(pi.item_id))
            .map(Item::area)
            .sum::<f32>()
    }
}
