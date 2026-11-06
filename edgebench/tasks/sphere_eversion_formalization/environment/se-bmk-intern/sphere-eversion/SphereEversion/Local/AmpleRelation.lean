/-
Copyright (c) 2021 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot
-/
import Mathlib.Analysis.Convex.AmpleSet
import SphereEversion.Local.DualPair
import SphereEversion.Local.Relation

/-! # Slices of first order relations

Recal that a first order partial differential relation for maps between real normed vector spaces
`E` and `F` is a set `R` in `OneJet E F := E × F × (E →L[ℝ] F)`. In this file we study slices
of such relations. The word slice is meant to convey the idea of intersecting with an affine
subspace. Here we fix `(x, y, φ) : OneJet E F` and some hyperplane `H` in `E`. The points
`x` and `y` are fixed and we will take a slice in `E →L[ℝ] F` by intersecting `R` with the affine
subspace of linear maps that coincide with `φ` on `H`.

It will be convenient for convex integration purposes to identify this slice with `F`. There is
no natural identification but we can build one by fixing more data that a hyperplane in `E`.
Namely we fix `p : DualPair E` (where `ker p.π` is the relevant hyperplane) and reformulate
"linear map that coincides with `φ` on `H`" as `p.update φ w` for some `w : F`.

This `slice` definition allows to define `RelLoc.isAmple`, the ampleness condition for first
order relations: a relation is ample if all its slices are ample sets.

At the end of the file we consider 1-jet sections and slices corresponding to points in their image.
-/

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
  {X : Type*} [NormedAddCommGroup X] [InnerProductSpace ℝ X]

variable {R : RelLoc E F}

open Set

/-! ## Slices and ampleness -/

namespace RelLoc

/-- The slice of a local relation `R : RelLoc E F` for a dual pair `p` at a jet `θ` is
the set of `w` in `F` such that updating `θ` using `p` and `w` leads to a jet in `R`. -/
def slice (R : RelLoc E F) (p : DualPair E) (θ : E × F × (E →L[ℝ] F)) : Set F :=
  {w | (θ.1, θ.2.1, p.update θ.2.2 w) ∈ R}

theorem mem_slice (R : RelLoc E F) {p : DualPair E} {θ : E × F × (E →L[ℝ] F)} {w : F} :
    w ∈ R.slice p θ ↔ (θ.1, θ.2.1, p.update θ.2.2 w) ∈ R := by
  sorry

/-- A relation is ample if all its slices are ample. -/
def IsAmple (R : RelLoc E F) : Prop :=
  ∀ (p : DualPair E) (θ : E × F × (E →L[ℝ] F)), AmpleSet (R.slice p θ)

open scoped Pointwise

 --h

end RelLoc

open RelLoc

/-! ## Slices for 1-jet sections and formal solutions. -/

namespace JetSec

/-- The slice associated to a jet section and a dual pair at some point. -/
def sliceAt (𝓕 : JetSec E F) (R : RelLoc E F) (p : DualPair E) (x : E) : Set F :=
  R.slice p (x, 𝓕.f x, 𝓕.φ x)

/-- A 1-jet section `𝓕` is short for a dual pair `p` at a point `x` if the derivative of
the function `𝓕.f` at `x` is in the convex hull of the relevant connected component of the
corresponding slice. -/
def IsShortAt (𝓕 : JetSec E F) (R : RelLoc E F) (p : DualPair E) (x : E) : Prop :=
  D 𝓕.f x p.v ∈ hull (connectedComponentIn (𝓕.sliceAt R p x) <| 𝓕.φ x p.v)

end JetSec

namespace RelLoc.FormalSol

/-- The slice associated to a formal solution and a dual pair at some point. -/
def sliceAt (𝓕 : FormalSol R) (p : DualPair E) (x : E) : Set F :=
  R.slice p (x, 𝓕.f x, 𝓕.φ x)

/-- A formal solution `𝓕` is short for a dual pair `p` at a point `x` if the derivative of
the function `𝓕.f` at `x` is in the convex hull of the relevant connected component of the
corresponding slice. -/
def IsShortAt (𝓕 : FormalSol R) (p : DualPair E) (x : E) : Prop :=
  D 𝓕.f x p.v ∈ hull (connectedComponentIn (𝓕.sliceAt p x) <| 𝓕.φ x p.v)

end RelLoc.FormalSol

