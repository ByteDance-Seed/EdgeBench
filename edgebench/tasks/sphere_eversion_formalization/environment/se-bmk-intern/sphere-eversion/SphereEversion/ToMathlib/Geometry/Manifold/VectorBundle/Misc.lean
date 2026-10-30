/-
Copyright (c) 2022 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn

! This file was ported from Lean 3 source module to_mathlib.geometry.manifold.vector_bundle.misc
-/
import Mathlib.Geometry.Manifold.VectorBundle.Basic
import Mathlib.Topology.VectorBundle.Hom

/-!
# Various operations on and properties of smooth vector bundles
-/

noncomputable section

open Bundle Set

namespace FiberBundle

variable {𝕜 B B' F M : Type*} {E : B → Type*}

variable [TopologicalSpace F] [TopologicalSpace (TotalSpace F E)] [∀ x, TopologicalSpace (E x)]
  {HB : Type*} [TopologicalSpace HB] [TopologicalSpace B] [ChartedSpace HB B] [FiberBundle F E]

theorem chartedSpace_chartAt_fst {x y : TotalSpace F E}
    (hy : y.proj ∈ (trivializationAt F E x.proj).baseSet) :
    (chartAt (ModelProd HB F) x y).1 = chartAt HB x.proj y.proj := by
  sorry

end FiberBundle

section VectorBundle

variable {𝕜 B F F₁ F₂ : Type*} {E : B → Type*} {E₁ : B → Type*} {E₂ : B → Type*}
  [NontriviallyNormedField 𝕜] [∀ x, AddCommMonoid (E x)] [∀ x, Module 𝕜 (E x)]
  [NormedAddCommGroup F] [NormedSpace 𝕜 F] [TopologicalSpace (TotalSpace F E)]
  [∀ x, TopologicalSpace (E x)] [∀ x, AddCommMonoid (E₁ x)] [∀ x, Module 𝕜 (E₁ x)]
  [NormedAddCommGroup F₁] [NormedSpace 𝕜 F₁] [TopologicalSpace (TotalSpace F₁ E₁)]
  [∀ x, TopologicalSpace (E₁ x)] [∀ x, AddCommMonoid (E₂ x)] [∀ x, Module 𝕜 (E₂ x)]
  [NormedAddCommGroup F₂] [NormedSpace 𝕜 F₂] [TopologicalSpace (TotalSpace F₂ E₂)]
  [∀ x, TopologicalSpace (E₂ x)] [TopologicalSpace B] {n : ℕ∞} [FiberBundle F₁ E₁]
  [VectorBundle 𝕜 F₁ E₁] [FiberBundle F₂ E₂] [VectorBundle 𝕜 F₂ E₂]
  {e₁ e₁' : Trivialization F₁ (π F₁ E₁)} {e₂ e₂' : Trivialization F₂ (π F₂ E₂)}

end VectorBundle

namespace VectorBundleCore

variable {R 𝕜 B F ι : Type*} [NontriviallyNormedField R] [NormedAddCommGroup F] [NormedSpace R F]
  [TopologicalSpace B] (Z : VectorBundleCore R B F ι)

/-- `Z.coord_change j i` is a partial inverse of `Z.coord_change i j`. -/
theorem coordChange_comp_eq_self {i j : ι} {x : B} (hx : x ∈ Z.baseSet i ∩ Z.baseSet j) (v : F) :
    Z.coordChange j i x (Z.coordChange i j x v) = v := by
  sorry

end VectorBundleCore

namespace Bundle.Trivial

variable {𝕜 B F : Type*}

variable [NontriviallyNormedField 𝕜] [NormedAddCommGroup F] [NormedSpace 𝕜 F] [TopologicalSpace B]

@[simp, mfld_simps]
protected theorem trivializationAt (x : B) :
    trivializationAt F (Trivial B F) x = Trivial.trivialization B F := by
  sorry

end Bundle.Trivial

section Hom

variable {𝕜₁ : Type*} [NontriviallyNormedField 𝕜₁] {𝕜₂ : Type*} [NontriviallyNormedField 𝕜₂]
  (σ : 𝕜₁ →+* 𝕜₂)

variable {B : Type*} [TopologicalSpace B]

variable (F₁ : Type*) [NormedAddCommGroup F₁] [NormedSpace 𝕜₁ F₁] (E₁ : B → Type*)
  [∀ x, AddCommGroup (E₁ x)] [∀ x, Module 𝕜₁ (E₁ x)] [TopologicalSpace (TotalSpace F₁ E₁)]

variable (F₂ : Type*) [NormedAddCommGroup F₂] [NormedSpace 𝕜₂ F₂] (E₂ : B → Type*)
  [∀ x, AddCommGroup (E₂ x)] [∀ x, Module 𝕜₂ (E₂ x)] [TopologicalSpace (TotalSpace F₂ E₂)]

variable [RingHomIsometric σ]

variable [∀ x : B, TopologicalSpace (E₁ x)] [FiberBundle F₁ E₁] [VectorBundle 𝕜₁ F₁ E₁]

variable [∀ x : B, TopologicalSpace (E₂ x)] [FiberBundle F₂ E₂] [VectorBundle 𝕜₂ F₂ E₂]

variable [∀ x, IsTopologicalAddGroup (E₂ x)] [∀ x, ContinuousSMul 𝕜₂ (E₂ x)]

end Hom

section Pullback

/-- We need some instances like this to work with negation on pullbacks -/
instance {B B'} {E : B → Type*} {f : B' → B} {x : B'} [∀ x', AddCommGroup (E x')] :
    AddCommGroup ((f *ᵖ E) x) := by delta Bundle.Pullback; infer_instance

instance {B B'} {E : B → Type*} {f : B' → B} {x : B'} [∀ x', Zero (E x')] : Zero ((f *ᵖ E) x) := by
  delta Bundle.Pullback; infer_instance

variable {B F B' K : Type*} {E : B → Type*} {f : K} [TopologicalSpace B']
  [TopologicalSpace (TotalSpace F E)] [TopologicalSpace F] [TopologicalSpace B] [∀ b, Zero (E b)]
  [FunLike K B' B] [ContinuousMapClass K B' B]

namespace Trivialization

-- attribute [simps base_set] trivialization.pullback

end Trivialization

variable [∀ x, TopologicalSpace (E x)] [FiberBundle F E]

theorem pullback_trivializationAt {x : B'} :
    trivializationAt F (f *ᵖ E) x = (trivializationAt F E (f x)).pullback f := by
  sorry

end Pullback

section PullbackVb

variable {R 𝕜 B F B' : Type*} {E : B → Type*}

variable [TopologicalSpace B'] [TopologicalSpace (TotalSpace F E)] [NontriviallyNormedField 𝕜]
  [NormedAddCommGroup F] [NormedSpace 𝕜 F] [TopologicalSpace B] [∀ x, AddCommMonoid (E x)]
  [∀ x, Module 𝕜 (E x)] [∀ x, TopologicalSpace (E x)] [FiberBundle F E] {K : Type*}
  [FunLike K B' B] [ContinuousMapClass K B' B] (f : K)

namespace Trivialization

end Trivialization

end PullbackVb
