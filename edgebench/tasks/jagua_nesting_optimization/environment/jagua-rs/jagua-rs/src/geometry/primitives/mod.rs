#![allow(clippy::inline_always)]

mod circle;
mod edge;
mod point;
mod rect;
mod simple_polygon;

#[doc(inline)]
pub use circle::Circle;
#[doc(inline)]
pub use edge::Edge;
#[doc(inline)]
pub use point::Point;
#[doc(inline)]
pub use rect::Rect;
#[doc(inline)]
pub use simple_polygon::SPolygon;
