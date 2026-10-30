/-
Copyright (c) 2022 Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Heather Macbeth

! This file was ported from Lean 3 source module to_mathlib.analysis.inner_product_space.rotation
-/
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import SphereEversion.ToMathlib.Analysis.ContDiff
import SphereEversion.ToMathlib.LinearAlgebra.Basic
import SphereEversion.ToMathlib.Analysis.InnerProductSpace.CrossProduct

/-! # Rotation about an axis, considered as a function in that axis -/

noncomputable section

open scoped RealInnerProductSpace

open Module Submodule

set_option synthInstance.checkSynthOrder false
attribute [local instance] FiniteDimensional.of_fact_finrank_eq_succ
set_option synthInstance.checkSynthOrder true

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fact (finrank ℝ E = 3)]
  (ω : Orientation ℝ E (Fin 3))

local infixl:100 "×₃" => ω.crossProduct

namespace Orientation

/-- A family of endomorphisms of `E`, parametrized by `ℝ × E`. The idea is that for nonzero `v : E`
and `t : ℝ` this endomorphism will be the rotation by the angle `t` about the axis spanned by `v`.
-/
def rot (p : ℝ × E) : E →L[ℝ] E :=
  (ℝ ∙ p.2).subtypeL ∘L (orthogonalProjection (ℝ ∙ p.2) : E →L[ℝ] ℝ ∙ p.2) +
      Real.cos (p.1 * Real.pi) •
        (ℝ ∙ p.2)ᗮ.subtypeL ∘L (orthogonalProjection (ℝ ∙ p.2)ᗮ : E →L[ℝ] (ℝ ∙ p.2)ᗮ) +
    Real.sin (p.1 * Real.pi) • LinearMap.toContinuousLinearMap (ω.crossProduct p.2)

/-- Alternative form of the construction `rot`, convenient for the smoothness calculation. -/
def rotAux (p : ℝ × E) : E →L[ℝ] E :=
  Real.cos (p.1 * Real.pi) • ContinuousLinearMap.id ℝ E +
    ((1 - Real.cos (p.1 * Real.pi)) •
        (ℝ ∙ p.2).subtypeL ∘L (orthogonalProjection (ℝ ∙ p.2) : E →L[ℝ] ℝ ∙ p.2) +
      Real.sin (p.1 * Real.pi) • ω.crossProduct' p.2)

/-- The map `rot` is smooth on `ℝ × (E \ {0})`. -/
theorem contDiff_rot {p : ℝ × E} (hp : p.2 ≠ 0) : ContDiffAt ℝ ⊤ ω.rot p := by
  sorry

theorem isometry_rot (t : ℝ) (v : Metric.sphere (0 : E) 1) : Isometry (ω.rot (t, v)) := by
  sorry

open Real Submodule

open scoped Real

set_option linter.style.multiGoal false in
theorem injOn_rot_of_ne (t : ℝ) {x : E} (hx : x ≠ 0) : Set.InjOn (ω.rot (t, x)) (ℝ ∙ x)ᗮ := by
  sorry

theorem injOn_rot (t : ℝ) (x : Metric.sphere (0 : E) 1) :
    Set.InjOn (ω.rot (t, x)) (ℝ ∙ (x : E))ᗮ := by
  sorry

end Orientation
