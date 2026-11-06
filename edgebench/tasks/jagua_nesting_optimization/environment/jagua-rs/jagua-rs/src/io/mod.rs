/// External (serializable) representations of the entities within the library.
pub mod ext_repr;

/// All logic for converting external representations into internal ones
pub mod import;

/// All logic for exporting internal representations into external ones
pub mod export;

/// All logic for creating SVG from [`Layout`](crate::entities::Layout)s
pub mod svg;
