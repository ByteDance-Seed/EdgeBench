use crate::entities::Container;
use crate::entities::Item;
use std::any::Any;

/// The (abstract) static representation of a problem instance.
/// This trait defines shared functionality between any instance variant.
pub trait Instance: Any {
    /// All items
    fn items(&self) -> impl Iterator<Item = &Item>;

    /// All containers
    fn containers(&self) -> impl Iterator<Item = &Container>;

    /// A specific item
    fn item(&self, id: usize) -> &Item;

    /// A specific container
    fn container(&self, id: usize) -> &Container;
}
