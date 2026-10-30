/-
Copyright (c) 2024 Michael Rothgang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Michael Rothgang
-/
import Mathlib.Geometry.Manifold.ContMDiff.Defs
import Mathlib.Geometry.Manifold.MFDeriv.Defs
import Mathlib.Geometry.Manifold.Notation

/-! ## Smooth immersions

In this file, we define immersions and prove some of their basic properties.

## Main definitions
* `Immersion I I' f n`: a `C^n` map `f : M → M'` is an immersion iff
its `mfderiv` is injective at each point
* `InjImmersion`: an immersion which is also injective

## Main results


## Implementation notes
The initial design of immersions only assumed injectivity of the differential.
This is not sufficient to ensure immersions are `C^n`:
While mathlib's `mfderiv` has junk value zero when `f` is not differentiable and the zero map is
only injective if `M` has dimension zero (in which case `f` is always `C^n`), this argument only
shows immersions are `MDifferentiable`, not `C^n`.

**NOTE.** This is **not** the correct definition in the infinite-dimensional context,
but in finite dimensions, the general definition is equivalent to the one in this file.

## Tags
manifold, immersion

-/
noncomputable section

open Set Function

open scoped Manifold ContDiff

-- Let `M` be a manifold with corners over the pair `(E, H)`.
-- Let `M'` be a manifold with corners over the pair `(E', H')`.
variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E : Type*} [instE : NormedAddCommGroup E] [instE' : NormedSpace 𝕜 E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H)
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners 𝕜 E' H')
  {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M']

section Definition

/-- A `C^n` immersion `f : M → M` is a `C^n` map whose differential is injective at every point. -/
structure Immersion (f : M → M') (n : WithTop ℕ∞) : Prop where
  contMDiff : CMDiff n f
  diff_injective : ∀ p, Injective (mfderiv% f p)

/-- An injective `C^n` immersion -/
structure InjImmersion (f : M → M') (n : WithTop ℕ∞) : Prop extends Immersion I I' f n where
  injective : Injective f

end Definition
