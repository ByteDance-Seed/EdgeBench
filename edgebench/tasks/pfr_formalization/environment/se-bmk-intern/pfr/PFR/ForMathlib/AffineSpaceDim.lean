module

public import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Basic
public import Mathlib.LinearAlgebra.Dimension.Constructions
public import Mathlib.LinearAlgebra.Dimension.Finite
public import PFR.Mathlib.LinearAlgebra.Dimension.Finrank

@[expose] public section

open scoped Pointwise

namespace AffineSpace
variable {k V P : Type*} [Ring k] [AddCommGroup V] [Module k V] [AddTorsor V P] {s : Set P}
  {S : Submodule k V}

variable (k) in
open scoped Classical in
/-- The dimension of the affine span over `ℤ` of a subset of an additive group. -/
noncomputable def finrank (s : Set P) : ℕ := (vectorSpan k s).finrank

variable (k) in
@[simp] lemma finrank_empty [Nontrivial k] : finrank k (∅ : Set P) = 0 := by
  sorry

variable [StrongRankCondition k]

lemma finrank_le_submoduleFinrank [Module.Finite k S] (q : P) (hs : ∀ p ∈ s, p -ᵥ q ∈ S) :
    finrank k s ≤ S.finrank := by
  sorry

end AffineSpace
