use crate::geometry::DTransformation;
use serde::{Deserialize, Serialize};

/// External representation of an [`Item`](crate::entities::Item).
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtItem {
    /// Unique identifier of the item
    pub id: u64,
    /// List of allowed orientations angles (in degrees).
    /// Continuous rotation if not specified
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allowed_orientations: Option<Vec<f32>>,
    /// Shape of the item
    pub shape: ExtShape,
    /// The minimum required quality of the item.
    /// Maximum quality required if not specified.
    pub min_quality: Option<usize>,
}

/// External representation of a [`Container`](crate::entities::Container).
/// Items can be placed inside containers.
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtContainer {
    /// Unique identifier of the container
    pub id: u64,
    /// Shape of the container
    pub shape: ExtShape,
    /// Zones within the container with varying quality. Holes in the container shape are treated as zones with quality 0.
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub zones: Vec<ExtQualityZone>,
}

/// Various ways to represent a shape
#[derive(Serialize, Deserialize, Clone)]
#[serde(tag = "type", content = "data")]
#[serde(rename_all = "snake_case")]
pub enum ExtShape {
    /// Axis-aligned rectangle. With its left bottom corner at (`x_min`, `y_min`), a width and height
    Rectangle {
        x_min: f32,
        y_min: f32,
        width: f32,
        height: f32,
    },
    /// Polygon with a single outer boundary
    SimplePolygon(ExtSPolygon),
    /// Polygon with a single outer boundary and a set of holes
    Polygon(ExtPolygon),
    /// Multiple disjoint polygons
    MultiPolygon(Vec<ExtPolygon>),
}

/// A polygon represented as an outer boundary and a list of holes
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtPolygon {
    /// The outer boundary of the polygon
    pub outer: ExtSPolygon,
    /// A list of holes in the polygon
    #[serde(default)]
    pub inner: Vec<ExtSPolygon>,
}

/// External representation of a [`SPolygon`](crate::geometry::primitives::SPolygon).
/// A polygon with no holes and no self-intersections.
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtSPolygon(pub Vec<(f32, f32)>);

/// A zone with a specific quality level
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtQualityZone {
    /// The quality level of this zone
    pub quality: usize,
    /// The polygon shape of this zone
    pub shape: ExtShape,
}

/// External representation of a [`Layout`](crate::entities::Layout).
/// A layout consists of a container with items placed in a specific configuration.
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtLayout {
    /// The container that was used
    pub container_id: u64,
    /// The items placed in the container and where they were placed
    pub placed_items: Vec<ExtPlacedItem>,
    /// Some statistics about the layout
    pub density: f32,
}

/// External representation of a [`PlacedItem`](crate::entities::PlacedItem).
/// An item placed in a container with a specific transformation.
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtPlacedItem {
    /// The id of the item in the instance
    pub item_id: u64,
    /// The transformation applied to the item to place it in the container
    pub transformation: ExtTransformation,
}

/// Represents a proper rigid transformation defined as a rotation followed by translation
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtTransformation {
    /// The rotation angle in degrees
    pub rotation: f32,
    /// The translation vector (x, y)
    pub translation: (f32, f32),
}

impl From<DTransformation> for ExtTransformation {
    fn from(dt: DTransformation) -> Self {
        ExtTransformation {
            rotation: dt.rotation().to_degrees(),
            translation: dt.translation(),
        }
    }
}

impl From<ExtTransformation> for DTransformation {
    fn from(ext_dt: ExtTransformation) -> Self {
        DTransformation::new(ext_dt.rotation.to_radians(), ext_dt.translation)
    }
}
