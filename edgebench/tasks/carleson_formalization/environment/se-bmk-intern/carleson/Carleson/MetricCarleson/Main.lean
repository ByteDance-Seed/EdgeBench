module

public import Carleson.MetricCarleson.Linearized

@[expose] public section

open scoped NNReal
open MeasureTheory Set ENNReal Metric

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] {q q' : ℝ≥0} {F G : Set X} {K : X → X → ℂ}
variable [KernelProofData a K] {f : X → ℂ}

variable (X) in
/-- A countable dense subset of `Θ X`. -/
def Θ' : Set (Θ X) := (TopologicalSpace.exists_countable_dense _).choose

lemma countable_Θ' : (Θ' X).Countable := by
  sorry
lemma dense_Θ' : Dense (Θ' X) := by
  sorry

/-- A countable dense subset of the range of `R₁` and `R₂`. -/
def J102 : Set (ℚ × ℚ) := {p | 0 < p.1 ∧ p.1 < p.2}

lemma carlesonOperator_eq_biSup_Θ'_J102 {x : X} (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) :
    carlesonOperator K f x =
    ⨆ θ ∈ Θ' X, ⨆ j ∈ J102, ‖carlesonOperatorIntegrand K θ j.1 j.2 f x‖ₑ := by
  sorry

section Enum

variable (nΘ' : (Θ' X).Nonempty) (g : Θ X → X → ℝ≥0∞)

/-- An enumeration of `Θ' X`, assuming it is nonempty. It may contain duplicates. -/
def enumΘ' : ℕ → Θ' X :=
  (countable_Θ'.exists_surjective nΘ').choose

lemma surjective_enumΘ' : Function.Surjective (enumΘ' nΘ') := by
  sorry

lemma biSup_Θ'_eq_biSup_enumΘ' {x : X} :
    ⨆ θ ∈ Θ' X, g θ x = ⨆ n, ⨆ i ∈ Finset.range (n + 1), g (enumΘ' nΘ' i) x := by
  sorry

/-- The argmax of `g (enumΘ' nΘ' i) x` over `i ≤ n` with lower indices winning ties. -/
def enumΘ'ArgMax (n : ℕ) (x : X) : ℕ :=
  (List.range (n + 1)).findIdx fun i ↦ ∀ j ≤ n, g (enumΘ' nΘ' j) x ≤ g (enumΘ' nΘ' i) x

lemma enumΘ'ArgMax_mem_range {n : ℕ} {x : X} : enumΘ'ArgMax nΘ' g n x ∈ Finset.range (n + 1) := by
  sorry

/-- The characterising property of `enumΘ'ArgMax`. -/
lemma enumΘ'ArgMax_eq_iff {n i : ℕ} {x : X} (hi : i ≤ n) :
    enumΘ'ArgMax nΘ' g n x = i ↔
    (∀ j ≤ n, g (enumΘ' nΘ' j) x ≤ g (enumΘ' nΘ' i) x) ∧
    ∀ j < i, g (enumΘ' nΘ' j) x < g (enumΘ' nΘ' i) x := by
  sorry

variable {g} (mg : ∀ θ, Measurable (g θ))

/-- The simple function corresponding to the blueprint's `Q_n`. -/
def QΘ' (n : ℕ) : SimpleFunc X (Θ X) where
  toFun x := enumΘ' nΘ' (enumΘ'ArgMax nΘ' g n x)
  measurableSet_fiber' θ := by
    simp_rw [← measurable_mem, mem_preimage, mem_singleton_iff]
    apply Measurable.comp (g := fun i ↦ (enumΘ' nΘ' i).1 = θ) (f := enumΘ'ArgMax nΘ' g n)
    · exact measurable_id
    refine measurable_to_countable' fun i ↦ ?_
    simp_rw [← measurable_mem, mem_preimage, mem_singleton_iff]
    rcases lt_or_ge n i with hi | hi
    · have (x : X) : enumΘ'ArgMax nΘ' g n x ≠ i := by
        contrapose! hi; rw [← hi, ← Nat.lt_add_one_iff, ← Finset.mem_range]
        exact enumΘ'ArgMax_mem_range nΘ' g
      simp_rw [this]; exact measurable_const
    simp_rw [enumΘ'ArgMax_eq_iff nΘ' g hi]; apply Measurable.and
    all_goals refine (Measurable.forall fun j ↦ measurable_const.imp ?_); rw [← measurableSet_setOf]
    · exact measurableSet_le (mg _) (mg _)
    · exact measurableSet_lt (mg _) (mg _)
  finite_range' := by
    classical
    have fbs := Finset.finite_toSet ((Finset.range (n + 1)).image fun i ↦ (enumΘ' nΘ' i).1)
    refine fbs.subset fun θ mθ ↦ ?_
    simp only [mem_range, Finset.coe_image, Finset.coe_range, mem_image, mem_Iio] at mθ ⊢
    obtain ⟨x, hx⟩ := mθ
    have key := enumΘ'ArgMax_mem_range nΘ' g (n := n) (x := x)
    rw [Finset.mem_range] at key; exact ⟨_, key, hx⟩

lemma biSup_enumΘ'_le_QΘ' {n : ℕ} {x : X} :
    ⨆ i ∈ Finset.range (n + 1), g (enumΘ' nΘ' i) x ≤ g (QΘ' nΘ' mg n x) x := by
  sorry

end Enum

lemma lowerSemicontinuous_LNT {Q : SimpleFunc X (Θ X)} {θ : Θ X} :
    LowerSemicontinuous (linearizedNontangentialOperator Q θ K f) := by
  sorry

lemma BST_LNT_of_BST_NT {Q : SimpleFunc X (Θ X)}
    (hT : HasBoundedStrongType (nontangentialOperator K · ·) 2 2 volume volume (C_Ts a)) :
    ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a) := by
  sorry

/-- Theorem 1.1.1 -/
theorem metric_carleson [IsCancellative X (defaultτ a)]
    (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q') (mF : MeasurableSet F) (mG : MeasurableSet G)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    (hT : HasBoundedStrongType (nontangentialOperator K · ·) 2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, carlesonOperator K f x ≤
    C1_0_2 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

theorem metric_carleson_check : MetricSpaceCarleson := by
  sorry

/- Theorem 1.1.1, with an explicit value for the constant, corresponding to `𝕔 = 100` and following
the blueprint. If one takes `𝕔 = 7`, one gets `2 ^ (44 * a ^ 3)` instead. -/
theorem metric_carleson' [IsCancellative X (defaultτ a)]
    (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q') (mF : MeasurableSet F) (mG : MeasurableSet G)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    (hT : HasBoundedStrongType (nontangentialOperator K · ·) 2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, carlesonOperator K f x ≤
    (2 ^ (443 * a ^ 3) / (q - 1) ^ 6) * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

end
