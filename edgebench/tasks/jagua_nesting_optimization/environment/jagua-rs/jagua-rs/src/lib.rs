#![warn(
    clippy::pedantic,
    clippy::correctness,
    clippy::suspicious,
    clippy::complexity,
    clippy::perf,
    clippy::style
)]
#![allow(clippy::missing_panics_doc, clippy::missing_errors_doc)]
//!
//! A fast and fearless Collision Detection Engine for 2D irregular cutting and packing problems.
//!
//! This library is designed to be used as a backend by optimization algorithms.

#![doc = document_features::document_features!()]

/// Everything related to the Collision Detection Engine
pub mod collision_detection;

/// Entities to model 2D Irregular Cutting and Packing Problems
pub mod entities;

/// Geometric primitives and base algorithms
pub mod geometry;

/// Importing problem instances into and exporting solutions out of this library
pub mod io;

/// Helper functions which do not belong to any specific module
pub mod util;

/// Enabled variants of the 2D irregular Cutting and Packing Problem.
pub mod probs;

/// Export the `web_time` crate's `Instant` type for compatibility with web environments.
pub type Instant = web_time::Instant;
