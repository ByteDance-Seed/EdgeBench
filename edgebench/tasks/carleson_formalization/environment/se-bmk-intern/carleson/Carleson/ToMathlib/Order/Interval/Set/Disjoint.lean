module
public import Mathlib.Order.Interval.Set.Disjoint

--Upstreaming status: ready

public section

open Set

@[simp]
theorem iUnion_Icc_eq_Ici_self_iff {ι : Sort*} {α : Type*} [LinearOrder α] {f : ι → α} {a : α} :
    ⋃ i, Icc a (f i) = Ici a ↔ ∀ (x : α), a ≤ x → ∃ i, x ≤ f i := by
  sorry

theorem IsGLB.biUnion_Ioi_eq_Ioi {α : Type*} [LinearOrder α] {s : Set α} {a : α}
  (a_glb : IsGLB s a) :
    ⋃ x ∈ s, Ioi x = Ioi a := by
  sorry

theorem iUnion_Ioi_eq_Ioi_iInf {ι : Sort*} {R : Type*} [CompleteLinearOrder R] {f : ι → R} :
    ⋃ i : ι, Ioi (f i) = Ioi (⨅ i, f i) := by
  sorry

theorem iUnion_Iio_eq_Iio_iSup {ι : Sort*} {R : Type*} [CompleteLinearOrder R] {f : ι → R}
     : ⋃ i : ι, Iio (f i) = Iio (⨆ i, f i) := by
  sorry
