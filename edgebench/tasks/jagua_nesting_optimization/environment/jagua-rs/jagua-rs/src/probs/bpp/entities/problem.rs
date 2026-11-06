use crate::Instant;
use crate::entities::Instance;
use crate::entities::Layout;
use crate::entities::{PItemKey, PlacedItem};
use crate::geometry::DTransformation;
use crate::probs::bpp::entities::BPInstance;
use crate::probs::bpp::entities::BPSolution;
use crate::probs::bpp::util::assertions::problem_matches_solution;
use itertools::Itertools;
use slotmap::{SlotMap, new_key_type};

new_key_type! {
    /// Unique key for each [`Layout`] in a [`BPProblem`] and [`BPSolution`]
    pub struct LayKey;
}

/// Dynamic counterpart of [`BPInstance`].
#[derive(Clone)]
pub struct BPProblem {
    pub instance: BPInstance,
    pub layouts: SlotMap<LayKey, Layout>,
    pub item_demand_qtys: Vec<usize>,
    pub bin_stock_qtys: Vec<usize>,
}

impl BPProblem {
    #[must_use]
    pub fn new(instance: BPInstance) -> Self {
        let item_demand_qtys = instance.items.iter().map(|(_, qty)| *qty).collect_vec();
        let bin_stock_qtys = instance.bins.iter().map(|bin| bin.stock).collect_vec();

        Self {
            instance,
            layouts: SlotMap::with_key(),
            item_demand_qtys,
            bin_stock_qtys,
        }
    }

    /// Removes a layout from the problem. The bin used by the layout will be closed and all items placed inside it will be deregistered.
    pub fn remove_layout(&mut self, key: LayKey) {
        self.deregister_layout(key);
    }

    /// Places an item according to the provided [`BPPlacement`] in the problem.
    pub fn place_item(&mut self, placement: BPPlacement) -> (LayKey, PItemKey) {
        let lkey = match placement.layout_id {
            BPLayoutType::Open(lkey) => lkey,
            BPLayoutType::Closed { bin_id } => {
                //open a new layout
                let bin = &self.instance.bins[bin_id];
                let layout = Layout::new(bin.container.clone());
                self.register_layout(layout)
            }
        };

        let layout = &mut self.layouts[lkey];
        let item = self.instance.item(placement.item_id);
        let pik = layout.place_item(item, placement.d_transf);

        self.register_included_item(placement.item_id);

        (lkey, pik)
    }

    /// Removes an item from a layout. If the layout is empty, it will be closed.
    pub fn remove_item(&mut self, lkey: LayKey, pik: PItemKey) -> BPPlacement {
        let pi = self.layouts[lkey].remove_item(pik);
        self.deregister_included_item(pi.item_id);
        if self.layouts[lkey].is_empty() {
            //if layout is empty, close it
            let bin_id = self.layouts[lkey].container.id;
            self.deregister_layout(lkey);
            BPPlacement::from_placed_item(BPLayoutType::Closed { bin_id }, &pi)
        } else {
            BPPlacement::from_placed_item(BPLayoutType::Open(lkey), &pi)
        }
    }

    /// Creates a snapshot of the current state of the problem as a [`BPSolution`].
    #[must_use]
    pub fn save(&self) -> BPSolution {
        let layout_snapshots = self
            .layouts
            .iter()
            .map(|(lkey, l)| (lkey, l.save()))
            .collect();

        let solution = BPSolution {
            layout_snapshots,
            time_stamp: Instant::now(),
        };

        debug_assert!(problem_matches_solution(self, &solution));

        solution
    }

