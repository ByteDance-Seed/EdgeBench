#![allow(clippy::inline_always)]

use std::borrow::Borrow;
use std::ops::{Add, Div, Mul, Sub};

use ordered_float::NotNan;

use crate::geometry::DTransformation;

#[derive(Clone, Debug)]
///The matrix form of [`DTransformation`].
///[read more](https://pages.mtu.edu/~shene/COURSES/cs3621/NOTES/geometry/geo-tran.html)
pub struct Transformation {
    matrix: [[NotNan<f32>; 3]; 3],
}

impl Transformation {
    /// Creates a transformation with no effect.
    #[must_use]
    pub const fn empty() -> Self {
        Self {
            matrix: EMPTY_MATRIX,
        }
    }

    #[must_use]
    pub fn from_translation((tx, ty): (f32, f32)) -> Self {
        Self {
            matrix: transl_m((tx, ty)),
        }
    }

    #[must_use]
    pub fn from_rotation(angle: f32) -> Self {
        Self {
            matrix: rot_m(angle),
        }
    }

    /// Applies a rotation to `self`.
    #[must_use]
    pub fn rotate(mut self, angle: f32) -> Self {
        self.matrix = dot_prod(&rot_m(angle), &self.matrix);
        self
    }

    /// Applies a translation to `self`.
    #[must_use]
    pub fn translate(mut self, (tx, ty): (f32, f32)) -> Self {
        self.matrix = dot_prod(&transl_m((tx, ty)), &self.matrix);
        self
    }

    /// Applies a translation followed by a rotation to `self`.
    #[must_use]
    pub fn rotate_translate(mut self, angle: f32, (tx, ty): (f32, f32)) -> Self {
        self.matrix = dot_prod(&rot_transl_m(angle, (tx, ty)), &self.matrix);
        self
    }

    /// Applies a rotation followed by a translation to `self`.
    #[must_use]
    pub fn translate_rotate(mut self, (tx, ty): (f32, f32), angle: f32) -> Self {
        self.matrix = dot_prod(&transl_rot_m((tx, ty), angle), &self.matrix);
        self
    }

    /// Applies `other` to `self`.
    #[must_use]
    pub fn transform(mut self, other: &Self) -> Self {
        self.matrix = dot_prod(&other.matrix, &self.matrix);
        self
    }

    #[must_use]
    pub fn transform_from_decomposed(self, other: &DTransformation) -> Self {
        self.rotate_translate(other.rotation(), other.translation())
    }

    /// Generates the transformation that undoes the effect of `self`.
    #[must_use]
    pub fn inverse(mut self) -> Self {
        self.matrix = inverse(&self.matrix);
        self
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.matrix == EMPTY_MATRIX
    }

    #[must_use]
    pub fn matrix(&self) -> &[[NotNan<f32>; 3]; 3] {
        &self.matrix
    }

    #[must_use]
    pub fn decompose(&self) -> DTransformation {
        let m = self.matrix();
        let angle = m[1][0].atan2(m[0][0].into_inner());
        let (tx, ty) = (m[0][2].into_inner(), m[1][2].into_inner());
        DTransformation::new(angle, (tx, ty))
    }
}

impl<T> From<T> for Transformation
where
    T: Borrow<DTransformation>,
{
    fn from(dt: T) -> Self {
        let rot = dt.borrow().rotation();
        let transl = dt.borrow().translation();
        Self {
            matrix: rot_transl_m(rot, transl),
        }
    }
}

impl Default for Transformation {
    fn default() -> Self {
        Self::empty()
    }
}

const _0: NotNan<f32> = unsafe { NotNan::new_unchecked(0.0) };
const _1: NotNan<f32> = unsafe { NotNan::new_unchecked(1.0) };

const EMPTY_MATRIX: [[NotNan<f32>; 3]; 3] = [[_1, _0, _0], [_0, _1, _0], [_0, _0, _1]];

fn rot_m(angle: f32) -> [[NotNan<f32>; 3]; 3] {
    let (sin, cos) = angle.sin_cos();
    let cos = NotNan::new(cos).expect("cos is NaN");
    let sin = NotNan::new(sin).expect("sin is NaN");

    [[cos, -sin, _0], [sin, cos, _0], [_0, _0, _1]]
}

