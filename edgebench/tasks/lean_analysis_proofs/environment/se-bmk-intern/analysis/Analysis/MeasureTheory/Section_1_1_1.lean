import Analysis.MeasureTheory.Notation
import Analysis.Section_9_1

/-!
# Introduction to Measure Theory, Section 1.1.1: Elementary measure

A companion to Section 1.1.1 of the book "An introduction to Measure Theory".

-/

/- Definition 1.1.1.  (Intervals) We use the same formalization of intervals used in
Chapter 11 of "Analysis I".  Following the usual Lean preference to admit `junk` values,
we allow for the possibility that `b < a`. -/
inductive BoundedInterval where
  | Ioo (a b:ℝ) : BoundedInterval
  | Icc (a b:ℝ) : BoundedInterval
  | Ioc (a b:ℝ) : BoundedInterval
  | Ico (a b:ℝ) : BoundedInterval

open BoundedInterval

/-- Coerces a `BoundedInterval` to its underlying set of real numbers. -/
@[coe]
def BoundedInterval.toSet (I: BoundedInterval) : Set ℝ := match I with
  | Ioo a b => .Ioo a b
  | Icc a b => .Icc a b
  | Ioc a b => .Ioc a b
  | Ico a b => .Ico a b

/-- Enables coercion from `BoundedInterval` to {lean}`Set ℝ`. -/
instance BoundedInterval.inst_coeSet : Coe BoundedInterval (Set ℝ) where
  coe := toSet

/-- The empty `BoundedInterval` is represented as the degenerate open interval (0,0). -/
instance BoundedInterval.instEmpty : EmptyCollection BoundedInterval where
  emptyCollection := Ioo 0 0

/-- The empty `BoundedInterval` coerces to the empty set. -/
@[simp]
theorem BoundedInterval.coe_empty : ((∅ : BoundedInterval):Set ℝ) = ∅ := by
  sorry

open Classical in
/-- This is to make `Finset`s of `BoundedInterval`s work properly -/
noncomputable instance BoundedInterval.decidableEq : DecidableEq BoundedInterval := instDecidableEqOfLawfulBEq

@[simp]
theorem BoundedInterval.set_Icc (a b:ℝ) : (Icc a b : Set ℝ) = .Icc a b := by
  sorry

namespace BoundedInterval

/-- `BoundedInterval.toSet` is injective for non-empty intervals -/
lemma toSet_injective_of_nonempty {I J : BoundedInterval}
    (hI : I.toSet.Nonempty) (hJ : J.toSet.Nonempty) (h_eq : I.toSet = J.toSet) :
    I = J := by
  sorry

end BoundedInterval

/-- A witness for lowerBound of upperBounds -/
def witness_lowerBound_upperBounds {X : Set ℝ} (y : ℝ) (hy : y ∈ X)
    : y ∈ lowerBounds (upperBounds X) := by
  intro u hu; simp [upperBounds] at hu; exact hu hy

/-- A witness for upperBound of lowerBounds -/
def witness_upperBound_lowerBounds {X : Set ℝ} (y : ℝ) (hy : y ∈ X)
    : y ∈ upperBounds (lowerBounds X) := by
  intro u hu; simp [lowerBounds] at hu; exact hu hy

