use crate::geometry::Transformation;
use crate::geometry::geo_enums::GeoPosition;

/// Trait for types that can detect collisions between `self` and `other` of type `T`.
pub trait CollidesWith<T> {
    fn collides_with(&self, other: &T) -> bool;
}

///  Trait for types that can detect 'almost-collisions' between `self` and `other` of type `T`.
///
/// Due to floating point arithmetic precision, two objects that are very close to each other may have unexpected behavior with
/// the [`CollidesWith`] trait. This trait errors on the side of false positives, so that if two objects are very close to each other,
/// they will be considered as colliding.
pub trait AlmostCollidesWith<T> {
    fn almost_collides_with(&self, other: &T) -> bool;
}

/// Trait for types that can compute the minimum distance between `self` and `other` of type `T`.
pub trait DistanceTo<T> {
    /// Minimum distance between two primitives. Will be 0 in case of a collision.
    fn distance_to(&self, other: &T) -> f32;

    /// Squared version of [`DistanceTo::distance_to`]
    fn sq_distance_to(&self, other: &T) -> f32;
}

/// Trait for types that can compute the minimum distance to separate `self` from `other` of type `T`.
pub trait SeparationDistance<T>: DistanceTo<T> {
    /// In case of a collision between `self` and `other`, returns [`GeoPosition::Interior`] and the minimum distance to separate the two primitives.
    /// Otherwise, returns [`GeoPosition::Exterior`] and the minimum distance between the two primitives. (similar to [`DistanceTo::distance_to`])
    fn separation_distance(&self, other: &T) -> (GeoPosition, f32);

    /// Squared version of [`SeparationDistance::separation_distance`]
    fn sq_separation_distance(&self, other: &T) -> (GeoPosition, f32);
}

/// Trait for types that can modify themselves by a [`Transformation`].
pub trait Transformable: Clone {
    /// Applies a transformation to `self`.
    fn transform(&mut self, t: &Transformation) -> &mut Self;

    /// Applies a transformation to a clone.
    #[must_use]
    fn transform_clone(&self, t: &Transformation) -> Self {
        let mut clone = self.clone();
        clone.transform(t);
        clone
    }
}

/// Trait for types that can modify themselves to a reference object with a [`Transformation`] applied.
///
/// Useful when repeatedly transforming a single object without having to reallocate new memory each time.
pub trait TransformableFrom: Transformable {
    /// Applies a transformation on the reference object and stores the result in `self`.
    fn transform_from(&mut self, reference: &Self, t: &Transformation) -> &mut Self;
}
