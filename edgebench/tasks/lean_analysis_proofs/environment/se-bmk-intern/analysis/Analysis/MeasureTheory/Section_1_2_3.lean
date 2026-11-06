import Analysis.MeasureTheory.Section_1_2_2

/-!
# Introduction to Measure Theory, Section 1.2.3: Non-measurable sets

A companion to (the introduction to) Section 1.2.3 of the book "An introduction to Measure Theory".

-/

open scoped Pointwise

/-! ## Vitali Set Construction

We construct a Vitali set by choosing representatives from each coset of ℝ/ℚ
that intersects \[0,1\]. The key is that ℚ acts on ℝ by translation, and this
partitions ℝ into countably many disjoint translates of any transversal.
-/

/-- The additive subgroup of ℚ in ℝ -/
def Rat.addSubgroup : AddSubgroup ℝ where
  carrier := Set.range ((↑) : ℚ → ℝ)
  add_mem' := by
    intro a b ⟨qa, ha⟩ ⟨qb, hb⟩
    exact ⟨qa + qb, by simp [ha, hb]⟩
  zero_mem' := ⟨0, by simp⟩
  neg_mem' := by
    intro a ⟨q, hq⟩
    exact ⟨-q, by simp [hq]⟩

/-- The quotient group ℝ/ℚ (reals modulo rationals) -/
abbrev RealModRat := ℝ ⧸ Rat.addSubgroup

/-- ℚ is dense in ℝ, so every coset of ℝ/ℚ intersects \[0,1\] -/
lemma coset_intersects_unit_interval (c : RealModRat) :
    ∃ x : ℝ, x ∈ Set.Icc 0 1 ∧ QuotientAddGroup.mk (s := Rat.addSubgroup) x = c := by
  sorry

/-- The Vitali set: choose one representative from each coset that lies in \[0,1\] -/
noncomputable def VitaliSet : Set ℝ :=
  Set.range (fun c : RealModRat => (coset_intersects_unit_interval c).choose)

/-- The Lebesgue measure of a closed interval \[a,b\] in ℝ (embedded in {lean}`EuclideanSpace' 1`) equals b - a -/
lemma Lebesgue_measure.Icc_eq (a b : ℝ) (hab : a ≤ b) :
    Lebesgue_measure (Real.equiv_EuclideanSpace' '' Set.Icc a b) = (b - a : ℝ) := by
  sorry

/-- The Vitali set (lifted to {lean}`EuclideanSpace' 1`) is not Lebesgue measurable.
    This is the core of Proposition 1.2.18. -/
theorem VitaliSet.nonmeasurable : ¬ LebesgueMeasurable (Real.equiv_EuclideanSpace' '' VitaliSet) := by
  sorry

/-- Proposition 1.2.18 -/
theorem LebesgueMeasurable.nonmeasurable : ∃ E : Set (EuclideanSpace' 1), E ⊆ Real.equiv_EuclideanSpace' '' (Set.Icc 0 1) ∧ ¬ LebesgueMeasurable E := by
  sorry

/-- Exercise 1.2.26 (Outer measure is not finitely additive)-/
example : ∃ E F : Set (EuclideanSpace' 1), E ∩ F = ∅ ∧ Bornology.IsBounded E ∧ Bornology.IsBounded F ∧ Lebesgue_outer_measure (E ∪ F) ≠ Lebesgue_outer_measure E + Lebesgue_outer_measure F := by
  sorry

/-- Exercise 1.2.27 (Projections of measurable sets need not be measurable) -/
example : ∃ E : Set (EuclideanSpace' 2), LebesgueMeasurable E ∧ ¬ LebesgueMeasurable ((fun x ↦ Real.equiv_EuclideanSpace' (x 0: ℝ)) '' E) := by
  sorry
