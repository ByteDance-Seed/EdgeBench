import Analysis.MeasureTheory.Section_1_3_1
import Mathlib.Algebra.Order.Floor.Semifield

set_option doc.verso.suggestions false

/-!
# Introduction to Measure Theory, Section 1.3.2: Measurable functions

A companion to (the introduction to) Section 1.3.2 of the book "An introduction to Measure Theory".

-/

def Unsigned {X Y:Type*} [LE Y] [Zero Y] (f:X → Y) : Prop := ∀ x, f x ≥ 0

def PointwiseConvergesTo {X Y:Type*} [TopologicalSpace Y] (f: ℕ → X → Y) (g: X → Y) : Prop := ∀ x, Filter.atTop.Tendsto (fun n ↦ f n x) (nhds (g x))

/-- Definition 1.3.8 (Unsigned measurable function) -/
def UnsignedMeasurable {d:ℕ} (f: EuclideanSpace' d → EReal) : Prop := Unsigned f ∧ ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n)) ∧ (PointwiseConvergesTo g f)

def EReal.BoundedFunction {X:Type*} (f:X → EReal) : Prop := ∃ M:NNReal, ∀ x, (f x).abs ≤ M

def FiniteMeasureSupport {d:ℕ} {Y:Type*} [Zero Y] (f: EuclideanSpace' d → Y) : Prop := Lebesgue_measure (Support f) < ⊤

def PointwiseAeConvergesTo {d:ℕ} {Y:Type*} [TopologicalSpace Y] (f: ℕ → (EuclideanSpace' d → Y)) (g: EuclideanSpace' d → Y) : Prop := AlmostAlways (fun x ↦ Filter.atTop.Tendsto (fun n ↦ f n x) (nhds (g x)))

/-!
## Helper lemmas for Lemma 1.3.9

The proof follows the book's implication chain. We establish explicit edges and
let `tfae_finish` compute the transitive closure.

**Explicit edges declared:**
- (i) ⟺ (ii): by definition of `UnsignedMeasurable`
- (ii) ⟹ (iii): pointwise everywhere implies pointwise a.e.
- (iv) ⟹ (ii): monotone sequences in \[0,∞\] converge to their supremum
- (iii) ⟹ (v): via limsup representation (main technical work)
- (v) ⟺ (vi): countable unions/intersections
- (vi) ⟺ (vii): complementation
- (v) ⟺ (viii): complementation
- (v)-(viii) ⟹ (ix): intervals are intersections of half-intervals
- (ix) ⟹ (x): open sets are countable unions of intervals
- (x) ⟺ (xi): complementation
- (x) ⟹ (vii): \{f < λ\} = f⁻¹'(`Set.Iio` λ) and `Set.Iio` λ is open
- (v)-(xi) ⟹ (iv): construction of approximating sequence

**Derived transitively (by `tfae_finish`):**
- (ix) ⟹ (v) or (vi): via (ix) → (x) → (vii) → (vi) → (v)
- (x) ⟹ (v)-(ix): via (x) → (vii) → (vi) → (v) → (viii)/(ix)
-/

namespace UnsignedMeasurable.TFAE_helpers

variable {d : ℕ} {f : EuclideanSpace' d → EReal}

-- Statement abbreviations for clarity (using indices as in the book)
private abbrev stmt_i (f : EuclideanSpace' d → EReal) := UnsignedMeasurable f
private abbrev stmt_ii (f : EuclideanSpace' d → EReal) :=
  ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n)) ∧ (∀ x, Filter.atTop.Tendsto (fun n ↦ g n x) (nhds (f x)))
private abbrev stmt_iii (f : EuclideanSpace' d → EReal) :=
  ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n)) ∧ (PointwiseAeConvergesTo g f)
private abbrev stmt_iv (f : EuclideanSpace' d → EReal) :=
  ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n) ∧ EReal.BoundedFunction (g n) ∧ FiniteMeasureSupport (g n)) ∧ (∀ x, Monotone (fun n ↦ g n x)) ∧ (∀ x, f x = iSup (fun n ↦ g n x))
private abbrev stmt_v (f : EuclideanSpace' d → EReal) := ∀ t, LebesgueMeasurable {x | f x > t}
private abbrev stmt_vi (f : EuclideanSpace' d → EReal) := ∀ t, LebesgueMeasurable {x | f x ≥ t}
private abbrev stmt_vii (f : EuclideanSpace' d → EReal) := ∀ t, LebesgueMeasurable {x | f x < t}
private abbrev stmt_viii (f : EuclideanSpace' d → EReal) := ∀ t, LebesgueMeasurable {x | f x ≤ t}
private abbrev stmt_ix (f : EuclideanSpace' d → EReal) := ∀ I:BoundedInterval, LebesgueMeasurable (f⁻¹' (Real.toEReal '' I.toSet))
private abbrev stmt_x (f : EuclideanSpace' d → EReal) := ∀ U: Set EReal, IsOpen U → LebesgueMeasurable (f⁻¹' U)
private abbrev stmt_xi (f : EuclideanSpace' d → EReal) := ∀ K: Set EReal, IsClosed K → LebesgueMeasurable (f⁻¹' K)

/-! # (i) ⟺ (ii): By definition of `UnsignedMeasurable` -/

/-! # (ii) ⟹ (iii): Pointwise everywhere implies pointwise a.e. -/

/-! # (iv) ⟹ (ii): Monotone sequences in \[0,∞\] converge to their supremum -/

/-! # (iii) ⟹ (v): Via limsup representation -/

-- Helper: Set.indicator' equals 1 when x ∈ E

-- Helper: Set.indicator' equals 0 when x ∉ E

-- Level sets of simple functions are Lebesgue measurable
private lemma UnsignedSimpleFunction.levelset_gt_LebesgueMeasurable
    {g : EuclideanSpace' d → EReal} (hg : UnsignedSimpleFunction g) (t : EReal) :
    LebesgueMeasurable {x | g x > t} := by
  sorry

-- The limsup set for (iii) ⟹ (v)
private def limsupSet (g : ℕ → EuclideanSpace' d → EReal) (t : EReal) : Set (EuclideanSpace' d) :=
  ⋃ (M : ℕ), ⋂ (N : ℕ), ⋃ n ∈ {n | n ≥ N}, {x | g n x > t + 1 / (M + 1)}

-- The limsup set is Lebesgue measurable when each g_n is a simple function
private lemma limsupSet_LebesgueMeasurable {g : ℕ → EuclideanSpace' d → EReal}
    (hg : ∀ n, UnsignedSimpleFunction (g n)) (t : EReal) :
    LebesgueMeasurable (limsupSet g t) := by
  sorry

-- This is the main technical work of the proof
private lemma iii_imp_v : stmt_iii f → stmt_v f := by
  sorry

/-! # (v) ⟹ (vi): \{f ≥ λ\} = ⋂\_\{n≥1\} \{f > λ - 1/n\} -/

-- Helper: if x > n for all n ∈ ℕ, then x = ⊤

private lemma v_imp_vi : stmt_v f → stmt_vi f := by
  sorry

/-! # (vi) ⟹ (v): \{f > λ\} = ⋃\_\{q ∈ ℚ, q > λ\} \{f ≥ q\} -/

private lemma vi_imp_v : stmt_vi f → stmt_v f := by
  sorry

/-! # (v) ⟹ (viii): \{f ≤ t\} = \{f > t\}ᶜ -/

private lemma v_imp_viii : stmt_v f → stmt_viii f := by
  sorry

/-! # (vi) ⟹ (vii): \{f < t\} = \{f ≥ t\}ᶜ -/

private lemma vi_imp_vii : stmt_vi f → stmt_vii f := by
  sorry

/-! # (vii) ⟹ (vi): \{f ≥ t\} = \{f < t\}ᶜ -/

private lemma vii_imp_vi : stmt_vii f → stmt_vi f := by
  sorry

/-! # (viii) ⟹ (v): \{f > t\} = \{f ≤ t\}ᶜ -/

private lemma viii_imp_v : stmt_viii f → stmt_v f := by
  sorry

/-! # (v)-(viii) ⟹ (ix): Intervals are intersections of half-intervals -/

private lemma v_to_viii_imp_ix (hv : stmt_v f) (hvi : stmt_vi f) (hvii : stmt_vii f) (hviii : stmt_viii f) :
    stmt_ix f := by
  sorry

/-! # (ix) ⟹ (x): Open sets are countable unions of intervals -/

-- For unsigned f, f⁻¹'({⊥}) = ∅

-- The embedded reals ℝ as a subset of EReal

-- ℝ embedded in EReal has Lebesgue measurable preimage
private lemma measurable_preimage_reals (hix : stmt_ix f) : LebesgueMeasurable (f⁻¹' (Set.range Real.toEReal)) := by
  sorry

-- {⊤} as complement of ℝ ∪ {⊥}

-- For unsigned f, f⁻¹'({⊤}) is Lebesgue measurable
private lemma measurable_preimage_top (hf : Unsigned f) (hix : stmt_ix f) : LebesgueMeasurable (f⁻¹' {⊤}) := by
  sorry

-- The intersection of an open set with ℝ can be expressed using countable intervals

private lemma ix_imp_x (hf : Unsigned f) : stmt_ix f → stmt_x f := by
  sorry

/-! # (x) ⟺ (xi): Complementation -/

private lemma x_iff_xi : stmt_x f ↔ stmt_xi f := by
  sorry

/-! # (x) ⟹ (vii): \{f < λ\} = f⁻¹'(`Set.Iio` λ) and `Set.Iio` λ is open -/

/-! # (v)-(xi) ⟹ (iv): Construction of approximating sequence -/

-- Helper: the norm ball centered at origin is Lebesgue measurable
private lemma normBall_LebesgueMeasurable (r : ℝ) :
    LebesgueMeasurable {x : EuclideanSpace' d | ‖x‖ ≤ r} := by
  sorry

-- The approximating function: f_n(x) = floor(min(f(x), n) * 2^n) / 2^n when |x| ≤ n, else 0
-- This is the largest k·2^{-n} ≤ min(f(x), n)
private noncomputable def approx_fn (f : EuclideanSpace' d → EReal) (n : ℕ) (x : EuclideanSpace' d) : EReal :=
  if ‖x‖ ≤ n then
    let t := min (f x) n
    if t = ⊥ then 0  -- won't happen for unsigned f
    else if t = ⊤ then n  -- t = min(⊤, n) = n, so this case shouldn't trigger
    else
      let r := t.toReal
      if r < 0 then 0  -- won't happen for unsigned f
      else ((⌊r * 2^n⌋₊ : ℕ) : ℝ) / (2^n : ℝ)
  else 0

-- Key lemma: approx_fn takes values in {k/2^n : k = 0, 1, ..., n·2^n}

-- Helper: approx_fn is always nonnegative for unsigned functions
  -- |x| > n case

-- Helper: floor approximation converges to the value as iSup
-- For r ≥ 0: r = ⨆ n, ⌊r * 2^n⌋₊ / 2^n (in EReal)

-- Helper: approx_fn simplifies to floor formula when f x is finite and r ≤ n

-- Helper: (n * 2^n) / 2^n = n in EReal

-- Helper: Extract equality from EReal division equality with 2^n denominator

-- Each level set of approx_fn is LebesgueMeasurable
-- The key observation: level sets are Boolean combinations of:
-- - {‖x‖ ≤ n} which is closed, hence LebesgueMeasurable
-- - {‖x‖ > n} which is open, hence LebesgueMeasurable
-- - {f x ≥ t} which is LebesgueMeasurable by hvi
-- - {f x < t} which is LebesgueMeasurable by hvii
private lemma approx_fn_levelset_LebesgueMeasurable (hf : Unsigned f) (hvi : stmt_vi f)
    (hvii : stmt_vii f) (n : ℕ) (v : EReal) :
    LebesgueMeasurable {x | approx_fn f n x = v} := by
  sorry

-- The main construction lemma
private lemma v_to_xi_imp_iv (hf : Unsigned f) (hvi : stmt_vi f) (hvii : stmt_vii f) :
    stmt_iv f := by
  sorry

end UnsignedMeasurable.TFAE_helpers

/-- Lemma 1.3.9 (Equivalent notions of measurability).  Some slight changes to the statement have been made to make the claims cleaner to state -/
theorem UnsignedMeasurable.TFAE {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: Unsigned f):
    [
      UnsignedMeasurable f,
      ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n)) ∧ (∀ x, Filter.atTop.Tendsto (fun n ↦ g n x) (nhds (f x))),
      ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n)) ∧ (PointwiseAeConvergesTo g f),
      ∃ (g: ℕ → EuclideanSpace' d → EReal), (∀ n, UnsignedSimpleFunction (g n) ∧  EReal.BoundedFunction (g n) ∧ FiniteMeasureSupport (g n)) ∧ (∀ x, Monotone (fun n ↦ g n x)) ∧ (∀ x, f x = iSup (fun n ↦ g n x)),
      ∀ t, LebesgueMeasurable {x | f x > t},
      ∀ t, LebesgueMeasurable {x | f x ≥ t},
      ∀ t, LebesgueMeasurable {x | f x < t},
      ∀ t, LebesgueMeasurable {x | f x ≤ t},
      ∀ I:BoundedInterval, LebesgueMeasurable (f⁻¹' (Real.toEReal '' I.toSet)),
      ∀ U: Set EReal, IsOpen U → LebesgueMeasurable (f⁻¹' U),
      ∀ K: Set EReal, IsClosed K → LebesgueMeasurable (f⁻¹' K)
    ].TFAE := by
  sorry

/-- Exercise 1.3.3(i) -/
theorem Continuous.UnsignedMeasurable {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: Continuous f) (hnonneg: Unsigned f): UnsignedMeasurable f := by
  sorry

/-- Exercise 1.3.3(iii) -/
theorem UnsignedMeasurable.sup {d:ℕ} {f: ℕ → EuclideanSpace' d → EReal} (hf: ∀ n, UnsignedMeasurable (f n)) : UnsignedMeasurable (fun x ↦ iSup (fun n ↦ f n x)) := by
  sorry

/-- Exercise 1.3.3(iii) -/
theorem UnsignedMeasurable.inf {d:ℕ} {f: ℕ → EuclideanSpace' d → EReal} (hf: ∀ n, UnsignedMeasurable (f n)) : UnsignedMeasurable (fun x ↦ iInf (fun n ↦ f n x)) := by
  sorry

/-- Exercise 1.3.3(iii) -/
theorem UnsignedMeasurable.limsup {d:ℕ} {f: ℕ → EuclideanSpace' d → EReal} (hf: ∀ n, UnsignedMeasurable (f n)) : UnsignedMeasurable (fun x ↦ Filter.atTop.limsup (fun n ↦ f n x) ) := by
  sorry

/-- Exercise 1.3.3(iii) -/
theorem UnsignedMeasurable.liminf {d:ℕ} {f: ℕ → EuclideanSpace' d → EReal} (hf: ∀ n, UnsignedMeasurable (f n)) : UnsignedMeasurable (fun x ↦ Filter.atTop.liminf (fun n ↦ f n x) ) := by
  sorry

/-- Exercise 1.3.3(iv) -/
theorem UnsignedMeasurable.aeEqual {d:ℕ} {f g: EuclideanSpace' d → EReal} (hf: UnsignedMeasurable f) (heq: AlmostEverywhereEqual f g) : UnsignedMeasurable g := by
  sorry

/-- Exercise 1.3.3(v) -/
theorem UnsignedMeasurable.aeLimit {d:ℕ} {f: EuclideanSpace' d → EReal} (g: ℕ → EuclideanSpace' d → EReal) (hf: ∀ n, UnsignedMeasurable (g n)) (heq: PointwiseAeConvergesTo g f) : UnsignedMeasurable f := by
  sorry

/-- Exercise 1.3.3(vi) -/
theorem UnsignedMeasurable.comp_cts {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedMeasurable f) {φ: EReal → EReal} (hφ: Continuous φ)  : UnsignedMeasurable (φ ∘ f) := by
  sorry

/-- Exercise 1.3.3(vii) -/
theorem UnsignedMeasurable.add {d:ℕ} {f g: EuclideanSpace' d → EReal} (hf: UnsignedMeasurable f) (hg: UnsignedMeasurable g) : UnsignedMeasurable (f + g) := by
  sorry

def UniformConvergesTo {X:Type*} (f: ℕ → X → EReal) (g: X → EReal) : Prop := ∀ ε:NNReal, ε > 0 → ∃ N:ℕ, ∀ n ≥ N, ∀ x, f n x > g x - ε ∧ f n x < g x + ε

/-- Exercise 1.3.4 -/
theorem UnsignedMeasurable.bounded_iff {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: Unsigned f) : UnsignedMeasurable f ∧ EReal.BoundedFunction f ↔ ∃ g : ℕ → EuclideanSpace' d → EReal, (∀ n, UnsignedSimpleFunction (g n) ∧ EReal.BoundedFunction (g n)) ∧ UniformConvergesTo g f := by
  sorry

/-- Exercise 1.3.5 -/
theorem UnsignedSimpleFunction.iff {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: Unsigned f) : UnsignedSimpleFunction f ↔ UnsignedMeasurable f ∧ Finite (f '' Set.univ) := by
  sorry

/-- Exercise 1.3.6 -/
theorem UnsignedMeasurable.measurable_graph {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedMeasurable f) : LebesgueMeasurable { p | ∃ x, ∃ t:ℝ, EuclideanSpace'.prod_equiv d 1 p = ⟨ x, t ⟩ ∧ 0 ≤ t ∧ t ≤ f x } := by
  sorry

/-!
## Remark 1.3.10: Measurable functions can have non-measurable preimages

We construct an example showing that even for a measurable function f: ℝ^d → \[0, +∞\],
the inverse image f⁻¹(E) of a Lebesgue measurable set E need not be Lebesgue measurable.

**Strategy** (from the textbook):
1. The Cantor set C := \{∑ aⱼ 3^(-j) : aⱼ ∈ \{0,2\}\} has measure zero
2. Define f: \[0,1\] → C by mapping binary digits to ternary: f(∑ bⱼ 2^(-j)) = ∑ 2bⱼ 3^(-j)
3. f is bijective from A (non-terminating binary decimals) onto C, and f is measurable
4. Take non-measurable F ⊆ A (from Vitali construction)
5. E := f(F) ⊆ C is measurable (subset of null set), but f⁻¹(E) = F is non-measurable

**Implementation note**: Our formalization differs slightly from the textbook:
- **Textbook**: f(x) = 0 for dyadic rationals (terminating binary decimals)
- **Our version**: f is defined uniformly for all x ∈ \[0,1\] using floor-based binary digits

The textbook's f is NOT monotone on \[0,1\] (e.g., f(0.4) > 0 but f(0.5) = 0).
Our f IS monotone on all of \[0,1\], which simplifies the measurability proof:
sublevel sets are intervals, hence measurable by Lemma 1.3.9(viii).

Both versions work for the theorem because:
- Both are injective on A (non-dyadic numbers have unique binary expansions)
- Both map \[0,1\] into `CantorSet` ∪ \{0\}
- Both give measurable f with f⁻¹(E) = F non-measurable
-/

/-- Dyadic rationals: numbers of the form k/2^n where k ≤ 2^n.
    These are exactly the real numbers with terminating binary expansions. -/
def DyadicRationals : Set ℝ := {x : ℝ | ∃ (k n : ℕ), x = k / 2^n ∧ k ≤ 2^n}

/-- Binary digit extraction: bⱼ(x) = ⌊2^j · x⌋ mod 2.
    For x ∈ \[0,1), this extracts the j-th binary digit.
    Special case: x = 1 has all digits = 1 (1 = 0.111...₂).
    For x ∉ \[0,1\], all digits are 0. -/
noncomputable def binaryDigit (x : ℝ) (j : ℕ) : ℕ :=
  if x ∈ Set.Ico (0:ℝ) 1 then ⌊(2:ℝ)^j * x⌋₊ % 2
  else if x = 1 then 1
  else 0

/-- The tail sum bound: ∑\_\{j≥k\} 2·(1/3)^(j+1) = (1/3)^k. -/
lemma tsum_tail_bound (k : ℕ) :
    ∑' j : ℕ, (2:ℝ) * (1/3:ℝ)^(k + j + 1) = (1/3:ℝ)^k := by
  sorry

namespace Remark_1_3_10

/-- The properties required of the binary-to-ternary function for this construction.
    The function maps \[0,1\] into the Cantor set C by converting binary digits to ternary.

    Note: Unlike the textbook (which sets g(x) = 0 for dyadic rationals), our g is defined
    uniformly for all x ∈ \[0,1\]. This makes g monotone on ALL of \[0,1\], not just on A. -/
structure BinaryToTernaryProperties (g : ℝ → ℝ) : Prop where
  nonneg : ∀ x, 0 ≤ g x
  bounded : ∀ x, g x ≤ 1
  zero_outside : ∀ x, x ∉ Set.Icc 0 1 → g x = 0  -- g(x) = 0 outside [0,1]
  zero_at_zero : g 0 = 0  -- g(0) = 0 (binary 0.000... maps to ternary 0.000...)
  zero_set_countable : (Set.Icc 0 1 ∩ {x | g x = 0}).Countable  -- {g = 0} ∩ [0,1] = {0}
  monotone_on : MonotoneOn g (Set.Icc 0 1)  -- g is monotone on ALL of [0,1]
  image_in_cantor : g '' (Set.Icc 0 1) ⊆ CantorSet ∪ {0}
  injective_on_nonterminating : ∃ A : Set ℝ, A ⊆ Set.Icc 0 1 ∧
    (Set.Icc 0 1 \ A).Countable ∧  -- A is co-countable in [0,1]
    Set.InjOn g A ∧                 -- g is injective on A (hence bijective onto g(A) ⊆ C)
    A ∩ DyadicRationals = ∅         -- A excludes dyadic rationals

/-- The binary-to-ternary function: g(x) = ∑\_\{j≥1\} 2·bⱼ(x)·3^(-j) for x ∈ \[0,1\], else 0. -/
noncomputable def binaryToTernaryFn (x : ℝ) : ℝ :=
  if x ∈ Set.Icc (0:ℝ) 1 then
    ∑' j : ℕ, (2 * binaryDigit x (j + 1) : ℝ) * (1/3:ℝ)^(j + 1)
  else 0

/-! # Helper lemmas for monotonicity proof -/

/-- For x, y ∈ \[0,1) with x < y, there exists a first position k where bₖ(x) < bₖ(y). -/
lemma binaryDigit_first_diff {x y : ℝ} (hx : x ∈ Set.Ico (0:ℝ) 1) (hy : y ∈ Set.Ico (0:ℝ) 1)
    (hxy : x < y) :
    ∃ k, binaryDigit x (k + 1) < binaryDigit y (k + 1) ∧
         ∀ j < k, binaryDigit x (j + 1) = binaryDigit y (j + 1) := by
  sorry

/-! # Helper lemmas for injectivity proof -/

/-! # Helper lemmas for binary expansion sums -/

/-! # Helper lemmas for image_in_cantor -/

/-- Existence of a binary-to-ternary function: g(x) = ∑ 2bⱼ 3^(-j). -/
lemma binaryToTernary_exists : ∃ g : ℝ → ℝ, BinaryToTernaryProperties g := by
  sorry

/-- Binary-to-ternary function: g(x) = ∑ 2·bⱼ(x)·3^(-j), monotone on \[0,1\], g(\[0,1\]) ⊆ C ∪ \{0\}. -/
noncomputable def binaryToTernary : ℝ → ℝ := Classical.choose binaryToTernary_exists

lemma binaryToTernary_props : BinaryToTernaryProperties binaryToTernary := by
  sorry

/-- {lean}`binaryToTernary x = 0` iff {lean}`x = 0` for x ∈ \[0,1\]. -/
lemma binaryToTernary_eq_zero_iff {x : ℝ} (hx : x ∈ Set.Icc (0:ℝ) 1) :
    binaryToTernary x = 0 ↔ x = 0 := by
  sorry

/-- `binaryToTernary` lifted to {lean}`EuclideanSpace' 1 → EReal` (called f in informal proof). -/
noncomputable def f_lifted : EuclideanSpace' 1 → EReal :=
  fun x => Real.toEReal (max 0 (binaryToTernary (EuclideanSpace'.equiv_Real x)))

lemma f_lifted_unsigned : Unsigned f_lifted := by
  sorry

lemma f_lifted_le_one (x : EuclideanSpace' 1) : f_lifted x ≤ 1 := by
  sorry

lemma f_lifted_zero_outside (x : EuclideanSpace' 1) (hx : EuclideanSpace'.equiv_Real x ∉ Set.Icc 0 1) :
    f_lifted x = 0 := by
  sorry

lemma f_lifted_zero_at_zero (x : EuclideanSpace' 1) (hx : EuclideanSpace'.equiv_Real x = 0) :
    f_lifted x = 0 := by
  sorry

lemma f_zero_set_in_interval_countable :
    (Set.Icc (0:ℝ) 1 ∩ {x | binaryToTernary x = 0}).Countable := by
  sorry

lemma f_lifted_zero_set_measurable : LebesgueMeasurable {x : EuclideanSpace' 1 | f_lifted x = 0} := by
  sorry

/-- Sublevel sets of `f_lifted` are measurable (key lemma for `f_lifted_measurable`). -/
lemma sublevel_set_measurable (t : EReal) (ht_pos : 0 < t) (ht_lt_one : t < 1) :
    LebesgueMeasurable {x : EuclideanSpace' 1 | f_lifted x ≤ t} := by
  sorry

lemma f_lifted_measurable : UnsignedMeasurable f_lifted := by
  sorry

/-- Non-measurable F ⊆ \[0,1\] with `binaryToTernary`(F) ⊆ Cantor set (Vitali construction). -/
lemma exists_nonmeasurable_with_cantor_image :
    ∃ F : Set ℝ, ∃ A : Set ℝ, F ⊆ Set.Icc 0 1 ∧
    ¬ LebesgueMeasurable (Real.equiv_EuclideanSpace' '' F) ∧
    binaryToTernary '' F ⊆ CantorSet ∧
    F ⊆ A ∧
    A ⊆ Set.Icc 0 1 ∧
    (Set.Icc 0 1 \ A).Countable ∧
    Set.InjOn binaryToTernary A := by
  sorry

end Remark_1_3_10

/-- Remark 1.3.10: The inverse image of a Lebesgue measurable set by a measurable function
    need not be Lebesgue measurable.
    Proof: Let f = `Remark_1_3_10.binaryToTernary` (maps \[0,1\] → Cantor set), F ⊆ \[0,1\] non-measurable (Vitali).
    Set E = f(F) ⊆ Cantor set. Then E is null (⊆ null set) hence measurable, but f⁻¹(E) = F
    is non-measurable. (Uses injectivity of f on non-dyadic rationals A ⊇ F.) -/
example : ∃ (f: EuclideanSpace' 1 → EReal) (_hf: UnsignedMeasurable f) (E: Set (EuclideanSpace' 1)) (_hE: LebesgueMeasurable E), ¬ LebesgueMeasurable (f⁻¹' ((Real.toEReal ∘ EuclideanSpace'.equiv_Real) '' E)) := by
  sorry

/-- Definition 1.3.11 (Complex measurability)-/
def ComplexMeasurable {d:ℕ} (f: EuclideanSpace' d → ℂ) : Prop := ∃ (g: ℕ → EuclideanSpace' d → ℂ), (∀ n, ComplexSimpleFunction (g n)) ∧ (PointwiseConvergesTo g f)

def RealMeasurable {d:ℕ} (f: EuclideanSpace' d → ℝ) : Prop := ∃ (g: ℕ → EuclideanSpace' d → ℝ), (∀ n, RealSimpleFunction (g n)) ∧ (PointwiseConvergesTo g f)

/-- Exercise 1.3.7 -/
theorem RealMeasurable.TFAE {d:ℕ} {f: EuclideanSpace' d → ℝ}:
    [
      RealMeasurable f,
      ∃ (g: ℕ → EuclideanSpace' d → ℝ), (∀ n, RealSimpleFunction (g n)) ∧ (PointwiseAeConvergesTo g f),
      UnsignedMeasurable (EReal.pos_fun f) ∧ UnsignedMeasurable (EReal.neg_fun f),
      ∀ U: Set ℝ, IsOpen U → MeasurableSet (f⁻¹' U),
      ∀ K: Set ℝ, IsClosed K → MeasurableSet (f⁻¹' K)
    ].TFAE
  := by
  sorry

theorem ComplexMeasurable.TFAE {d:ℕ} {f: EuclideanSpace' d → ℂ}:
    [
      ComplexMeasurable f,
      ∃ (g: ℕ → EuclideanSpace' d → ℂ), (∀ n, ComplexSimpleFunction (g n)) ∧ (PointwiseAeConvergesTo g f),
      RealMeasurable (Complex.re_fun f) ∧ RealMeasurable (Complex.im_fun f),
      UnsignedMeasurable (EReal.pos_fun (Complex.re_fun f)) ∧ UnsignedMeasurable (EReal.neg_fun (Complex.im_fun f)) ∧ UnsignedMeasurable (EReal.pos_fun (Complex.im_fun f)) ∧ UnsignedMeasurable (EReal.neg_fun (Complex.re_fun f)),
      ∀ U: Set ℂ, IsOpen U → MeasurableSet (f⁻¹' U),
      ∀ K: Set ℂ, IsClosed K → MeasurableSet (f⁻¹' K)
    ].TFAE
  := by
  sorry

theorem Continuous.ComplexMeasurable {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: Continuous f) : ComplexMeasurable f := by
  sorry

/-- Exercise 1.3.8(ii) -/
theorem UnsignedSimpleFunction.iff' {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: Unsigned f) : UnsignedSimpleFunction f ↔ UnsignedMeasurable f ∧ Finite (f '' Set.univ) := by
  sorry

/-- Exercise 1.3.8(iii) -/
theorem RealMeasurable.aeEqual {d:ℕ} {f g: EuclideanSpace' d → ℝ} (hf: RealMeasurable f) (heq: AlmostEverywhereEqual f g) : RealMeasurable g := by
  sorry

theorem ComplexMeasurable.aeEqual {d:ℕ} {f g: EuclideanSpace' d → ℂ} (hf: ComplexMeasurable f) (heq: AlmostEverywhereEqual f g) : ComplexMeasurable g := by
  sorry

/-- Exercise 1.3.8(iv) -/
theorem RealMeasurable.aeLimit {d:ℕ} {f: EuclideanSpace' d → ℝ} (g: ℕ → EuclideanSpace' d → ℝ) (hf: ∀ n, RealMeasurable (g n)) (heq: PointwiseAeConvergesTo g f) : RealMeasurable f := by
  sorry

theorem ComplexMeasurable.aeLimit {d:ℕ} {f: EuclideanSpace' d → ℂ} (g: ℕ → EuclideanSpace' d → ℂ) (hf: ∀ n, ComplexMeasurable (g n)) (heq: PointwiseAeConvergesTo g f) : ComplexMeasurable f := by
  sorry

/-- Exercise 1.3.8(v) -/
theorem RealMeasurable.comp_cts {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealMeasurable f) {φ: ℝ → ℝ} (hφ: Continuous φ)  : RealMeasurable (φ ∘ f) := by
  sorry

theorem ComplexMeasurable.comp_cts {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexMeasurable f) {φ: ℂ → ℂ} (hφ: Continuous φ)  : ComplexMeasurable (φ ∘ f) := by
  sorry

/-- Exercise 1.3.8(vi) -/
theorem RealMeasurable.mul {d:ℕ} {f g: EuclideanSpace' d → ℝ} (hf: RealMeasurable f) (hg: RealMeasurable g) : RealMeasurable (f * g) := by
  sorry

theorem ComplexMeasurable.mul {d:ℕ} {f g: EuclideanSpace' d → ℂ} (hf: ComplexMeasurable f) (hg: ComplexMeasurable g) : ComplexMeasurable (f * g) := by
  sorry

open Classical in
/-- Exercise 1.3.9 -/
theorem RealMeasurable.riemann_integrable {f: ℝ → ℝ} {I: BoundedInterval} (hf: RiemannIntegrableOn f I) : RealMeasurable ((fun x ↦ if x ∈ I.toSet then f x else 0) ∘ EuclideanSpace'.equiv_Real) := by
  sorry
