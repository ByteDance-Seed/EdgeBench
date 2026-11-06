use crate::geometry::DTransformation;
use crate::geometry::geo_traits::Transformable;
use crate::geometry::primitives::{Point, Rect, SPolygon};
use crate::geometry::shape_modification::{
    ShapeModifyConfig, ShapeModifyMode, close_narrow_concavities, offset_shape,
    shape_modification_valid, simplify_shape,
};
use anyhow::Result;

#[derive(Clone, Debug)]
/// A [`SPolygon`] exactly as is defined in the input file
///
/// Also contains all required operations to convert it to a shape that can be used internally.
/// Currently, these are centering and simplification operations, but could be extended in the future.
pub struct OriginalShape {
    pub shape: SPolygon,
    pub pre_transform: DTransformation,
    pub modify_mode: ShapeModifyMode,
    pub modify_config: ShapeModifyConfig,
}

impl OriginalShape {
    pub fn convert_to_internal(&self) -> Result<SPolygon> {
        // Apply the transformation
        let mut internal = self.shape.transform_clone(&self.pre_transform.compose());

        if let Some(offset) = self.modify_config.offset {
            // Offset the shape
            if offset != 0.0 {
                internal = offset_shape(&internal, self.modify_mode, offset)?;
            }
        }
        if let Some(tolerance) = self.modify_config.simplify_tolerance {
            let pre_simplified = internal.clone();
            // Simplify the shape
            internal = simplify_shape(&internal, self.modify_mode, tolerance);
            if let Some(narrow_concavity_cutoff) = self.modify_config.narrow_concavity_cutoff {
                // Close narrow concavities
                internal =
                    close_narrow_concavities(&internal, self.modify_mode, narrow_concavity_cutoff);
                // Do another simplification after closing concavities
                internal = simplify_shape(&internal, self.modify_mode, tolerance / 10.0);
            }
            debug_assert!(shape_modification_valid(
                &pre_simplified,
                &internal,
                self.modify_mode
            ));
        }

        Ok(internal)
    }

    #[must_use]
    pub fn centroid(&self) -> Point {
        self.shape.centroid()
    }

    #[must_use]
    pub fn area(&self) -> f32 {
        self.shape.area
    }

    #[must_use]
    pub fn bbox(&self) -> Rect {
        self.shape.bbox
    }

    #[must_use]
    pub fn diameter(&self) -> f32 {
        self.shape.diameter
    }
}
