use std::borrow::Borrow;
use std::f32::consts::PI;
use std::fmt::Display;

use crate::geometry::Transformation;
use ordered_float::NotNan;

#[derive(Clone, Debug, PartialEq, Eq, Hash, Copy, Default)]
/// [Proper rigid transformation](https://en.wikipedia.org/wiki/Rigid_transformation),
/// decomposed into a rotation followed by a translation.
pub struct DTransformation {
    /// The rotation in radians
    pub rotation: NotNan<f32>,
    /// The translation in the x and y-axis
    pub translation: (NotNan<f32>, NotNan<f32>),
}

impl DTransformation {
    #[must_use]
    pub fn new(rotation: f32, translation: (f32, f32)) -> Self {
        Self {
            rotation: NotNan::new(rotation).expect("rotation is NaN"),
            translation: (
                NotNan::new(translation.0).expect("translation.0 is NaN"),
                NotNan::new(translation.1).expect("translation.1 is NaN"),
            ),
        }
    }

    #[must_use]
    pub const fn empty() -> Self {
        const _0: NotNan<f32> = unsafe { NotNan::new_unchecked(0.0) };
        Self {
            rotation: _0,
            translation: (_0, _0),
        }
    }

    #[must_use]
    pub fn rotation(&self) -> f32 {
        self.rotation.into()
    }

    #[must_use]
    pub fn translation(&self) -> (f32, f32) {
        (self.translation.0.into(), self.translation.1.into())
    }

    #[must_use]
    pub fn compose(&self) -> Transformation {
        self.into()
    }
}

impl<T> From<T> for DTransformation
where
    T: Borrow<Transformation>,
{
    fn from(t: T) -> Self {
        t.borrow().decompose()
    }
}

impl Display for DTransformation {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "r: {:.3}°, t: ({:.3}, {:.3})",
            self.rotation.to_degrees(),
            self.translation.0.into_inner(),
            self.translation.1.into_inner()
        )
    }
}

/// Normalizes a rotation angle to the range [0, 2π).
#[must_use]
pub fn normalize_rotation(r: f32) -> f32 {
    let normalized = r % (2.0 * PI);
    if normalized < 0.0 {
        normalized + 2.0 * PI
    } else {
        normalized
    }
}
