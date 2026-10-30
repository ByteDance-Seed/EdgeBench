import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Algebra.Ring.Periodic
import Mathlib.Topology.Separation.Hausdorff

-- TODO: the file this references doesn't exist in mathlib any more; rename this one appropriately!

/-!

# Boundedness property of periodic function

The main purpose of that file it to prove
```
lemma Continuous.bounded_of_onePeriodic_of_isCompact {f : X → ℝ → E} (cont : Continuous ↿f)
  (hper : ∀ x, OnePeriodic (f x)) {K : Set X} (hK : IsCompact K) (hfK : ∀ x ∉ K, f x = 0) :
  ∃ C, ∀ x t, ‖f x t‖ ≤ C
```

This is done by introducing the quotient 𝕊₁ = ℝ/ℤ as a compact topological space.
Patrick is not sure this is the optimal version.

In the first part, generalize many lemmas to any period and add to `Algebra.Ring.Periodic.lean`?
-/

noncomputable section

open Set Function Filter TopologicalSpace Int

open scoped Topology

section OnePeriodic

variable {α : Type*}

/-- The integers as an additive subgroup of the reals. -/
def ℤSubℝ : AddSubgroup ℝ := AddMonoidHom.range (Int.castAddHom ℝ)

/-- The equivalence relation on `ℝ` corresponding to its partition as cosets of `ℤ`. -/
def transOne : Setoid ℝ := QuotientAddGroup.leftRel ℤSubℝ

/-- The proposition that a function on `ℝ` is periodic with period `1`. -/
def OnePeriodic (f : ℝ → α) : Prop := Periodic f 1

theorem OnePeriodic.add_nat {f : ℝ → α} (h : OnePeriodic f) (k : ℕ) (x : ℝ) : f (x + k) = f x := by
  sorry

theorem OnePeriodic.add_int {f : ℝ → α} (h : OnePeriodic f) (k : ℤ) (x : ℝ) : f (x + k) = f x := by
  sorry

/-- The circle `𝕊₁ := ℝ/ℤ`.

TODO [Yury]: use `AddCircle`. -/
def 𝕊₁ :=
  Quotient transOne
deriving TopologicalSpace, Inhabited

theorem transOne_rel_iff {a b : ℝ} : transOne.r a b ↔ ∃ k : ℤ, b = a + k := by
  sorry

section

attribute [local instance] transOne

/-- The quotient map from the reals to the circle `ℝ ⧸ ℤ`. -/
def proj𝕊₁ : ℝ → 𝕊₁ :=
  Quotient.mk'

/-- The unique representative in the half-open interval `[0, 1)` for each coset of `ℤ` in `ℝ`,
regarded as a map from the circle `𝕊₁ → ℝ`. -/
def 𝕊₁.repr (x : 𝕊₁) : ℝ :=
  let t := Quotient.out x
  fract t

theorem image_proj𝕊₁_Icc : proj𝕊₁ '' Icc 0 1 = univ := by
  sorry

theorem isOpenQuotientMap_proj𝕊₁ : IsOpenQuotientMap proj𝕊₁ := by
  sorry

@[continuity, fun_prop]
theorem continuous_proj𝕊₁ : Continuous proj𝕊₁ := by
  sorry

/-- A one-periodic function on `ℝ` descends to a function on the circle `ℝ ⧸ ℤ`. -/
def OnePeriodic.lift {f : ℝ → α} (h : OnePeriodic f) : 𝕊₁ → α :=
  Quotient.lift f (by intro a b hab; rcases transOne_rel_iff.mp hab with ⟨k, rfl⟩; rw [h.add_int])

end

@[inherit_doc] local notation "π" => proj𝕊₁

instance : CompactSpace 𝕊₁ :=
  ⟨by rw [← image_proj𝕊₁_Icc]; exact isCompact_Icc.image continuous_proj𝕊₁⟩

theorem isClosed_int : IsClosed (range ((↑) : ℤ → ℝ)) := by
  sorry

instance : T2Space 𝕊₁ := by
  rw [t2Space_iff_of_isOpenQuotientMap isOpenQuotientMap_proj𝕊₁]
  have : {q : ℝ × ℝ | π q.fst = π q.snd} = {q : ℝ × ℝ | ∃ k : ℤ, q.2 = q.1 + k} := by
    ext ⟨a, b⟩
    exact Quotient.eq''.trans transOne_rel_iff
  have : {q : ℝ × ℝ | π q.fst = π q.snd} =
      (fun q : ℝ × ℝ ↦ q.2 - q.1) ⁻¹' (range <| ((↑) : ℤ → ℝ)) := by
    rw [this]
    ext ⟨a, b⟩
    refine exists_congr fun k ↦ ?_
    conv_rhs => rw [eq_comm, sub_eq_iff_eq_add']
  rw [this]
  exact IsClosed.preimage (continuous_snd.sub continuous_fst) isClosed_int

variable {X E : Type*} [TopologicalSpace X] [NormedAddCommGroup E]

theorem Continuous.bounded_of_onePeriodic_of_compact {f : X → ℝ → E} (cont : Continuous ↿f)
    (hper : ∀ x, OnePeriodic (f x)) {K : Set X} (hK : IsCompact K)
    (hfK : ∀ x ∉ K, f x = 0) : ∃ C, ∀ x t, ‖f x t‖ ≤ C := by
  sorry

end OnePeriodic
