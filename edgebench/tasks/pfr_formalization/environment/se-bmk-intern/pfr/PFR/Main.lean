module

public import Mathlib.Algebra.Group.Pointwise.Set.Card
public import Mathlib.Algebra.Module.ZMod
public import Mathlib.Combinatorics.Additive.RuzsaCovering
public import Mathlib.GroupTheory.Complement
public import PFR.EntropyPFR
public import PFR.Tactic.RPowSimp

/- In this file the power notation will always mean the base and exponent are real numbers. -/
local macro_rules | `($x ^ $y) => `(HPow.hPow ($x : ℝ) ($y : ℝ))

/-!
# Polynomial Freiman-Ruzsa conjecture

Here we prove the polynomial Freiman-Ruzsa conjecture.
-/

public section

open ProbabilityTheory MeasureTheory Real Set Fintype Function
open scoped Pointwise

universe u

namespace ProbabilityTheory
variable {G Ω : Type*} [AddCommGroup G] [Finite G]
    [MeasurableSpace G] [MeasurableSingletonClass G] {A B : Finset G}
    [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)] {U V : Ω → G}

end ProbabilityTheory

variable {G : Type*} [AddCommGroup G] {A : Set G} {K : ℝ} [Countable G]

variable [Module (ZMod 2) G] [Finite G]

/-- Auxiliary statement towards the polynomial Freiman-Ruzsa (PFR) conjecture: if `A` is a subset of
an elementary abelian 2-group of doubling constant at most $K$, then there exists a subgroup `H`
such that `A` can be covered by at most `K^(13/2) |A|^(1/2) / |H|^(1/2)` cosets of `H`, and `H` has
the same cardinality as `A` up to a multiplicative factor `K^11`. -/
lemma PFR_conjecture_aux (hA₀ : A.Nonempty) (hA : (A + A).ncard ≤ K * A.ncard) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
    Nat.card c ≤ K ^ (13/2 : ℝ) * A.ncard ^ (1/2 : ℝ) * (H : Set G).ncard ^ (-1/2 : ℝ) ∧
      (H : Set G).ncard ≤ K ^ 11 * A.ncard ∧ A.ncard ≤ K ^ 11 * (H : Set G).ncard ∧ A ⊆ c + H := by
  sorry

/-- The polynomial Freiman-Ruzsa (PFR) conjecture: if `A` is a subset of an elementary abelian
2-group of doubling constant at most `K`, then `A` can be covered by at most `2 * K ^ 12` cosets of
a subgroup of cardinality at most `|A|`. -/
theorem PFR_conjecture (hA₀ : A.Nonempty) (hA : (A + A).ncard ≤ K * A.ncard) :
     ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 12 ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry

/-- Corollary of `PFR_conjecture` in which the ambient group is not required to be finite (but) then
`H` and `c` are finite. -/
theorem PFR_conjecture' {G : Type*} [AddCommGroup G] [Module (ZMod 2) G]
    {A : Set G} {K : ℝ} (hA₀ : A.Nonempty) (Afin : A.Finite)
    (hA : (A + A).ncard ≤ K * A.ncard) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G), c.Finite ∧ (H : Set G).Finite ∧
      Nat.card c < 2 * K ^ 12 ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry
