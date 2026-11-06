import Mathlib.Algebra.Ring.Periodic
import Mathlib.Analysis.Normed.Affine.Convex
import Mathlib.Tactic.Cases
import Mathlib.Topology.Algebra.Order.Floor
import Mathlib.Topology.EMetricSpace.Paracompact
import Mathlib.Topology.ShrinkingLemma

noncomputable section

open Set Function Filter TopologicalSpace
open scoped unitInterval Topology uniformity

section Maps

variable {α β : Type*} {f : α → β} {g : β → α}

variable [TopologicalSpace α] [TopologicalSpace β]

end Maps

section

-- TODO: move to Topology.Separation.Basic

end

section

theorem support_norm {α E : Type*} [NormedAddCommGroup E] (f : α → E) :
    (support fun a ↦ ‖f a‖) = support f := by
  sorry

@[to_additive]
theorem hasCompactMulSupport_of_subset {α β : Type*} [TopologicalSpace α] [T2Space α] [One β]
    {f : α → β} {K : Set α} (hK : IsCompact K) (hf : mulSupport f ⊆ K) : HasCompactMulSupport f := by
  sorry

theorem periodic_const {α β : Type*} [Add α] {a : α} {b : β} : Periodic (fun _ ↦ b) a := by
  sorry

end

section

/-! ## The standard ℤ action on ℝ is properly discontinuous

TODO: use that in ToMathlib.Algebra.Periodic?
-/

instance : VAdd ℤ ℝ :=
  ⟨fun n x ↦ (n : ℝ) + x⟩