fn transl_m((tx, ty): (f32, f32)) -> [[NotNan<f32>; 3]; 3] {
    let h = NotNan::new(tx).expect("tx is NaN");
    let k = NotNan::new(ty).expect("ty is NaN");

    [[_1, _0, h], [_0, _1, k], [_0, _0, _1]]
}

//rotation followed by translation
fn rot_transl_m(angle: f32, (tx, ty): (f32, f32)) -> [[NotNan<f32>; 3]; 3] {
    let (sin, cos) = angle.sin_cos();
    let cos = NotNan::new(cos).expect("cos is NaN");
    let sin = NotNan::new(sin).expect("sin is NaN");
    let h = NotNan::new(tx).expect("tx is NaN");
    let k = NotNan::new(ty).expect("ty is NaN");

    [[cos, -sin, h], [sin, cos, k], [_0, _0, _1]]
}

//translation followed by rotation
fn transl_rot_m((tx, ty): (f32, f32), angle: f32) -> [[NotNan<f32>; 3]; 3] {
    let (sin, cos) = angle.sin_cos();
    let cos = NotNan::new(cos).expect("cos is NaN");
    let sin = NotNan::new(sin).expect("sin is NaN");
    let h = NotNan::new(tx).expect("tx is NaN");
    let k = NotNan::new(ty).expect("ty is NaN");

    [
        [cos, -sin, h * cos - k * sin],
        [sin, cos, h * sin + k * cos],
        [_0, _0, _1],
    ]
}

#[inline(always)]
fn dot_prod<T>(l: &[[T; 3]; 3], r: &[[T; 3]; 3]) -> [[T; 3]; 3]
where
    T: Add<Output = T> + Mul<Output = T> + Copy + Default,
{
    [
        [
            l[0][0] * r[0][0] + l[0][1] * r[1][0] + l[0][2] * r[2][0],
            l[0][0] * r[0][1] + l[0][1] * r[1][1] + l[0][2] * r[2][1],
            l[0][0] * r[0][2] + l[0][1] * r[1][2] + l[0][2] * r[2][2],
        ],
        [
            l[1][0] * r[0][0] + l[1][1] * r[1][0] + l[1][2] * r[2][0],
            l[1][0] * r[0][1] + l[1][1] * r[1][1] + l[1][2] * r[2][1],
            l[1][0] * r[0][2] + l[1][1] * r[1][2] + l[1][2] * r[2][2],
        ],
        [
            l[2][0] * r[0][0] + l[2][1] * r[1][0] + l[2][2] * r[2][0],
            l[2][0] * r[0][1] + l[2][1] * r[1][1] + l[2][2] * r[2][1],
            l[2][0] * r[0][2] + l[2][1] * r[1][2] + l[2][2] * r[2][2],
        ],
    ]
}

#[inline(always)]
fn inverse<T>(m: &[[T; 3]; 3]) -> [[T; 3]; 3]
where
    T: Add<Output = T> + Mul<Output = T> + Sub<Output = T> + Div<Output = T> + Copy,
{
    let det =
        m[0][0] * m[1][1] * m[2][2] + m[0][1] * m[1][2] * m[2][0] + m[0][2] * m[1][0] * m[2][1]
            - m[0][2] * m[1][1] * m[2][0]
            - m[0][1] * m[1][0] * m[2][2]
            - m[0][0] * m[1][2] * m[2][1];

    [
        [
            (m[1][1] * m[2][2] - m[1][2] * m[2][1]) / det,
            (m[0][2] * m[2][1] - m[0][1] * m[2][2]) / det,
            (m[0][1] * m[1][2] - m[0][2] * m[1][1]) / det,
        ],
        [
            (m[1][2] * m[2][0] - m[1][0] * m[2][2]) / det,
            (m[0][0] * m[2][2] - m[0][2] * m[2][0]) / det,
            (m[0][2] * m[1][0] - m[0][0] * m[1][2]) / det,
        ],
        [
            (m[1][0] * m[2][1] - m[1][1] * m[2][0]) / det,
            (m[0][1] * m[2][0] - m[0][0] * m[2][1]) / det,
            (m[0][0] * m[1][1] - m[0][1] * m[1][0]) / det,
        ],
    ]
}
