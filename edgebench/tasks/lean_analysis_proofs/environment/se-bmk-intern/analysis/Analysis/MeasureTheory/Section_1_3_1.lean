import Analysis.MeasureTheory.Section_1_2_3
import Analysis.Misc.NatBitwise

/-!
# Introduction to Measure Theory, Section 1.3.1: Integration of simple functions

A companion to (the introduction to) Section 1.3.1 of the book "An introduction to Measure Theory".

-/

-- some tools to convert between EReal-valued, ℝ-valued, and ℂ-valued functions

def EReal.abs_fun {X Y:Type*} [RCLike Y] (f: X → Y) : X → EReal := fun x ↦ ‖f x‖.toEReal
def Complex.re_fun {X:Type*} (f: X → ℂ) : X → ℝ := fun x ↦ Complex.re (f x)
def Complex.im_fun {X:Type*} (f: X → ℂ) : X → ℝ := fun x ↦ Complex.im (f x)
def Complex.conj_fun {X:Type*} (f: X → ℂ) : X → ℂ := fun x ↦ starRingEnd ℂ (f x)
def EReal.pos_fun {X:Type*} (f: X → ℝ) : X → EReal := fun x ↦ (max (f x) 0).toEReal
def EReal.neg_fun {X:Type*} (f: X → ℝ) : X → EReal := fun x ↦ (max (-f x) 0).toEReal
def Real.complex_fun {X:Type*} (f: X → ℝ) : X → ℂ := fun x ↦ Complex.ofReal (f x)
def Real.EReal_fun {X:Type*} (f: X → ℝ) : X → EReal := fun x ↦ Real.toEReal (f x)

noncomputable def EReal.indicator {X:Type*} (A: Set X) : X → EReal := Real.EReal_fun A.indicator'

noncomputable def Complex.indicator {X:Type*} (A: Set X) : X → ℂ := Real.complex_fun A.indicator'

/-- Definition 1.3.2 -/
def UnsignedSimpleFunction {d:ℕ} (f: EuclideanSpace' d → EReal) : Prop := ∃ (k:ℕ) (c: Fin k → EReal) (E: Fin k → Set (EuclideanSpace' d)),
  (∀ i, LebesgueMeasurable (E i) ∧ c i ≥ 0) ∧ f = ∑ i, (c i) • (EReal.indicator (E i))

def RealSimpleFunction {d:ℕ} (f: EuclideanSpace' d → ℝ) : Prop := ∃ (k:ℕ) (c: Fin k → ℝ) (E: Fin k → Set (EuclideanSpace' d)),
  (∀ i, LebesgueMeasurable (E i)) ∧ f = ∑ i, (c i) • (E i).indicator'

def ComplexSimpleFunction {d:ℕ} (f: EuclideanSpace' d → ℂ) : Prop := ∃ (k:ℕ) (c: Fin k → ℂ) (E: Fin k → Set (EuclideanSpace' d)),
  (∀ i, LebesgueMeasurable (E i)) ∧ f = ∑ i, (c i) • (Complex.indicator (E i))

-- TODO: coercions between these concepts, and vector space structure on real and complex simple functions (and cone structure on unsigned simple functions).