    /// Restores the state of the problem to the given [`BPSolution`].
    /// Returns `true` if any of the layout keys changed (i.e., layouts were added or removed).
    pub fn restore(&mut self, solution: &BPSolution) -> bool {
        let mut layout_keys_changed = false;
        let mut layouts_to_remove = vec![];

        //Check which layouts from the problem are also present in the solution.
        //If a layout is present we might be able to do a (partial) restore instead of fully rebuilding everything.
        for (lkey, layout) in &mut self.layouts {
            match solution.layout_snapshots.get(lkey) {
                Some(ls) if layout.container.id == ls.container.id => {
                    layout.restore(ls);
                }
                _ => {
                    layouts_to_remove.push(lkey);
                }
            }
        }

        //Remove all layouts that were not present in the solution (or have a different bin)
        for lkey in layouts_to_remove {
            layout_keys_changed = true;
            self.layouts.remove(lkey);
        }

        //Create new layouts for all keys present in solution but not in problem
        for (lkey, ls) in &solution.layout_snapshots {
            if !self.layouts.contains_key(lkey) {
                self.layouts.insert(Layout::from_snapshot(ls));
                layout_keys_changed = true;
            }
        }

        //Restore the item demands and bin stocks
        {
            self.item_demand_qtys
                .iter_mut()
                .enumerate()
                .for_each(|(id, demand)| {
                    *demand = self.instance.item_qty(id);
                });

            self.bin_stock_qtys
                .iter_mut()
                .enumerate()
                .for_each(|(id, stock)| {
                    *stock = self.instance.bin_qty(id);
                });

            self.layouts.values().for_each(|layout| {
                self.bin_stock_qtys[layout.container.id] -= 1;
                layout
                    .placed_items
                    .values()
                    .for_each(|pi| self.item_demand_qtys[pi.item_id] -= 1);
            });
        }

        debug_assert!(problem_matches_solution(self, solution));
        layout_keys_changed
    }

    #[must_use]
    pub fn density(&self) -> f32 {
        let total_bin_area = self
            .layouts
            .values()
            .map(|l| l.container.area())
            .sum::<f32>();

        let total_item_area = self
            .layouts
            .values()
            .map(|l| l.placed_item_area(&self.instance))
            .sum::<f32>();

        total_item_area / total_bin_area
    }

    pub fn item_placed_qtys(&self) -> impl Iterator<Item = usize> {
        self.item_demand_qtys
            .iter()
            .enumerate()
            .map(|(i, demand)| self.instance.item_qty(i) - demand)
    }

    pub fn bin_used_qtys(&self) -> impl Iterator<Item = usize> {
        self.bin_stock_qtys
            .iter()
            .enumerate()
            .map(|(i, stock)| self.instance.bin_qty(i) - stock)
    }

    /// Returns the total cost of all bins used in the solution.
    #[must_use]
    pub fn bin_cost(&self) -> u64 {
        self.bin_used_qtys()
            .enumerate()
            .map(|(id, qty)| self.instance.bins[id].cost * qty as u64)
            .sum()
    }

    fn register_layout(&mut self, layout: Layout) -> LayKey {
        self.open_bin(layout.container.id);
        layout
            .placed_items
            .values()
            .for_each(|pi| self.register_included_item(pi.item_id));
        self.layouts.insert(layout)
    }

    fn deregister_layout(&mut self, key: LayKey) {
        let layout = self.layouts.remove(key).expect("layout key not present");
        self.close_bin(layout.container.id);
        layout
            .placed_items
            .values()
            .for_each(|pi| self.deregister_included_item(pi.item_id));
    }

    fn register_included_item(&mut self, item_id: usize) {
        self.item_demand_qtys[item_id] -= 1;
    }

    fn deregister_included_item(&mut self, item_id: usize) {
        self.item_demand_qtys[item_id] += 1;
    }

    fn open_bin(&mut self, bin_id: usize) {
        self.bin_stock_qtys[bin_id] -= 1;
    }

    fn close_bin(&mut self, bin_id: usize) {
        self.bin_stock_qtys[bin_id] += 1;
    }

    #[must_use]
    pub fn n_placed_items(&self) -> usize {
        self.layouts.values().map(|l| l.placed_items.len()).sum()
    }
}

#[derive(Clone, Debug, Copy)]
/// Encapsulates all required information to place an [`Item`](crate::entities::Item) in a [`BPProblem`].
pub struct BPPlacement {
    /// Which [`Layout`] to place the item in
    pub layout_id: BPLayoutType,
    /// The id of the [`Item`](crate::entities::Item) to be placed
    pub item_id: usize,
    /// The transformation to apply to the item when placing it
    pub d_transf: DTransformation,
}

impl BPPlacement {
    #[must_use]
    pub fn from_placed_item(layout_id: BPLayoutType, placed_item: &PlacedItem) -> Self {
        BPPlacement {
            layout_id,
            item_id: placed_item.item_id,
            d_transf: placed_item.d_transf,
        }
    }
}

/// Enum to distinguish between already existing [`Layout`]s and new ones.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BPLayoutType {
    /// An existing layout, identified by its key
    Open(LayKey),
    /// A layout that does not yet exist, but can be created by 'opening' a new bin
    Closed { bin_id: usize },
}
