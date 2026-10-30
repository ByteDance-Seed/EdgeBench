use crate::Instant;
use crate::entities::{Container, Instance, Layout, PItemKey};
use crate::geometry::DTransformation;
use crate::probs::mspp::entities::MSPSolution;
use crate::probs::mspp::entities::instance::MSPInstance;
use crate::probs::mspp::entities::strip::Strip;
use crate::probs::mspp::util::assertions::problem_matches_solution;
use itertools::Itertools;
use slotmap::{SecondaryMap, SlotMap, new_key_type};

new_key_type! {
    /// Unique key for each [`Layout`] in a [`MSPProblem`] and [`MSPSolution`]
    pub struct LayKey;
}

/// Modifiable counterpart of [`MSPInstance`]: items can be placed and removed; layouts can be added, removed, and modified.
#[derive(Clone)]
pub struct MSPProblem {
    /// The underlying instance
    pub instance: MSPInstance,
    /// The layouts in the problem
    pub layouts: SlotMap<LayKey, Layout>,
    /// The strips associated with each layout
    pub strips: SecondaryMap<LayKey, Strip>,
    /// The remaining demand quantities for each item
    pub item_demand_qtys: Vec<usize>,
}

impl MSPProblem {
    #[must_use]
    pub fn new(instance: MSPInstance) -> Self {
        let item_demand_qtys = instance.items.iter().map(|(_, qty)| *qty).collect_vec();

        Self {
            instance,
            layouts: SlotMap::with_key(),
            strips: SecondaryMap::new(),
            item_demand_qtys,
        }
    }

    /// Adds a new layout to the problem based on the given strip.
    /// Returns the key of the newly added layout.
    pub fn add_layout_from_strip(&mut self, strip: Strip) -> LayKey {
        let layout = Layout::new(Container::from(strip));
        let lk = self.register_layout(layout);
        self.strips.insert(lk, strip);
        lk
    }

    /// Removes a layout from the problem. All items placed inside it will be deregistered.
    pub fn remove_layout(&mut self, key: LayKey) {
        self.deregister_layout(key);
    }

    /// Modifies a layout by shrinking its strip to the smallest width that can still contain all placed items.
    pub fn fit_strip(&mut self, lk: LayKey) {
        let feasible_before = self.layouts[lk].is_feasible();

        //Find the rightmost item in the strip and add some tolerance (avoiding false collision positives)
        let item_x_max = self.layouts[lk]
            .placed_items
            .values()
            .map(|pi| pi.shape.bbox.x_max)
            .max_by(|a, b| a.partial_cmp(b).unwrap())
            .unwrap()
            * 1.00001;

        // add the shape offset if any, the strip needs to be at least `offset` wider than the items
        let fitted_width = item_x_max + self.strips[lk].shape_modify_config.offset.unwrap_or(0.0);

        self.change_strip_width(lk, fitted_width);
        debug_assert!(feasible_before == self.layouts[lk].is_feasible());
    }

    /// Places an item according to the given `MSPPlacement` in the problem.
    /// Returns the layout key and the placed item key.
    pub fn place_item(&mut self, placement: MSPPlacement) -> (LayKey, PItemKey) {
        let lk = placement.lk;

        let layout = &mut self.layouts[lk];
        let item = self.instance.item(placement.item_id);
        let pik = layout.place_item(item, placement.d_transf);

        self.register_included_item(placement.item_id);

        (lk, pik)
    }

    /// Removes a placed item from a layout.
    /// Returns the corresponding `MSPPlacement` to place it back.
    pub fn remove_item(&mut self, lk: LayKey, pk: PItemKey) -> MSPPlacement {
        let pi = self.layouts[lk].remove_item(pk);
        self.deregister_included_item(pi.item_id);

        MSPPlacement {
            lk,
            item_id: pi.item_id,
            d_transf: pi.d_transf,
        }
    }

    /// Creates a snapshot of the current state of the problem as a [`MSPSolution`].
    #[must_use]
    pub fn save(&self) -> MSPSolution {
        let solution = MSPSolution {
            layout_snapshots: self.layouts.iter().map(|(lk, l)| (lk, l.save())).collect(),
            strips: self.strips.clone(),
            time_stamp: Instant::now(),
        };

        debug_assert!(problem_matches_solution(self, &solution));

        solution
    }

