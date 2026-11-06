import Mathlib.Analysis.Normed.Field.Basic
import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Topology.Connected.PathConnected

open Set Function

open scoped Topology unitInterval

noncomputable section

variable {X X' Y Z : Type*} [TopologicalSpace X]
  [TopologicalSpace X'] [TopologicalSpace Y] [TopologicalSpace Z]

namespace Path

variable {x : X} {γ γ' : Path x x}

/-- A loop evaluated at `t / t` is equal to its endpoint. Note that `t / t = 0` for `t = 0`. -/
@[simp]
theorem extend_div_self (γ : Path x x) (t : ℝ) : γ.extend (t / t) = x := by
  sorry

/-- Concatenation of two loops which moves through the first loop on `[0, t₀]` and
through the second one on `[t₀, 1]`. All endpoints are assumed to be the same so that this
function is also well-defined for `t₀ ∈ {0, 1}`.
`strans` stands either for a *s*kewed transitivity, or a transitivity with different *s*peeds. -/
def strans (γ γ' : Path x x) (t₀ : I) : Path x x where
  toFun t := if t ≤ t₀ then γ.extend (t / t₀) else γ'.extend ((t - t₀) / (1 - t₀))
  continuous_toFun := by
    refine Continuous.if_le ?_ ?_ continuous_id continuous_const ?_
    · continuity
    · continuity
    · simp only [extend_div_self, Icc.mk_zero, zero_le_one, zero_div, forall_eq,
        extend_apply, Path.source, left_mem_Icc, sub_self]
  source' := by simp
  target' := by
    simp +contextual only [unitInterval.le_one'.ge_iff_eq.trans eq_comm,
      extend_div_self, Icc.coe_one, imp_true_iff, ite_eq_right_iff]

theorem strans_self {x : X} (γ γ' : Path x x) (t₀ : I) : γ.strans γ' t₀ t₀ = x := by
  sorry

end Path
