/-
Copyright (c) 2023 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot
-/

import Mathlib.Algebra.Ring.Subring.Order
import Mathlib.Geometry.Manifold.Algebra.SmoothFunctions
import Mathlib.Geometry.Manifold.MFDeriv.Basic
import Mathlib.Geometry.Manifold.Notation
import Mathlib.Order.Filter.Ring
import Mathlib.Tactic.Cases
import Mathlib.Topology.Germ

/-!
## Germs of smooth functions
under construction: might need further refactoring to be usable!
-/

-- TODO: please confirm authorship and copyright are appropriate

noncomputable section

open Filter Set

open scoped Manifold Topology ContDiff

-- FIXME: move to `Manifold/Algebra/SmoothFunctions`, around line 46
section

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
  {H : Type*} [TopologicalSpace H] {I : ModelWithCorners 𝕜 E H}
  {H' : Type*} [TopologicalSpace H'] {I' : ModelWithCorners 𝕜 E' H'}
  {N : Type*} [TopologicalSpace N] [ChartedSpace H N]
  {E'' : Type*} [NormedAddCommGroup E''] [NormedSpace 𝕜 E''] {H'' : Type*} [TopologicalSpace H'']
  {I'' : ModelWithCorners 𝕜 E'' H''} {N' : Type*} [TopologicalSpace N'] [ChartedSpace H'' N']
  {G : Type*} [CommMonoid G] [TopologicalSpace G] [ChartedSpace H' G] [ContMDiffMul I' ∞ G]

@[to_additive]
theorem SmoothMap.coe_prod {ι : Type*} (f : ι → C^∞⟮I, N; I', G⟯) (s : Finset ι) :
    ⇑(∏ i ∈ s, f i) = ∏ i ∈ s, ⇑(f i) := by
  sorry

end

section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H)
  {H' : Type*} [TopologicalSpace H'] {I' : ModelWithCorners ℝ E' H'}
  {N : Type*} [TopologicalSpace N] [ChartedSpace H N]
  {E'' : Type*} [NormedAddCommGroup E''] [NormedSpace ℝ E'']
  {H'' : Type*} [TopologicalSpace H''] {I'' : ModelWithCorners ℝ E'' H''}
  {N' : Type*} [TopologicalSpace N'] [ChartedSpace H'' N']
  (F : Type*) [NormedAddCommGroup F] [NormedSpace ℝ F] (G : Type*) [AddCommGroup G] [Module ℝ G]

/-- The map `C^∞(N, ℝ) → Germ (𝓝 x) ℝ` as a ring homomorphism. -/
def RingHom.germOfContMDiffMap (x : N) : C^∞⟮I, N; 𝓘(ℝ), ℝ⟯ →+* Germ (𝓝 x) ℝ :=
  RingHom.comp (Germ.coeRingHom _) ContMDiffMap.coeFnRingHom

/-- All germs of smooth functions `N → ℝ` at `x : N`, as a subring of `Germ (𝓝 x) ℝ`. -/
def smoothGerm (x : N) : Subring (Germ (𝓝 x) ℝ) :=
  (RingHom.germOfContMDiffMap I x).range

instance (x : N) : Coe C^∞⟮I, N; 𝓘(ℝ), ℝ⟯ (smoothGerm I x) :=
  ⟨fun f ↦ ⟨(f : N → ℝ), ⟨f, rfl⟩⟩⟩

@[simp]
theorem smoothGerm.coe_coe (f : C^∞⟮I, N; 𝓘(ℝ), ℝ⟯) (x : N) :
    ((f : smoothGerm I x) : (𝓝 x).Germ ℝ) = (f : (𝓝 x).Germ ℝ) := by
  sorry

@[simp]
theorem smoothGerm.coe_sum {ι} (f : ι → C^∞⟮I, N; 𝓘(ℝ), ℝ⟯) (s : Finset ι) (x : N) :
    ((∑ i ∈ s, f i : C^∞⟮I, N; 𝓘(ℝ), ℝ⟯) : smoothGerm I x) = ∑ i ∈ s, (f i : smoothGerm I x) := by
  sorry

@[simp]
theorem smoothGerm.coe_eq_coe (f g : C^∞⟮I, N; 𝓘(ℝ), ℝ⟯) {x : N} (h : ∀ᶠ y in 𝓝 x, f y = g y) :
    (f : smoothGerm I x) = (g : smoothGerm I x) := by
  sorry

example (x : N) : Module (smoothGerm I x) (Germ (𝓝 x) G) := by
  sorry

example (x : N) : Module (Germ (𝓝 x) ℝ) (Germ (𝓝 x) F) := by
  sorry

-- def linear_map.germ_of_cont_mdiff_map (x : N) :
--   C^∞⟮I, N; 𝓘(ℝ, F), F⟯ →ₛₗ[(germ.coe_ring_hom (𝓝 x) : (N → ℝ) →+*
--    germ (𝓝 x) ℝ).comp (pi.const_ring_hom N ℝ)] germ (𝓝 x) F :=
-- sorry -- linear_map.comp (germ.coe_linear_map _) smooth_map.coe_fn_linear_map
/-
def smooth_germ_vec (x : N) : submodule (smooth_germ I x) (germ (𝓝 x) F) :=
-- linear_map.range (linear_map.germ_of_cont_mdiff_map I F x)
{ carrier := {φ : germ (𝓝 x) F | ∃ f : C^∞⟮I, N; 𝓘(ℝ, F), F⟯, φ = (f : N → F)},
  add_mem' := sorry,
  zero_mem' := sorry,
  smul_mem' := sorry }

instance (x : N) : has_coe C^∞⟮I, N; 𝓘(ℝ, F), F⟯ (smooth_germ_vec I F x) :=
⟨λ f, ⟨(f : N → F), ⟨f, rfl⟩⟩⟩

variables {I F}

@[elab_as_eliminator]
lemma smooth_germ_vec.induction_on {x : N} {P : germ (𝓝 x) F → Prop}
  (h : ∀ f : C^∞⟮I, N; 𝓘(ℝ, F), F⟯, P (f : N → F)) :
  ∀ φ ∈ smooth_germ_vec I F x, P φ :=
begin
  rintros _ ⟨f, rfl⟩,
  apply h
end

@[elab_as_eliminator]
lemma smooth_germ.induction_on {x : N} {P : germ (𝓝 x) ℝ → Prop}
  (h : ∀ f : C^∞⟮I, N; 𝓘(ℝ), ℝ⟯, P (f : N → ℝ)) :
  ∀ φ ∈ smooth_germ I x, P φ :=
begin
  rintros _ ⟨f, rfl⟩,
  apply h
end

-- We may also need versions of the above two lemmas for using the coe_to_sort
-- `∀ φ : smooth_germ I x`, maybe even a tactic, but let's wait to see if they are really needed.

lemma convex_smooth_germ_vec (x : N) : convex (smooth_germ I x)
  (smooth_germ_vec I F x : Set $ germ (𝓝 x) F) :=
begin
  refine smooth_germ_vec.induction_on _,
  intros f,
  refine smooth_germ_vec.induction_on _,
  rintros g ⟨_, ⟨b, rfl⟩⟩ ⟨_, ⟨c, rfl⟩⟩ hb hc hbc,
  exact ⟨b • f + c • g, rfl⟩,
end
-/
end

section

variable {ι : Type*}

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {H : Type*}
  [TopologicalSpace H] {I : ModelWithCorners ℝ E H} {M : Type*} [TopologicalSpace M]
  [ChartedSpace H M] [IsManifold I ∞ M] [SigmaCompactSpace M] [T2Space M]

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]

variable {G : Type*} [NormedAddCommGroup G] [NormedSpace ℝ G] {HG : Type*} [TopologicalSpace HG]
  (IG : ModelWithCorners ℝ G HG) {N : Type*} [TopologicalSpace N] [ChartedSpace HG N]
  [IsManifold IG ∞ N]

def smoothGerm.valueOrderRingHom (x : N) : smoothGerm IG x →+*o ℝ :=
  Filter.Germ.valueOrderRingHom.comp <| Subring.orderedSubtype _

def smoothGerm.valueRingHom (x : N) : smoothGerm IG x →+* ℝ :=
  Filter.Germ.valueRingHom.comp <| Subring.subtype _

omit [IsManifold IG ∞ N] in
theorem smoothGerm.valueOrderRingHom_toRingHom (x : N) :
    (smoothGerm.valueOrderRingHom IG x).toRingHom = smoothGerm.valueRingHom IG x := by
  sorry

namespace Filter.Germ

def valueₛₗ {F} [AddCommMonoid F] [Module ℝ F] (x : N) :
    Germ (𝓝 x) F →ₛₗ[smoothGerm.valueRingHom IG x] F :=
  { Filter.Germ.valueAddHom with
    toFun := Filter.Germ.value
    map_smul' := fun φ ψ ↦ (φ : Germ (𝓝 x) ℝ).value_smul ψ }

variable (I)

protected def ContMDiffAt' {x : M} (φ : Germ (𝓝 x) N) (n : WithTop ℕ∞) : Prop :=
  Quotient.liftOn' φ (fun f ↦ CMDiffAt n f x) fun f g h ↦
    propext <| by
      constructor
      all_goals refine fun H ↦ H.congr_of_eventuallyEq ?_
      exacts [h.symm, h]

/-- The predicate selecting germs of `ContMDiffAt` functions.
TODO: merge with the next def that generalizes target space -/
protected nonrec def ContMDiffAt {x : M} (φ : Germ (𝓝 x) F) (n : WithTop ℕ∞) : Prop :=
  φ.ContMDiffAt' I 𝓘(ℝ, F) n

-- currently unused
nonrec def mfderiv {x : M} (φ : Germ (𝓝 x) N) :
    TangentSpace I x →L[ℝ] TangentSpace IG φ.value :=
  @Quotient.hrecOn _ (germSetoid (𝓝 x) N)
    (fun φ : Germ (𝓝 x) N ↦ TangentSpace I x →L[ℝ] TangentSpace IG φ.value) φ
    (fun f ↦ mfderiv% f x) fun _f _g hfg ↦ heq_of_eq (EventuallyEq.mfderiv_eq hfg : _)

variable {I}

omit [FiniteDimensional ℝ E] [IsManifold I ∞ M] [SigmaCompactSpace M] [T2Space M]

end Filter.Germ

end

section

variable {E₁ E₂ F H₁ M₁ H₂ M₂ : Type*}
  [NormedAddCommGroup E₁] [NormedSpace ℝ E₁] [FiniteDimensional ℝ E₁]
  [NormedAddCommGroup E₂] [NormedSpace ℝ E₂] [FiniteDimensional ℝ E₂]
  [NormedAddCommGroup F] [NormedSpace ℝ F]
  [TopologicalSpace H₁] (I₁ : ModelWithCorners ℝ E₁ H₁)
  [TopologicalSpace M₁] [ChartedSpace H₁ M₁] [IsManifold I₁ ∞ M₁]
  [SigmaCompactSpace M₁] [T2Space M₁]
  [TopologicalSpace H₂] (I₂ : ModelWithCorners ℝ E₂ H₂)
  [TopologicalSpace M₂] [ChartedSpace H₂ M₂] [IsManifold I₂ ∞ M₂]

open scoped Filter

open Function

namespace Filter.Germ

-- TODO: generalize the next def?
def ContMDiffAtProd {x : M₁} (φ : Germ (𝓝 x) (M₂ → F)) (n : ℕ∞) : Prop :=
  Quotient.liftOn' φ (fun f ↦ ∀ y : M₂, ContMDiffAt (I₁.prod I₂) 𝓘(ℝ, F) n (uncurry f) (x, y))
    fun f g h ↦ propext <| by
        change {x' | f x' = g x'} ∈ 𝓝 x at h
        constructor
        all_goals
          refine fun H y ↦ (H y).congr_of_eventuallyEq ?_
          clear H
          replace h : {x' | f x' = g x'} ×ˢ (univ : Set M₂) ∈ 𝓝 x ×ˢ 𝓝 y := prod_mem_prod h univ_mem
          rw [← nhds_prod_eq] at h
          apply mem_of_superset h
          rintro ⟨x', y'⟩ ⟨hx' : f x' = g x', -⟩
          simp only [mem_setOf_eq, uncurry_apply_pair]
          apply congr_fun
        exacts [hx'.symm, hx']

/- potential generalization of the above.
note(grunweg): fixed some names for Lean 4, but not the core syntax
def contMDiffAt_comp {x : M₁} (φ : germ (𝓝 x) M₂) (n : ℕ∞)
  (g : M₂ → M₃) (h : M₄ → M₁) : Prop :=
quotient.lift_on' φ (λ f, ∀ y ∈ h⁻¹' {x}, ContMDiffAt I₄ I₃ n (g ∘ f ∘ h) y) (λ f g h, propext begin
  change {x' | f x' = g x'} ∈ 𝓝 x at h,
  split,
  all_goals
  { refine λ H y, (H y).congr_of_eventuallyEq _,
    clear H,
    replace h : {x' | f x' = g x'} ×ˢ (univ : Set M₂) ∈ (𝓝 x) ×ᶠ (𝓝 y) := prod_mem_prod h univ_mem,
    rw ← nhds_prod_eq at h,
    apply mem_of_superset h,
    rintros ⟨x', y'⟩ ⟨(hx' : f x' = g x'), -⟩,
    simp only [mem_setOf_eq, uncurry_apply_pair],
    apply congr_fun, },
  exacts [hx'.symm, hx']
end)
-/
variable {I₁ I₂}

omit [FiniteDimensional ℝ E₁] [FiniteDimensional ℝ E₂] [IsManifold I₁ ∞ M₁]
  [SigmaCompactSpace M₁] [T2Space M₁] [IsManifold I₂ ∞ M₂]

theorem ContMDiffAtProd.smul {x : M₁} {φ : Germ (𝓝 x) <| M₂ → ℝ}
    {ψ : Germ (𝓝 x) <| M₂ → F} {n : ℕ∞} :
    φ.ContMDiffAtProd I₁ I₂ n → ψ.ContMDiffAtProd I₁ I₂ n → (φ • ψ).ContMDiffAtProd I₁ I₂ n := by
  sorry

end Filter.Germ

end
