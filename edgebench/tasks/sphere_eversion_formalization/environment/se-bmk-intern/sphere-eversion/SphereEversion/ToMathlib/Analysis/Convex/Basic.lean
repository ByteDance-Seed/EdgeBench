import Mathlib.Analysis.Convex.Combination
import Mathlib.Algebra.Module.BigOperators
import Mathlib.Algebra.Order.Hom.Ring

open Function Set

section

variable {𝕜 𝕜' E E₂ E' : Type*} [Semiring 𝕜] [PartialOrder 𝕜] --[IsOrderedRing 𝕜]
  [AddCommMonoid E] [Module 𝕜 E] [AddCommMonoid E₂] [Module 𝕜 E₂] [AddCommMonoid E']
  [Semiring 𝕜'] [PartialOrder 𝕜'] [IsOrderedRing 𝕜'] [Module 𝕜' E'] (σ : 𝕜 →+*o 𝕜')

def reallyConvexHull (𝕜 : Type*) {E : Type*}
    [Semiring 𝕜] [PartialOrder 𝕜] [AddCommMonoid E] [SMul 𝕜 E]
    (s : Set E) : Set E :=
  {e | ∃ w : E → 𝕜, 0 ≤ w ∧ support w ⊆ s ∧ ∑ᶠ x, w x = 1 ∧ e = ∑ᶠ x, w x • x}

-- https://xkcd.com/927/

-- rename: `mul_support_finite_of_finprod_ne_one`?
@[to_additive]
theorem finite_of_finprod_ne_one {M : Type*} {ι : Sort _} [CommMonoid M] {f : ι → M}
    (h : ∏ᶠ i, f i ≠ 1) : (mulSupport f).Finite := by
  sorry

theorem support_finite_of_finsum_eq_of_neZero {M : Type*} {ι : Sort _} [AddCommMonoid M]
    {f : ι → M} {x : M} [NeZero x] (h : ∑ᶠ i, f i = x) : (support f).Finite := by
  sorry

theorem sum_mem_reallyConvexHull [IsOrderedRing 𝕜]
    {s : Set E} {ι : Type*} {t : Finset ι} {w : ι → 𝕜} {z : ι → E}
    (h₀ : ∀ i ∈ t, 0 ≤ w i) (h₁ : ∑ i ∈ t, w i = 1) (hz : ∀ i ∈ t, z i ∈ s) :
    ∑ i ∈ t, w i • z i ∈ reallyConvexHull 𝕜 s := by
  sorry

/-- Generalization of `Convex` to semirings. We only add the `s = ∅` clause if `𝕜` is trivial. -/
def ReallyConvex (𝕜 : Type*) {E : Type*} [Semiring 𝕜] [PartialOrder 𝕜]
    [AddCommMonoid E] [Module 𝕜 E] (s : Set E) : Prop :=
  s = ∅ ∨ ∀ w : E → 𝕜, 0 ≤ w → support w ⊆ s → ∑ᶠ x, w x = 1 → ∑ᶠ x, w x • x ∈ s

variable {s : Set E}

@[simp]
theorem reallyConvex_empty : ReallyConvex 𝕜 (∅ : Set E) := by
  sorry

@[simp]
theorem reallyConvex_univ : ReallyConvex 𝕜 (univ : Set E) := by
  sorry

-- for every lemma that requires `Nontrivial` should we also add a lemma that has the condition
-- `s.Nonempty` (or even `Nontrivial 𝕜 ∨ s.Nonempty`)?

theorem Subsingleton.reallyConvex [Subsingleton 𝕜] : ReallyConvex 𝕜 s := by
  sorry

theorem reallyConvex_iff_hull [Nontrivial 𝕜] : ReallyConvex 𝕜 s ↔ reallyConvexHull 𝕜 s ⊆ s := by
  sorry

-- turn this into an iff

theorem ReallyConvex.preimage [IsOrderedRing 𝕜]
    (f : E →ₗ[𝕜] E₂) {s : Set E₂} (hs : ReallyConvex 𝕜 s) :
    ReallyConvex 𝕜 (f ⁻¹' s) := by
  sorry

/-  The next lemma would also be nice to have.
lemma reallyConvex_reallyConvexHull (s : Set E) : reallyConvex 𝕜 (reallyConvexHull 𝕜 s) := sorry
 -/
end

section

variable (𝕜 : Type*) {E : Type*} [Field 𝕜] [LinearOrder 𝕜] [IsStrictOrderedRing 𝕜] [AddCommGroup E]
  [Module 𝕜 E]

end