    /// Restores the state of the problem to the given [`MSPSolution`].
    /// Returns `true` if any keys in the layout map changed (i.e., layouts were added or removed).
    pub fn restore(&mut self, solution: &MSPSolution) -> bool {
        let mut layout_keys_changed = false;
        let mut layouts_to_remove = vec![];

        //Check which layouts from the problem are also present in the solution.
        //If a layout is present we might be able to do a (partial) restore instead of fully rebuilding everything.
        for (lk, layout) in &mut self.layouts {
            match solution.layout_snapshots.get(lk) {
                Some(ls) => {
                    //The key is present in the solution
                    if self.strips[lk] == solution.strips[lk] {
                        //Strips match, do a simple restore
                        layout.restore(ls);
                    } else {
                        //The strip changed, we need to swap the container and then restore
                        self.strips[lk] = solution.strips[lk];
                        layout.swap_container(Container::from(self.strips[lk]));
                        layout.restore(ls);
                    }
                }
                None => {
                    //Layout not present in solution, mark for removal
                    layouts_to_remove.push(lk);
                }
            }
        }

        //Remove all layouts that were not present in the solution (or have a different bin)
        for lk in layouts_to_remove {
            layout_keys_changed = true;
            self.layouts.remove(lk);
            self.strips.remove(lk);
        }

        //Create new layouts for all keys present in solution but not in problem
        for (lk, ls) in &solution.layout_snapshots {
            if !self.layouts.contains_key(lk) {
                layout_keys_changed = true;
                let new_lk = self.layouts.insert(Layout::from_snapshot(ls));
                self.strips.insert(new_lk, solution.strips[lk]);
            }
        }

        //Restore the item demands and strips
        {
            self.item_demand_qtys
                .iter_mut()
                .enumerate()
                .for_each(|(id, demand)| {
                    *demand = self.instance.item_qty(id);
                });
        }

        debug_assert!(problem_matches_solution(self, solution));
        layout_keys_changed
    }

    /// Modifies the width of the strip of the layout.
    /// If the width is non-positive, the layout is removed.
    pub fn change_strip_width(&mut self, lk: LayKey, new_width: f32) {
        assert!(
            new_width > 0.0,
            "Strip width must be positive. Got: {new_width}"
        );
        let strip = &mut self.strips[lk];
        strip.set_width(new_width);
        self.layouts[lk].swap_container(Container::from(*strip));
    }

    fn register_layout(&mut self, layout: Layout) -> LayKey {
        layout
            .placed_items
            .values()
            .for_each(|pi| self.register_included_item(pi.item_id));
        self.layouts.insert(layout)
    }

    fn deregister_layout(&mut self, key: LayKey) {
        let layout = self.layouts.remove(key).expect("layout key not present");
        layout
            .placed_items
            .values()
            .for_each(|pi| self.deregister_included_item(pi.item_id));

        self.strips.remove(key);
    }

    fn register_included_item(&mut self, item_id: usize) {
        self.item_demand_qtys[item_id] -= 1;
    }

    fn deregister_included_item(&mut self, item_id: usize) {
        self.item_demand_qtys[item_id] += 1;
    }

    /// Computes the density of the problem as the ratio between the total area of placed items and the total area of containers.
    #[must_use]
    pub fn density(&self) -> f32 {
        let total_container_area = self.all_layouts().map(|l| l.container.area()).sum::<f32>();

        let total_item_area = self
            .all_layouts()
            .map(|l| l.placed_item_area(&self.instance))
            .sum::<f32>();

        total_item_area / total_container_area
    }

    pub fn all_layouts(&self) -> impl Iterator<Item = &Layout> {
        self.layouts.values()
    }

    /// Returns an iterator over the keys of layouts whose strips are not yet at maximum width.
    pub fn extendable_strips(&self) -> impl Iterator<Item = LayKey> {
        self.strips
            .iter()
            .filter(|(_, s)| s.width < s.max_width)
            .map(|(lk, _)| lk)
    }

    /// Returns the total width of the strips of all the layouts in the problem.
    #[must_use]
    pub fn total_strip_width(&self) -> f32 {
        self.strips.iter().map(|(_, s)| s.width).sum()
    }

    #[must_use]
    pub fn n_placed_items(&self) -> usize {
        self.layouts.values().map(|l| l.placed_items.len()).sum()
    }
}

/// Represents a specific placement of an item in the [`MSPProblem`].
#[derive(Debug, Clone, Copy)]
pub struct MSPPlacement {
    /// Which [`Layout`] to place the item in
    pub lk: LayKey,
    /// The id of the [`Item`](crate::entities::Item) to be placed
    pub item_id: usize,
    /// The transformation to apply to the item when placing it
    pub d_transf: DTransformation,
}
