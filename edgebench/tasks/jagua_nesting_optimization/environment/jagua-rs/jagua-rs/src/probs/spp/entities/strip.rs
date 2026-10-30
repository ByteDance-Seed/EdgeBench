use crate::collision_detection::CDEConfig;
use crate::entities::Container;
use crate::geometry::primitives::{Rect, SPolygon};
use crate::geometry::shape_modification::{ShapeModifyConfig, ShapeModifyMode};
use crate::geometry::{DTransformation, OriginalShape};
use anyhow::{Result, ensure};

#[derive(Clone, Debug, Copy, PartialEq)]
/// Represents a rectangular container with fixed height and variable width.
pub struct Strip {
    pub fixed_height: f32,
    pub cde_config: CDEConfig,
    pub shape_modify_config: ShapeModifyConfig,
    pub width: f32,
}

impl Strip {
    pub fn new(
        fixed_height: f32,
        cde_config: CDEConfig,
        shape_modify_config: ShapeModifyConfig,
        width: f32,
    ) -> Result<Self> {
        ensure!(fixed_height > 0.0, "strip height must be positive");
        ensure!(width > 0.0, "strip width must be positive");
        Ok(Strip {
            fixed_height,
            cde_config,
            shape_modify_config,
            width,
        })
    }

    pub fn set_width(&mut self, width: f32) {
        assert!(width > 0.0, "strip width must be positive");
        self.width = width;
    }
}

impl From<Strip> for Container {
    fn from(s: Strip) -> Container {
        let id = s.width.to_bits() as usize;
        Container::new(
            id,
            OriginalShape {
                shape: SPolygon::from(Rect::try_new(0.0, 0.0, s.width, s.fixed_height).unwrap()),
                pre_transform: DTransformation::empty(),
                modify_mode: ShapeModifyMode::Deflate,
                modify_config: s.shape_modify_config,
            },
            vec![],
            s.cde_config,
        )
        .unwrap()
    }
}