instance : ProperlyDiscontinuousVAdd ℤ ℝ :=
  ⟨fun {K L} hK hL ↦ by
    rcases eq_empty_or_nonempty K with (rfl | hK') <;>
        rcases eq_empty_or_nonempty L with (rfl | hL') <;>
      try simp only [image_empty, inter_self, setOf_false, finite_empty, empty_inter, inter_empty,
        Set.not_nonempty_empty, image_inter_nonempty_iff]
    have hSK := (hK.isLUB_sSup hK').1
    have hIK := (hK.isGLB_sInf hK').1
    have hSL := (hL.isLUB_sSup hL').1
    have hIL := (hL.isGLB_sInf hL').1
    apply (finite_Icc ⌈sInf L - sSup K⌉ ⌊sSup L - sInf K⌋).subset
    intro n ⟨x, hk, hnk⟩
    replace hnk : (n : ℝ) + x ∈ L := hnk
    constructor
    · rw [Int.ceil_le]
      linarith [hIL hnk, hSK hk]
    · rw [Int.le_floor]
      linarith [hSL hnk, hIK hk]⟩

end

section Fract

open Int

/- properties of the (dis)continuity of `Int.fract` on `ℝ`.
To be PRed to Topology.Algebra.FloorRing
-/

theorem Ioo_inter_Iio {α : Type*} [LinearOrder α] {a b c : α} :
    Ioo a b ∩ Iio c = Ioo a (min b c) := by
  sorry

-- is `sᶜ ∉ 𝓝[<] (1 : ℝ)` equivalent to something like `ClusterPt (𝓝[Iio (1 : ℝ) ∩ s] (1 : ℝ)` ?

end Fract

section

-- TODO: move to Mathlib.Topology.Constructions
-- needs classical
variable {α β γ δ ι : Type*} [TopologicalSpace α] [TopologicalSpace β] {x : α}
open scoped Classical in

end

section projI

variable {α β : Type*} [Semiring α] [LinearOrder α] [IsStrictOrderedRing α] {x c : α}

/-- If `α` is a `LinearOrderedSemiring`, then `projI : α → α` projection of `α` onto the unit
interval `[0, 1]`. -/
def projI : α → α := fun x ↦ projIcc (0 : α) 1 zero_le_one x

theorem projI_def : projI x = max 0 (min 1 x) := by
  sorry

theorem projIcc_eq_projI : (projIcc (0 : α) 1 zero_le_one x : α) = projI x := by
  sorry

theorem projI_of_le_zero (hx : x ≤ 0) : projI x = 0 := by
  sorry

theorem projI_of_one_le (hx : 1 ≤ x) : projI x = 1 := by
  sorry

@[simp]
theorem projI_eq_zero : projI x = 0 ↔ x ≤ 0 := by
  sorry

@[simp]
theorem projI_eq_one : projI x = 1 ↔ 1 ≤ x := by
  sorry

@[simp]
theorem range_projI : range projI = Icc 0 1 := by
  sorry

theorem monotone_projI : Monotone (projI : α → α) := by
  sorry

theorem strictMonoOn_projI : StrictMonoOn projI (Icc (0 : α) 1) := by
  sorry

theorem projI_le_max : projI x ≤ max 0 x := by
  sorry

theorem min_le_projI : min 1 x ≤ projI x := by
  sorry

theorem projI_le_iff : projI x ≤ c ↔ 0 ≤ c ∧ (1 ≤ c ∨ x ≤ c) := by
  sorry

@[simp]
theorem projI_eq_min : projI x = min 1 x ↔ 0 ≤ x := by
  sorry

theorem projI_mapsto {s : Set α} (h0s : (0 : α) ∈ s)
    (h1s : (1 : α) ∈ s) : MapsTo projI s s := by
  sorry

-- about Path.truncate

end projI

section

open Encodable Option

variable {α β γ : Type*} [TopologicalSpace α] [TopologicalSpace β]

-- can we restate this nicely?

variable {X : Type*} [EMetricSpace X] [LocallyCompactSpace X] [SecondCountableTopology X]

set_option linter.style.cases false in

end

section

-- TODO: move to Topology.Compactness.Compact
variable {α β γ : Type*} [TopologicalSpace α] [TopologicalSpace β] [TopologicalSpace γ]

end

section

open Metric

attribute [fun_prop] continuous_infDist_pt

end

section NormedSpace

open Metric

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]

theorem isPreconnected_ball (x : E) (r : ℝ) : IsPreconnected (ball x r) := by
  sorry

theorem isConnected_ball {x : E} {r : ℝ} : IsConnected (ball x r) ↔ 0 < r := by
  sorry

-- todo: make Metric.mem_nhds_iff protected
end NormedSpace

namespace TopologicalSpace

-- TODO: move to Topology.Bases

open scoped Classical in
/-- A version of `TopologicalSpace.cover_nat_nhdsWithin` where `f` is only defined on `s`. -/
theorem cover_nat_nhdsWithin' {α} [TopologicalSpace α] [SecondCountableTopology α] {s : Set α}
    {f : ∀ x ∈ s, Set α} (hf : ∀ (x) (hx : x ∈ s), f x hx ∈ 𝓝[s] x) (hs : s.Nonempty) :
    ∃ (x : ℕ → α) (hx : range x ⊆ s), s ⊆ ⋃ n, f (x n) (range_subset_iff.mp hx n) := by
  sorry

end TopologicalSpace

open Subtype

namespace Set

namespace Subtype

variable {α : Type*}

theorem image_coe_eq_iff_eq_univ {s : Set α} {t : Set s} : ((↑) : s → α) '' t = s ↔ t = univ := by
  sorry

theorem preimage_coe_eq_univ {s t : Set α} : ((↑) : s → α) ⁻¹' t = univ ↔ s ⊆ t := by
  sorry

end Subtype

end Set

section ParacompactSpace

-- a version of `precise_refinement_set` for open `s`.
/-- When `s : Set X` is open and paracompact, we can find a precise refinement on `s`. Note that
 in this case we only get the locally finiteness condition on `s`, which is weaker than the local
 finiteness condition on all of `X` (the collection might not be locally finite on the boundary of
 `s`). -/
theorem precise_refinement_set' {ι X : Type*} [TopologicalSpace X] {s : Set X} [ParacompactSpace s]
    (hs : IsOpen s) (u : ι → Set X) (uo : ∀ i, IsOpen (u i)) (us : s ⊆ ⋃ i, u i) :
    ∃ v : ι → Set X, (∀ i, IsOpen (v i)) ∧ (s ⊆ ⋃ i, v i) ∧
      (LocallyFinite fun i ↦ ((↑) : s → X) ⁻¹' v i) ∧ (∀ i, v i ⊆ s) ∧ ∀ i, v i ⊆ u i := by
  sorry

theorem point_finite_of_locallyFinite_coe_preimage {ι X : Type*} [TopologicalSpace X] {s : Set X}
    {f : ι → Set X} (hf : LocallyFinite fun i ↦ ((↑) : s → X) ⁻¹' f i) (hfs : ∀ i, f i ⊆ s)
    {x : X} : {i | x ∈ f i}.Finite := by
  sorry

end ParacompactSpace

section ShrinkingLemma

variable {ι X : Type*} [TopologicalSpace X]

variable {u : ι → Set X} {s : Set X} [NormalSpace s]

-- this lemma is currently formulated a little weirdly, since we have a collection of open sets
-- as the input and a collection of closed/compact sets as output.
-- Perhaps we can formulate it so that the input is a collection of compact sets whose interiors
-- cover s.
theorem exists_subset_iUnion_interior_of_isOpen (hs : IsOpen s) (uo : ∀ i, IsOpen (u i))
    (uc : ∀ i, IsCompact (closure (u i))) (us : ∀ i, closure (u i) ⊆ s)
    (uf : ∀ x ∈ s, {i | x ∈ u i}.Finite) (uU : s ⊆ ⋃ i, u i) :
    ∃ v : ι → Set X, (s ⊆ ⋃ i, interior (v i)) ∧ (∀ i, IsCompact (v i)) ∧ ∀ i, v i ⊆ u i := by
  sorry

end ShrinkingLemma

theorem Filter.EventuallyEq.slice {α β γ : Type*} [TopologicalSpace α] [TopologicalSpace β]
    {f g : α × β → γ} {a : α} {b : β} (h : f =ᶠ[𝓝 (a, b)] g) :
    (fun y ↦ f (a, y)) =ᶠ[𝓝 b] fun y ↦ g (a, y) := by
  sorry

theorem exists_compact_between' {α : Type*} [TopologicalSpace α] [LocallyCompactSpace α]
    {K U : Set α} (hK : IsCompact K) (hU : IsOpen U) (h_KU : K ⊆ U) :
    ∃ L, IsCompact L ∧ L ∈ 𝓝ˢ K ∧ L ⊆ U := by
  sorry