@[coe]
abbrev RealSimpleFunction.toComplex {d:ℕ} (f: EuclideanSpace' d → ℝ) (df: RealSimpleFunction f) : ComplexSimpleFunction (Real.complex_fun f) := by
  obtain ⟨k, c, E, hmes, heq⟩ := df
  use k, fun i => Complex.ofReal (c i), E
  constructor
  · exact hmes
  · ext x
    simp only [Real.complex_fun, Complex.indicator, heq]
    simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
    rw [Complex.ofReal_sum]
    congr 1
    ext i
    exact Complex.ofReal_mul (c i) ((E i).indicator' x)

instance RealSimpleFunction.coe_complex {d:ℕ} (f: EuclideanSpace' d → ℝ) : Coe (RealSimpleFunction f) (ComplexSimpleFunction (Real.complex_fun f)) := {
  coe := RealSimpleFunction.toComplex f
}

lemma UnsignedSimpleFunction.add {d:ℕ} {f g: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) (hg: UnsignedSimpleFunction g) : UnsignedSimpleFunction (f + g) := by
  sorry

lemma RealSimpleFunction.add {d:ℕ} {f g: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) (hg: RealSimpleFunction g) : RealSimpleFunction (f + g) := by
  sorry

lemma ComplexSimpleFunction.add {d:ℕ} {f g: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) (hg: ComplexSimpleFunction g) : ComplexSimpleFunction (f + g) := by
  sorry

lemma RealSimpleFunction.smul {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) (a: ℝ)  : RealSimpleFunction (a • f) := by
  sorry

lemma ComplexSimpleFunction.smul {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) (a: ℂ)  : ComplexSimpleFunction (a • f) := by
  sorry

lemma ComplexSimpleFunction.conj {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : ComplexSimpleFunction (Complex.conj_fun f) := by
  sorry

noncomputable def UnsignedSimpleFunction.integ {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) : EReal := ∑ i, (hf.choose_spec.choose i) * Lebesgue_measure (hf.choose_spec.choose_spec.choose i)

/-! ## Helper lemmas for Lemma 1.3.4

The proof uses a Venn diagram argument: given two representations of the same simple function,
we partition R^d into atoms (intersections of all sets and their complements), express each
original set as a disjoint union of atoms, and use finite additivity of Lebesgue measure.
-/

namespace UnsignedSimpleFunction.IntegralWellDef

open scoped Classical

/-- {given -show}`k, k'` Given families of sets indexed by {lean}`Fin k` and {lean}`Fin k'`, an atom is determined by
    a choice of “in” or “out” for each set. We encode this as a {lean}`Fin (2^(k+k'))` index. -/
def atomMembership (_k _k' : ℕ) (n : ℕ) (i : ℕ) : Bool := (n / 2^i) % 2 = 1

/-- The atom indexed by n is the intersection over all $`i` of ($`E_i` if bit $`i` is 1, else $`E_i^c`) -/
def atom {X : Type*} {k k' : ℕ} (E : Fin k → Set X) (E' : Fin k' → Set X) (n : Fin (2^(k+k'))) : Set X :=
  {x | (∀ i : Fin k, atomMembership k k' n i ↔ x ∈ E i) ∧
       (∀ i : Fin k', atomMembership k k' n (k + i) ↔ x ∈ E' i)}

/-- Helper: construct atom index from membership pattern.
    The atom index encodes x's membership in each set as bits. -/
noncomputable def atomIndexOf {X : Type*} [DecidableEq X] {k k' : ℕ} (E : Fin k → Set X) (E' : Fin k' → Set X) (x : X) : ℕ :=
  (Finset.univ.filter fun j : Fin k => x ∈ E j).sum (fun j => 2^j.val) +
  (Finset.univ.filter fun j' : Fin k' => x ∈ E' j').sum (fun j' => 2^(k + j'.val))

/-- Original set E\_i is the union of atoms where bit i is 1 -/
lemma set_eq_biUnion_atoms {X : Type*} {k k' : ℕ} (E : Fin k → Set X) (E' : Fin k' → Set X) (i : Fin k) :
    E i = ⋃ n ∈ {n : Fin (2^(k+k')) | atomMembership k k' n i}, atom E E' n := by
  sorry

/-- Original set E'\_i is the union of atoms where bit (k+i) is 1 -/
lemma set_eq_biUnion_atoms' {X : Type*} {k k' : ℕ} (E : Fin k → Set X) (E' : Fin k' → Set X) (i : Fin k') :
    E' i = ⋃ n ∈ {n : Fin (2^(k+k')) | atomMembership k k' n (k + i)}, atom E E' n := by
  sorry

/-- Atoms are measurable if the original sets are -/
lemma atom_measurable {d k k' : ℕ} {E : Fin k → Set (EuclideanSpace' d)} {E' : Fin k' → Set (EuclideanSpace' d)}
    (hE : ∀ i, LebesgueMeasurable (E i)) (hE' : ∀ i, LebesgueMeasurable (E' i)) (n : Fin (2^(k+k'))) :
    LebesgueMeasurable (atom E E' n) := by
  sorry

/-- The weighted measure sum for a representation -/
noncomputable def weightedMeasureSum {d k : ℕ} (c : Fin k → EReal) (E : Fin k → Set (EuclideanSpace' d)) : EReal :=
  ∑ i, (c i) * Lebesgue_measure (E i)

/-- Core lemma: Two representations of the same function give the same weighted measure sum.
    This is the heart of Lemma 1.3.4 (Venn diagram argument). -/
lemma weightedMeasureSum_eq_of_eq {d k k' : ℕ}
    {c : Fin k → EReal} {E : Fin k → Set (EuclideanSpace' d)}
    {c' : Fin k' → EReal} {E' : Fin k' → Set (EuclideanSpace' d)}
    (hmes : ∀ i, LebesgueMeasurable (E i)) (hmes' : ∀ i, LebesgueMeasurable (E' i))
    (hnonneg : ∀ i, c i ≥ 0) (hnonneg' : ∀ i, c' i ≥ 0)
    (heq : ∑ i, (c i) • (EReal.indicator (E i)) = ∑ i, (c' i) • (EReal.indicator (E' i))) :
    weightedMeasureSum c E = weightedMeasureSum c' E' := by
  sorry

/-! ## Single-family atoms (k' = 0 specialization)

When working with a single family of sets (no second family to compare against),
we specialize the atom machinery with k' = 0. -/

/-- The atom for a single family of sets, using k' = 0 in the general atom definition -/
def singleAtom {X : Type*} {k : ℕ} (E : Fin k → Set X) (n : Fin (2^k)) : Set X :=
  atom E (fun _ : Fin 0 => ∅) ⟨n.val, by simp only [add_zero]; exact n.isLt⟩

/-- Every point is in exactly one singleAtom -/
lemma exists_unique_singleAtom {X : Type*} [DecidableEq X] {k : ℕ} (E : Fin k → Set X) (x : X) :
    ∃! n : Fin (2^k), x ∈ singleAtom E n := by
  sorry

/-- The value on atom n is the sum of coefficients for sets containing that atom -/
noncomputable def atomValue {k : ℕ} (c : Fin k → ℝ) (n : Fin (2^k)) : ℝ :=
  ∑ i : Fin k, if n.val.testBit i.val then c i else 0

end UnsignedSimpleFunction.IntegralWellDef

/-- Lemma 1.3.4 (Well-definedness of simple integral) -/
lemma UnsignedSimpleFunction.integral_eq {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) {k:ℕ} {c: Fin k → EReal}
    {E: Fin k → Set (EuclideanSpace' d)} (hmes: ∀ i, LebesgueMeasurable (E i)) (hnonneg: ∀ i, c i ≥ 0)
    (heq: f = ∑ i, (c i) • (EReal.indicator (E i))) :
    hf.integ = ∑ i, (c i) * Lebesgue_measure (E i) := by
  sorry

/-- Definition 1.3.5 -/
def AlmostAlways {d:ℕ} (P: EuclideanSpace' d → Prop) : Prop :=
  IsNull { x | ¬ P x }

/-- Definition 1.3.5 -/
def AlmostEverywhereEqual {d:ℕ} {X: Type*} (f g: EuclideanSpace' d → X) : Prop :=
  AlmostAlways (fun x ↦ f x = g x)

/-- Definition 1.3.5 -/
def Support {X Y: Type*} [Zero Y] (f: X → Y) : Set X := { x | f x ≠ 0 }

lemma UnsignedSimpleFunction.support_measurable {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) : LebesgueMeasurable (Support f) := by
  sorry

lemma AlmostAlways.ofAlways {d:ℕ} {P: EuclideanSpace' d → Prop} (h: ∀ x, P x) : AlmostAlways P := by
  sorry

lemma AlmostAlways.mp {d:ℕ} {P Q: EuclideanSpace' d → Prop} (hP: AlmostAlways P) (himp: ∀ x, P x → Q x) : AlmostAlways Q := by
  sorry

lemma AlmostAlways.countable {d:ℕ} {I: Type*} [Countable I] {P: I → EuclideanSpace' d → Prop} (hP: ∀ i, AlmostAlways (P i)) : AlmostAlways (fun x ↦ ∀ i, P i x) := by
  sorry

/-- Almost everywhere equality is an equivalence relation -/
theorem AlmostEverywhereEqual.equivalence {d:ℕ} {X: Type*} :
    Equivalence (@AlmostEverywhereEqual d X) := by
  sorry

/-- Exercise 1.3.1 (i) (Unsigned linearity) -/
lemma UnsignedSimpleFunction.integral_add {d:ℕ} {f g: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) (hg: UnsignedSimpleFunction g) :
  (hf.add hg).integ = hf.integ + hg.integ := by
  sorry

/-- Exercise 1.3.1 (ii) (Finiteness) -/
lemma UnsignedSimpleFunction.integral_finite_iff {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) :
  (hf.integ < ⊤) ↔ (AlmostAlways (fun x ↦ f x < ⊤)) ∧ (Lebesgue_measure (Support f)) < ⊤ := by
  sorry

/-- Exercise 1.3.1 (iii) (Vanishing) -/
lemma UnsignedSimpleFunction.integral_eq_zero_iff {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) :
  (hf.integ = 0) ↔ AlmostAlways (fun x ↦ f x = 0) := by
  sorry

/-- Exercise 1.3.1 (v) (Monotonicity) -/
lemma UnsignedSimpleFunction.integral_le_integral_of_aeLe {d:ℕ} {f g: EuclideanSpace' d → EReal} (hf: UnsignedSimpleFunction f) (hg: UnsignedSimpleFunction g)
  (hae: AlmostAlways (fun x ↦ f x ≤ g x)) :
  hf.integ ≤ hg.integ := by
  sorry

lemma RealSimpleFunction.abs {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : UnsignedSimpleFunction (EReal.abs_fun f) := by
  sorry

lemma ComplexSimpleFunction.abs {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : UnsignedSimpleFunction (EReal.abs_fun f) := by
  sorry

/-- Definition 1.3.6 (Absolutely convergent simple integral) -/
def RealSimpleFunction.AbsolutelyIntegrable {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : Prop :=
  (hf.abs).integ < ⊤

/-- Definition 1.3.6 (Absolutely convergent simple integral) -/
def ComplexSimpleFunction.AbsolutelyIntegrable {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : Prop :=
  (hf.abs).integ < ⊤

/-! ## Disjoint representation for `RealSimpleFunction`

Measure-theory specific lemmas for the disjoint representation of simple functions. -/

namespace RealSimpleFunction.DisjointRepr

open UnsignedSimpleFunction.IntegralWellDef

/-- Single atoms are measurable -/
lemma singleAtom_measurable {d k : ℕ} {E : Fin k → Set (EuclideanSpace' d)}
    (hE : ∀ i, LebesgueMeasurable (E i)) (n : Fin (2^k)) :
    LebesgueMeasurable (singleAtom E n) := by
  sorry

/-- The original function equals the sum over atoms with atomValue coefficients -/
lemma eq_sum_atomValue_indicator {d k : ℕ} (c : Fin k → ℝ) (E : Fin k → Set (EuclideanSpace' d)) :
    (∑ i : Fin k, (c i) • (E i).indicator') = ∑ n : Fin (2^k), (atomValue c n) • (singleAtom E n).indicator' := by
  sorry

end RealSimpleFunction.DisjointRepr

/-- Disjoint representation: any `RealSimpleFunction` has an equivalent representation
    with pairwise disjoint, measurable sets. -/
lemma RealSimpleFunction.disjoint_representation {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) :
    ∃ (n:ℕ) (v: Fin n → ℝ) (A: Fin n → Set (EuclideanSpace' d)),
      (∀ i, LebesgueMeasurable (A i)) ∧
      Set.univ.PairwiseDisjoint A ∧
      f = ∑ i, (v i) • (A i).indicator' := by
  sorry

def RealSimpleFunction.pos {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : UnsignedSimpleFunction (EReal.pos_fun f) := by
  -- Use disjoint representation: f = ∑ i, v_i • A_i.indicator' with disjoint A_i
  obtain ⟨n, v, A, hA_meas, hA_disj, heq⟩ := hf.disjoint_representation
  -- The positive part is ∑ i, (max(v_i, 0)).toEReal • EReal.indicator(A_i)
  use n, fun i => (max (v i) 0).toEReal, A
  constructor
  · intro i
    constructor
    · exact hA_meas i
    · exact EReal.coe_nonneg.mpr (le_max_right (v i) 0)
  · ext x
    simp only [EReal.pos_fun, Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
    -- Since atoms are disjoint, x is in at most one atom
    by_cases hx_in : ∃ j, x ∈ A j
    · -- x is in exactly one atom due to disjointness (we use exists version)
      obtain ⟨j, hj⟩ := hx_in
      -- The sum on both sides only has one nonzero term
      have hlhs : f x = v j := by
        rw [heq]
        simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
        rw [Finset.sum_eq_single j]
        · simp only [Set.indicator'_of_mem hj, mul_one]
        · intro i _ hi_ne
          have hx_notin : x ∉ A i := by
            intro hx_in_i
            have := hA_disj (Set.mem_univ i) (Set.mem_univ j) hi_ne
            simp only [Function.onFun, Set.disjoint_left] at this
            exact this hx_in_i hj
          simp only [Set.indicator'_of_notMem hx_notin, mul_zero]
        · intro h; exact absurd (Finset.mem_univ j) h
      have hrhs : (∑ i : Fin n, (max (v i) 0).toEReal * EReal.indicator (A i) x) =
                  (max (v j) 0).toEReal := by
        rw [Finset.sum_eq_single j]
        · simp only [EReal.indicator, Real.EReal_fun, Set.indicator'_of_mem hj, EReal.coe_one, mul_one]
        · intro i _ hi_ne
          have hx_notin : x ∉ A i := by
            intro hx_in_i
            have := hA_disj (Set.mem_univ i) (Set.mem_univ j) hi_ne
            simp only [Function.onFun, Set.disjoint_left] at this
            exact this hx_in_i hj
          simp only [EReal.indicator, Real.EReal_fun, Set.indicator'_of_notMem hx_notin, EReal.coe_zero, mul_zero]
        · intro h; exact absurd (Finset.mem_univ j) h
      rw [hlhs, hrhs]
    · -- x is not in any atom, so f(x) = 0
      push_neg at hx_in
      have hlhs : f x = 0 := by
        rw [heq]
        simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
        apply Finset.sum_eq_zero
        intro i _
        simp only [Set.indicator'_of_notMem (hx_in i), mul_zero]
      have hrhs : (∑ i : Fin n, (max (v i) 0).toEReal * EReal.indicator (A i) x) = 0 := by
        apply Finset.sum_eq_zero
        intro i _
        simp only [EReal.indicator, Real.EReal_fun, Set.indicator'_of_notMem (hx_in i), EReal.coe_zero, mul_zero]
      rw [hlhs, hrhs]
      simp only [max_self, EReal.coe_zero]

def RealSimpleFunction.neg {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : UnsignedSimpleFunction (EReal.neg_fun f) := by
  -- neg_fun f = pos_fun (-f), and -f = (-1) • f is a simple function
  have h : EReal.neg_fun f = EReal.pos_fun ((-1 : ℝ) • f) := by
    ext x; simp only [EReal.neg_fun, EReal.pos_fun, Pi.smul_apply, smul_eq_mul, neg_one_mul]
  rw [h]
  exact (hf.smul (-1)).pos

noncomputable def RealSimpleFunction.integ {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : ℝ := (hf.pos).integ.toReal - (hf.neg).integ.toReal

def ComplexSimpleFunction.re {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : RealSimpleFunction (Complex.re_fun f) := by
  -- If f = ∑ i, c_i • Complex.indicator(E_i), then Re(f) = ∑ i, Re(c_i) • indicator'(E_i)
  obtain ⟨k, c, E, hmes, heq⟩ := hf
  use k, fun i => (c i).re, E
  constructor
  · exact hmes
  · ext x
    simp only [Complex.re_fun, heq, Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
    -- Goal: (∑ i, c i * Complex.indicator (E i) x).re = ∑ i, (c i).re * (E i).indicator' x
    rw [Complex.re_sum]
    congr 1; ext i
    -- Goal: (c i * Complex.indicator (E i) x).re = (c i).re * (E i).indicator' x
    simp only [Complex.indicator, Real.complex_fun]
    rw [Complex.re_mul_ofReal]

def ComplexSimpleFunction.im {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : RealSimpleFunction (Complex.im_fun f) := by
  -- If f = ∑ i, c_i • Complex.indicator(E_i), then Im(f) = ∑ i, Im(c_i) • indicator'(E_i)
  obtain ⟨k, c, E, hmes, heq⟩ := hf
  use k, fun i => (c i).im, E
  constructor
  · exact hmes
  · ext x
    simp only [Complex.im_fun, heq, Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
    -- Goal: (∑ i, c i * Complex.indicator (E i) x).im = ∑ i, (c i).im * (E i).indicator' x
    rw [Complex.im_sum]
    congr 1; ext i
    -- Goal: (c i * Complex.indicator (E i) x).im = (c i).im * (E i).indicator' x
    simp only [Complex.indicator, Real.complex_fun]
    rw [Complex.im_mul_ofReal]

noncomputable def ComplexSimpleFunction.integ {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : ℂ :=
  hf.re.integ + Complex.I * hf.im.integ

lemma ComplexSimpleFunction.absolutelyIntegrable_iff {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : hf.AbsolutelyIntegrable ↔ Lebesgue_measure (Support f) < ⊤ := by
  sorry

lemma RealSimpleFunction.AbsolutelyIntegrable.add {d:ℕ} {f g: EuclideanSpace' d → ℝ} {hf: RealSimpleFunction f} {hg: RealSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) :
  (hf.add hg).AbsolutelyIntegrable := by
  sorry

lemma ComplexSimpleFunction.AbsolutelyIntegrable.add {d:ℕ} {f g: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} {hg: ComplexSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) :
  (hf.add hg).AbsolutelyIntegrable := by
  sorry

lemma RealSimpleFunction.AbsolutelyIntegrable.smul {d:ℕ} {f: EuclideanSpace' d → ℝ} {hf: RealSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) (a: ℝ) :
  (hf.smul a).AbsolutelyIntegrable := by
  sorry

lemma ComplexSimpleFunction.AbsolutelyIntegrable.smul {d:ℕ} {f: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) (a: ℂ) :
  (hf.smul a).AbsolutelyIntegrable := by
  sorry

lemma ComplexSimpleFunction.AbsolutelyIntegrable.conj {d:ℕ} {f: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) :
  (hf.conj).AbsolutelyIntegrable := by
  sorry

/-- Exercise 1.3.2 (i) ({lit}`*`-linearity) -/
lemma RealSimpleFunction.integ_add {d:ℕ} {f g: EuclideanSpace' d → ℝ} {hf: RealSimpleFunction f} {hg: RealSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) : (hf.add hg).integ = hf.integ + hg.integ := by
  sorry

lemma ComplexSimpleFunction.integ_add {d:ℕ} {f g: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} {hg: ComplexSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) : (hf.add hg).integ = hf.integ + hg.integ := by
  sorry

/-- Exercise 1.3.2 (i) ({lit}`*`-linearity) -/
lemma RealSimpleFunction.integ_smul {d:ℕ} {f: EuclideanSpace' d → ℝ} {hf: RealSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) (a: ℝ) : (hf.smul a).integ = a * hf.integ := by
  sorry

lemma ComplexSimpleFunction.integ_smul {d:ℕ} {f: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) (a: ℂ) : (hf.smul a).integ = a * hf.integ := by
  sorry

/-- Exercise 1.3.2 (i) ({lit}`*`-linearity) -/
lemma ComplexSimpleFunction.integral_conj {d:ℕ} {f: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} (hf_integ: hf.AbsolutelyIntegrable) : (hf.conj).integ = (starRingEnd ℂ) hf.integ := by
  sorry

/-- Exercise 1.3.2 (ii) (equivalence) -/
lemma RealSimpleFunction.integral_eq_integral_of_aeEqual {d:ℕ} {f g: EuclideanSpace' d → ℝ} {hf: RealSimpleFunction f} {hg: RealSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) (h_ae: AlmostEverywhereEqual f g) : hf.integ = hg.integ := by
  sorry

lemma ComplexSimpleFunction.integral_eq_integral_of_aeEqual {d:ℕ} {f g: EuclideanSpace' d → ℂ} {hf: ComplexSimpleFunction f} {hg: ComplexSimpleFunction g} (hf_integ: hf.AbsolutelyIntegrable) (hg_integ: hg.AbsolutelyIntegrable) (h_ae: AlmostEverywhereEqual f g) : hf.integ = hg.integ := by
  sorry

/-- Exercise 1.3.2(iii) (Compatibility with Lebesgue measure) -/
lemma RealSimpleFunction.indicator {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: LebesgueMeasurable E) :
  RealSimpleFunction (E.indicator') := by
  sorry

lemma ComplexSimpleFunction.indicator {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: LebesgueMeasurable E) :
  ComplexSimpleFunction (Complex.indicator E) := by
  sorry

/-- Exercise 1.3.2(iii) (Compatibility with Lebesgue measure) -/
lemma RealSimpleFunction.integral_indicator {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: LebesgueMeasurable E) (hfin: Lebesgue_measure E < ⊤): (RealSimpleFunction.indicator hE).integ = (Lebesgue_measure E).toReal := by
  sorry

lemma ComplexSimpleFunction.integral_indicator {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: LebesgueMeasurable E) (hfin: Lebesgue_measure E < ⊤): (ComplexSimpleFunction.indicator hE).integ = (Lebesgue_measure E).toReal := by
  sorry
