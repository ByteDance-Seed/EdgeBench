/// Set of functions to compute and generate [convex hulls](https://en.wikipedia.org/wiki/Convex_hull)
pub mod convex_hull;

mod d_transformation;

/// The *fail-fast surrogate* and all logic pertaining to its generation
pub mod fail_fast;

/// Set of enums representing various geometric properties
pub mod geo_enums;

/// Set of traits representing various geometric properties & operations
pub mod geo_traits;

/// Set of geometric primitives - atomic building blocks for the geometry module
pub mod primitives;
mod transformation;

mod original_shape;

/// Set of function to modify geometric shapes
pub mod shape_modification;

#[doc(inline)]
pub use d_transformation::DTransformation;

#[doc(inline)]
pub use transformation::Transformation;

#[doc(inline)]
pub use original_shape::OriginalShape;

#[doc(inline)]
pub use d_transformation::normalize_rotation;