/- If x < sSup X and X is not empty, then there exists z ∈ X with x < z -/
/- We don't need to assume that X is BddAbove
-(if X is not Bddabove, we get that sSup X = 0 (the junk value) and the result still follows -/
#check exists_lt_of_lt_csSup

/- If sInf X < x and X is not empty, then there exists w ∈ X with w ≤ x -/
/- We don't need to assume that X is BddBelow.
-(if X if not BddBelow, we get that sInf X = 0 (the junk value) and the result still follows-/
#check exists_lt_of_csInf_lt

/-- A set of reals is bounded and order-connected if and only if it equals some bounded interval. -/
theorem BoundedInterval.ordConnected_iff (X:Set ℝ) :
    Bornology.IsBounded X ∧ X.OrdConnected ↔ ∃ I: BoundedInterval, X = I := by
  sorry

/-- The intersection of two bounded intervals is again a bounded interval. -/
theorem BoundedInterval.inter (I J: BoundedInterval) : ∃ K : BoundedInterval, (I:Set ℝ) ∩ (J:Set ℝ) = (K:Set ℝ) := by
  sorry

/-- Instance enabling ∩ notation for `BoundedInterval`s. -/
noncomputable instance BoundedInterval.instInter : Inter BoundedInterval where
  inter I J := (inter I J).choose

/-- The intersection of `BoundedInterval`s equals the set-theoretic intersection. -/
@[simp]
theorem BoundedInterval.inter_eq (I J: BoundedInterval) : (I ∩ J : BoundedInterval) = (I:Set ℝ) ∩ (J:Set ℝ)  := by
  sorry

/-- Instance enabling ∈ notation for membership in `BoundedInterval`. -/
instance BoundedInterval.instMembership : Membership ℝ BoundedInterval where
  mem I x := x ∈ (I:Set ℝ)

/-- Membership in `BoundedInterval` is equivalent to membership in its underlying set. -/
@[simp]
theorem BoundedInterval.mem_iff (I: BoundedInterval) (x:ℝ) :
  x ∈ I ↔ x ∈ (I:Set ℝ) := by
  sorry

/-- Instance enabling ⊆ notation for `BoundedInterval`s. -/
instance BoundedInterval.instSubset : HasSubset BoundedInterval where
  Subset I J := ∀ x, x ∈ I → x ∈ J

/-- Subset of `BoundedInterval`s is equivalent to subset of their underlying sets. -/
@[simp]
theorem BoundedInterval.subset_iff (I J: BoundedInterval) :
  I ⊆ J ↔ (I:Set ℝ) ⊆ (J:Set ℝ) := by
  sorry

/-- Extracts the left endpoint of a bounded interval. -/
abbrev BoundedInterval.a (I: BoundedInterval) : ℝ := match I with
  | Ioo a _ => a
  | Icc a _ => a
  | Ioc a _ => a
  | Ico a _ => a

/-- Extracts the right endpoint of a bounded interval. -/
abbrev BoundedInterval.b (I: BoundedInterval) : ℝ := match I with
  | Ioo _ b => b
  | Icc _ b => b
  | Ioc _ b => b
  | Ico _ b => b

/-- Definition 1.1.1 (boxes): The length of an interval is max(b - a, 0). -/
abbrev BoundedInterval.length (I: BoundedInterval) : ℝ := max (I.b - I.a) 0

/-- Using ||ₗ subscript here to not override || -/
macro:max atomic("|" noWs) a:term noWs "|ₗ" : term => `(BoundedInterval.length $a)

/-- A d-dimensional box is a Cartesian product of d bounded intervals. -/
@[ext]
structure Box (d:ℕ) where
  side : Fin d → BoundedInterval

/-- Coerces a `Box` to its underlying set in d-dimensional Euclidean space. -/
@[coe]
def Box.toSet {d:ℕ} (B: Box d) : Set (EuclideanSpace' d) :=
  {x | ∀ i, x i ∈ (B.side i : Set ℝ)}

@[simp]
theorem Box.mem_toSet {d:ℕ} {B: Box d} {x : EuclideanSpace' d} :
    x ∈ B.toSet ↔ ∀ i, x i ∈ (B.side i : Set ℝ) := by
  sorry

/-- Enables coercion from {lean}`Box d` to {lean}`Set (EuclideanSpace' d)`. -/
instance Box.inst_coeSet {d:ℕ} : Coe (Box d) (Set (EuclideanSpace' d)) where
  coe := toSet

/-- Lifts a 1-dimensional interval to a 1-dimensional box. -/
@[coe]
abbrev BoundedInterval.toBox (I: BoundedInterval) : Box 1 where
  side := fun _ ↦ I

/-- Enables coercion from `BoundedInterval` to {lean}`Box 1`. -/
instance BoundedInterval.inst_coeBox : Coe (BoundedInterval) (Box 1) where
  coe := toBox

/-- Coercing to {lean}`Box 1` is injective: equal boxes implies equal intervals. -/
@[simp]
theorem BoundedInterval.toBox_inj {I J: BoundedInterval} : (I:Box 1) = (J:Box 1) ↔ I = J := by
  sorry

/-- Definition 1.1.1 (boxes): The volume of a box is the product of its side lengths. -/
abbrev Box.volume {d:ℕ} (B: Box d) : ℝ := ∏ i, |B.side i|ₗ

/-- Using ||ᵥ subscript here to not override || -/
macro:max atomic("|" noWs) a:term noWs "|ᵥ" : term => `(Box.volume $a)

/-- The volume of a 1D box equals the length of the underlying interval. -/
@[simp]
theorem Box.volume_of_interval (I:BoundedInterval) : |(I:Box 1)|ᵥ = |I|ₗ := by
  sorry

/-- `Box.toSet` is injective on non-empty boxes -/
lemma Box.toSet_injective_of_nonempty {d:ℕ} {B₁ B₂ : Box d}
    (h₁ : B₁.toSet.Nonempty) (h₂ : B₂.toSet.Nonempty) (h_eq : B₁.toSet = B₂.toSet) :
    B₁ = B₂ := by
  sorry

/-- A set is elementary if it can be expressed as a finite union of boxes. -/
abbrev IsElementary {d:ℕ} (E: Set (EuclideanSpace' d)) : Prop := ∃ S : Finset (Box d), E = ⋃ B ∈ S, ↑B

/-- Every box is an elementary set (witnessed by the singleton finset). -/
theorem IsElementary.box {d:ℕ} (B: Box d) : IsElementary B.toSet := by
  sorry

/-- Exercise 1.1.1 (Boolean closure): The union of two elementary sets is elementary. -/
theorem IsElementary.union {d:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: IsElementary E) (hF: IsElementary F) : IsElementary (E ∪ F) := by
  sorry

/-- The union of a finset of elementary sets is elementary. -/
lemma IsElementary.union' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, IsElementary E) : IsElementary (⋃ E ∈ S, E) := by
  sorry

/-- The empty set is elementary. -/
theorem IsElementary.empty (d:ℕ) : IsElementary (∅: Set (EuclideanSpace' d)) := by
  sorry

/-- Exercise 1.1.1 (Boolean closure): The set difference of two elementary sets is elementary. -/
theorem IsElementary.sdiff {d:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: IsElementary E) (hF: IsElementary F) : IsElementary (E \ F) := by
  sorry

/-- Exercise 1.1.1 (Boolean closure): The symmetric difference of two elementary sets is elementary. -/
theorem IsElementary.symmDiff {d:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: IsElementary E) (hF: IsElementary F) : IsElementary (symmDiff E F) := by
  sorry

open Pointwise

/-- Exercise 1.1.1 (Boolean closure): Translation of an elementary set is elementary. -/
theorem IsElementary.translate {d:ℕ} {E: Set (EuclideanSpace' d)}
  (hE: IsElementary E) (x: EuclideanSpace' d) : IsElementary (E + {x}) := by
  sorry

/-- Lemma 1.1.2(i): Any finset of boxes admits a common refinement into pairwise disjoint sub-boxes. -/
theorem Box.partition {d:ℕ} (S: Finset (Box d)) : ∃ T: Finset (Box d), (T : Set (Box d)).PairwiseDisjoint Box.toSet ∧ ∀ I ∈ S, ∃ U : Set T, I = ⋃ J ∈ U, J.val.toSet := by
  sorry

/-- Every elementary set can be partitioned into pairwise disjoint boxes. -/
theorem IsElementary.partition {d:ℕ} {E: Set (EuclideanSpace' d)}
(hE: IsElementary E) : ∃ T: Finset (Box d), (T : Set (Box d)).PairwiseDisjoint Box.toSet ∧ E = ⋃ J ∈ T, J.toSet := by
  sorry

/-- Lattice points in a box decompose as a product of lattice points in each interval side. -/
def Box.sample_congr {d:ℕ} (B:Box d) (N:ℕ) :
↥(B.toSet ∩ (Set.range (fun (n:Fin d → ℤ) ↦ .toLp 2 (fun i ↦ (N:ℝ)⁻¹*(n i))))) ≃ ((i : Fin d) → ↑(↑(B.side i) ∩ Set.range fun n:ℤ ↦ (N:ℝ)⁻¹ * ↑n)) := {
    toFun x i := by
      obtain ⟨ x, hx ⟩ := x; refine ⟨ x i, ?_ ⟩
      simp at hx; obtain ⟨hx1, n, hn⟩ := hx
      exact ⟨hx1 i, ⟨n i, by rw [← hn]⟩⟩
    invFun x := by
      refine ⟨ .toLp 2 (fun i ↦ (x i).1), ?_ ⟩
      simp; constructor
      . intro i; exact (x i).2.1
      have h (i:Fin d) : ∃ y:ℤ, (N:ℝ)⁻¹ * y = (x i).1 := by
        obtain ⟨ w, hx ⟩ := (x i).2.2; exact ⟨w, by simpa using hx⟩
      choose y hy using h; use y; ext i; simp [hy i]
    left_inv x := by ext; simp
    right_inv x := by ext; simp
  }

/-- Lemma 1.1.2(ii), helper lemma: Sum of volumes equals limit of lattice counts over a disjoint union. -/
theorem Box.sum_vol_eq {d:ℕ} {T: Finset (Box d)}
 (hT: (T : Set (Box d)).PairwiseDisjoint Box.toSet) :
  Filter.atTop.Tendsto (fun N:ℕ ↦ (N:ℝ)^(-d:ℝ) * Nat.card ↥((⋃ B ∈ T, B.toSet) ∩ (Set.range (fun (n:Fin d → ℤ) ↦ .toLp 2 (fun i ↦ (N:ℝ)⁻¹*(n i))))))
  (nhds (∑ B ∈ T, |B|ᵥ)) := by
  sorry

/-- Lemma 1.1.2(ii): Two disjoint partitions of the same set have equal sums of volumes. -/
theorem Box.measure_uniq {d:ℕ} {T₁ T₂: Finset (Box d)}
 (hT₁: (T₁ : Set (Box d)).PairwiseDisjoint Box.toSet)
 (hT₂: (T₂ : Set (Box d)).PairwiseDisjoint Box.toSet)
 (heq: ⋃ B ∈ T₁, B.toSet = ⋃ B ∈ T₂, B.toSet) :
 ∑ B ∈ T₁, |B|ᵥ = ∑ B ∈ T₂, |B|ᵥ := by
  sorry

/-- The elementary measure of a set, defined as the sum of volumes over a disjoint partition. -/
noncomputable abbrev IsElementary.measure {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E) : ℝ
  := ∑ B ∈ hE.partition.choose, |B|ᵥ

/-- The measure equals the sum of volumes for any disjoint box partition of the set. -/
theorem IsElementary.measure_eq {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E)
  {T: Finset (Box d)} (hT: (T : Set (Box d)).PairwiseDisjoint Box.toSet)
  (heq : E = ⋃ B ∈ T, B.toSet):
  hE.measure = ∑ B ∈ T, |B|ᵥ := by
  sorry

/-- Exercise 1.1.2: give an alternate proof of this proposition by showing that
the two partitions {lean}`T₁`, {lean}`T₂` admit a mutual refinement into boxes arising from
taking Cartesian products of elements from finite collections of disjoint intervals. -/
theorem Box.measure_uniq' {d:ℕ} {T₁ T₂: Finset (Box d)}
 (hT₁: (T₁ : Set (Box d)).PairwiseDisjoint Box.toSet)
 (hT₂: (T₂ : Set (Box d)).PairwiseDisjoint Box.toSet)
 (heq: ⋃ B ∈ T₁, B.toSet = ⋃ B ∈ T₂, B.toSet) :
 ∑ B ∈ T₁, |B|ᵥ = ∑ B ∈ T₂, |B|ᵥ := by
  sorry

/-- Example: the measure of (1,2) ∪ \[3,6\] is 1 + 3 = 4. -/
example :
  let E : Set (EuclideanSpace' 1) := Real.equiv_EuclideanSpace' '' ((Set.Ioo 1 2) ∪ (Set.Icc 3 6))
  ∃ hE : IsElementary E, hE.measure = 4 := by
  sorry

/-- Elementary measure is always non-negative. -/
lemma IsElementary.measure_nonneg {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E) :
  0 ≤ hE.measure := by
  sorry

/-- Measure is additive on disjoint elementary sets: μ(E ∪ F) = μ(E) + μ(F). -/
lemma IsElementary.measure_of_disjUnion {d:ℕ} {E F: Set (EuclideanSpace' d)}
(hE: IsElementary E) (hF: IsElementary F) (hdisj: Disjoint E F):
  (hE.union hF).measure = hE.measure + hF.measure := by
  sorry

-- Helper lemmas for measure_of_disjUnion'

/-- Two different proofs that a set is elementary yield the same measure. -/
lemma IsElementary.measure_irrelevant {d:ℕ} {E: Set (EuclideanSpace' d)}
    (h₁ h₂ : IsElementary E) : h₁.measure = h₂.measure := by
  sorry

/-- If two elementary sets are equal, their measures are equal. -/
lemma IsElementary.measure_eq_of_set_eq {d:ℕ} {E F: Set (EuclideanSpace' d)}
    (hE: IsElementary E) (hF: IsElementary F) (h: E = F) :
    hE.measure = hF.measure := by
  sorry

open Classical in
/-- Measure of a sum over {lean}`insert a S'` equals the measure of {lean}`a` plus the measure of the sum over {lean}`S'`. -/
lemma IsElementary.sum_insert_split {d:ℕ} {a: Set (EuclideanSpace' d)} {S': Finset (Set (EuclideanSpace' d))}
    (ha : a ∉ S')
    (hE: ∀ E ∈ insert a S', IsElementary E) :
    ∑ E:(insert a S' : Finset (Set (EuclideanSpace' d))), (hE E.val E.property).measure =
    (hE a (Finset.mem_insert_self _ _)).measure +
    ∑ E:S', (hE E.val (Finset.mem_insert_of_mem E.property)).measure := by
  sorry

/-- Measure is additive on pairwise disjoint finsets of elementary sets. -/
lemma IsElementary.measure_of_disjUnion' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, IsElementary E) (hdisj: (S : Set (Set (EuclideanSpace' d))).PairwiseDisjoint id):
  (IsElementary.union' hE).measure = ∑ E:S, (hE E.val E.property).measure := by
  sorry

/-- The empty set has measure zero. -/
@[simp]
lemma IsElementary.measure_of_empty (d:ℕ) : (IsElementary.empty d).measure = 0 := by
  sorry

/-- The measure of a single box equals its volume. -/
@[simp]
lemma IsElementary.measure_of_box {d:ℕ} (B: Box d) : (IsElementary.box B).measure = |B|ᵥ := by
  sorry

/-- Elementary measure is monotone: if E ⊆ F then μ(E) ≤ μ(F). -/
lemma IsElementary.measure_mono  {d:ℕ} {E F: Set (EuclideanSpace' d)}
(hE: IsElementary E) (hF: IsElementary F) (hcont: E ⊆ F):
  hE.measure ≤ hF.measure := by
  sorry

/-- Subadditivity of measure on unions: μ(E ∪ F) ≤ μ(E) + μ(F). -/
lemma IsElementary.measure_of_union {d:ℕ} {E F: Set (EuclideanSpace' d)}
(hE: IsElementary E) (hF: IsElementary F):
  (hE.union hF).measure ≤ hE.measure + hF.measure := by
  sorry

/-- Subadditivity of measure on finset unions: μ(⋃ S) ≤ ∑ μ(E) for E ∈ S. -/
lemma IsElementary.measure_of_union' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, IsElementary E) :
  (IsElementary.union' hE).measure ≤ ∑ E:S, (hE E.val E.property).measure := by
  sorry

/-- Elementary measure is translation-invariant: μ(E + \{x\}) = μ(E). -/
lemma IsElementary.measure_of_translate {d:ℕ} {E: Set (EuclideanSpace' d)}
(hE: IsElementary E) (x: EuclideanSpace' d):
  (hE.translate x).measure = hE.measure := by
  sorry

/-- Exercise 1.1.3 (uniqueness of elementary measure): Any non-negative, additive, translation-invariant
function on elementary sets is a scalar multiple of the standard elementary measure. -/
theorem IsElementary.measure_uniq {d:ℕ} {m': (E: Set (EuclideanSpace' d)) → (IsElementary E) → ℝ}
  (hnonneg: ∀ E: Set (EuclideanSpace' d), ∀ hE: IsElementary E, m' E hE ≥ 0)
  (hadd: ∀ E F: Set (EuclideanSpace' d), ∀ (hE: IsElementary E) (hF: IsElementary F),
   Disjoint E F → m' (E ∪ F) (hE.union hF) = m' E hE + m' F hF)
  (htrans: ∀ E: Set (EuclideanSpace' d), ∀ (hE: IsElementary E) (x: EuclideanSpace' d), m' (E + {x}) (hE.translate x) = m' E hE) : ∃ c, c ≥ 0 ∧ ∀ E: Set (EuclideanSpace' d), ∀ hE: IsElementary E, m' E hE = c * hE.measure := by
  sorry

/-- The d-dimensional unit cube (0,1\]^d. -/
abbrev Box.unit_cube (d:ℕ) : Box d := { side := fun _ ↦ BoundedInterval.Ioc 0 1}

/-- Any measure satisfying normalization m'(unit cube) = 1 must equal the standard elementary measure. -/
theorem IsElementary.measure_uniq' {d:ℕ} {m': (E: Set (EuclideanSpace' d)) → (IsElementary E) → ℝ}
  (hnonneg: ∀ E: Set (EuclideanSpace' d), ∀ hE: IsElementary E, m' E hE ≥ 0)
  (hadd: ∀ E F: Set (EuclideanSpace' d), ∀ (hE: IsElementary E) (hF: IsElementary F),
   Disjoint E F → m' (E ∪ F) (hE.union hF) = m' E hE + m' F hF)
  (htrans: ∀ E: Set (EuclideanSpace' d), ∀ (hE: IsElementary E) (x: EuclideanSpace' d), m' (E + {x}) (hE.translate x) = m' E hE)
  (hcube : m' (Box.unit_cube d) (IsElementary.box _) = 1) :
  ∀ E: Set (EuclideanSpace' d), ∀ hE: IsElementary E, m' E hE = hE.measure := by
  sorry

/-- The Cartesian product of two boxes is a box in the sum dimension. -/
abbrev Box.prod {d₁ d₂:ℕ} (B₁: Box d₁) (B₂: Box d₂) : Box (d₁ + d₂) where
  side i := by
    obtain ⟨ i, hi ⟩ := i
    exact if h : i < d₁ then B₁.side ⟨i, h⟩ else (B₂.side ⟨i - d₁, by omega⟩)

/-- Exercise 1.1.4: The Cartesian product of two elementary sets is elementary. -/
theorem IsElementary.prod {d₁ d₂:ℕ} {E₁: Set (EuclideanSpace' d₁)} {E₂: Set (EuclideanSpace' d₂)}
  (hE₁: IsElementary E₁) (hE₂: IsElementary E₂) : IsElementary (EuclideanSpace'.prod E₁ E₂) := by
  sorry

/-- Measure is multiplicative on products: μ(E₁ × E₂) = μ(E₁) \* μ(E₂). -/
theorem IsElementary.measure_of_prod {d₁ d₂:ℕ} {E₁: Set (EuclideanSpace' d₁)} {E₂: Set (EuclideanSpace' d₂)}
  (hE₁: IsElementary E₁) (hE₂: IsElementary E₂)
  : (hE₁.prod hE₂).measure = hE₁.measure * hE₂.measure := by
  sorry
