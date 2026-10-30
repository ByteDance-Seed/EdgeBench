use rand::Rng;
use rand::prelude::Distribution;
use rand::prelude::IndexedRandom;
use rand_distr::Normal;
use rand_distr::Uniform;
use std::f32::consts::PI;

use jagua_rs::entities::Item;
use jagua_rs::geometry::geo_enums::RotationRange;

/// Samples a rotation (radians).
pub trait RotationSampler {
    fn sample(&self, rng: &mut impl Rng) -> f32;
}

/// Samples a rotation from a uniform distribution over a given range or a discrete set of rotations.
pub enum UniformRotDistr {
    Range(Uniform<f32>),
    Discrete(Vec<f32>),
    None,
}

/// Samples a rotation from a normal distribution over a given range or a discrete set of rotations.
/// In case of discrete rotations the mean is always returned.
pub enum NormalRotDistr {
    Range(Normal<f32>),
    Discrete(f32),
    None,
}

impl UniformRotDistr {
    pub fn from_item(item: &Item) -> Self {
        match &item.allowed_rotation {
            RotationRange::None => UniformRotDistr::None,
            RotationRange::Continuous => {
                UniformRotDistr::Range(Uniform::new(0.0, 2.0 * PI).unwrap())
            }
            RotationRange::Discrete(a_o) => UniformRotDistr::Discrete(a_o.clone()),
        }
    }

    pub fn sample(&self, rng: &mut impl Rng) -> f32 {
        match self {
            UniformRotDistr::None => 0.0,
            UniformRotDistr::Range(u) => u.sample(rng),
            UniformRotDistr::Discrete(a_o) => *a_o.choose(rng).unwrap(),
        }
    }
}

impl NormalRotDistr {
    pub fn from_item(item: &Item, r_ref: f32, stddev: f32) -> Self {
        match &item.allowed_rotation {
            RotationRange::None => NormalRotDistr::None,
            RotationRange::Continuous => NormalRotDistr::Range(Normal::new(r_ref, stddev).unwrap()),
            RotationRange::Discrete(_) => NormalRotDistr::Discrete(r_ref),
        }
    }

    pub fn set_mean(&mut self, mean: f32) {
        match self {
            NormalRotDistr::Range(n) => {
                *n = Normal::new(mean, n.std_dev()).unwrap();
            }
            NormalRotDistr::Discrete(_) | NormalRotDistr::None => {}
        }
    }

    pub fn set_stddev(&mut self, stddev: f32) {
        match self {
            NormalRotDistr::Range(n) => {
                *n = Normal::new(n.mean(), stddev).unwrap();
            }
            NormalRotDistr::Discrete(_) | NormalRotDistr::None => {}
        }
    }

    pub fn sample(&self, rng: &mut impl Rng) -> f32 {
        match self {
            NormalRotDistr::None => 0.0,
            NormalRotDistr::Range(n) => n.sample(rng),
            NormalRotDistr::Discrete(r) => *r,
        }
    }
}
