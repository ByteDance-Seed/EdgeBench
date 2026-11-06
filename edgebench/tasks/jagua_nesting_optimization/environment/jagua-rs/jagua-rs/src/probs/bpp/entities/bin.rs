use crate::entities::Container;

#[derive(Debug, Clone)]
/// A container in the Bin Packing Problem (BPP) with an associated cost and stock.
pub struct Bin {
    /// Unique identifier for the bin
    pub id: usize,
    /// The container in which to pack the items
    pub container: Container,
    /// The number of copies of this bin available to be use
    pub stock: usize,
    /// The cost of using a bin of this type
    pub cost: u64,
}

impl Bin {
    /// Creates a new bin with the given id, container, stock, and cost.
    #[must_use]
    pub fn new(container: Container, stock: usize, cost: u64) -> Self {
        Self {
            id: container.id,
            container,
            stock,
            cost,
        }
    }
}
