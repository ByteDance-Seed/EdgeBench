import Analysis.MeasureTheory.Section_1_1_2

/-!
# Introduction to Measure Theory, Section 1.1.3: Connections with the Riemann integral

A companion to Section 1.1.3 of the book "An introduction to Measure Theory".

-/

open BoundedInterval

/-- Definition 1.1.5.  (Riemann integrability) The interval {lean}`I` should be closed, though we will not enforce this.  We also permit the length to be 0. We index the tags and deltas starting from 0 rather than 1
in the text as this is slightly more convenient in Lean. -/
@[ext]
structure TaggedPartition (I: BoundedInterval) (n:ℕ) where
  x : Fin (n+1) → ℝ
  x_tag : Fin n → ℝ
  x_start : x 0 = I.a
  x_end : x (Fin.last n) = I.b
  x_mono : StrictMono x
  x_tag_between (i: Fin n) : x i.castSucc ≤ x_tag i ∧ x_tag i ≤ x i.succ

-- The width of the i-th subinterval in a tagged partition.
def TaggedPartition.delta {I: BoundedInterval} {n:ℕ} (P: TaggedPartition I n) (i:Fin n): ℝ :=
 P.x i.succ - P.x i.castSucc

-- The mesh size (supremum of subinterval widths) of a tagged partition.
noncomputable def TaggedPartition.norm {I: BoundedInterval} {n:ℕ} (P: TaggedPartition I n) : ℝ := iSup P.delta

-- The Riemann sum of f with respect to a tagged partition: sum of f(tag_i) * delta_i.
def TaggedPartition.RiemannSum {I: BoundedInterval} {n:ℕ} (f: ℝ → ℝ) (P: TaggedPartition I n) : ℝ :=
  ∑ i, f (P.x_tag i) * P.delta i

/-- {given (type := "ℕ") -show}`n` {lean}`Sigma (TaggedPartition I)` is the type of all partitions of `I` with an unspecified number `n` of components.  Here we define what it means to converge to zero in this type. -/
-- A filter on Sigma (TaggedPartition I) converging to zero as the partition norm shrinks.
noncomputable def TaggedPartition.nhds_zero (I: BoundedInterval) : Filter (Sigma (TaggedPartition I)) := Filter.comap (fun P ↦ P.snd.norm) (nhds 0)

-- Riemann integrability: Riemann sums converge to R as the partition norm tends to zero.
def riemann_integral_eq (f: ℝ → ℝ) (I: BoundedInterval) (R: ℝ) : Prop := (TaggedPartition.nhds_zero I).Tendsto (fun P ↦ TaggedPartition.RiemannSum f P.snd) (nhds R)

/-- Construct a uniform partition of {lean}`[a,b]` into {lean}`n` equal pieces with left endpoint tags. -/
noncomputable def TaggedPartition.uniform (I: BoundedInterval) (n: ℕ) (hn: n > 0) (_: I = Icc I.a I.b) (hab: I.a < I.b) : TaggedPartition I n where
  x := fun i => I.a + (I.b - I.a) * (i.val : ℝ) / n
  x_tag := fun i => I.a + (I.b - I.a) * (i.castSucc.val : ℝ) / n
  x_start := by simp
  x_end := by
    show I.a + (I.b - I.a) * ((Fin.last n).val : ℝ) / n = I.b
    rw [Fin.val_last]
    field_simp; linarith
  x_mono i j hij := by
    have h_width_pos : 0 < I.b - I.a := by linarith
    have h_n_pos : 0 < (n : ℝ) := Nat.cast_pos.mpr hn
    have : (i.val : ℝ) < (j.val : ℝ) := Nat.cast_lt.mpr hij
    apply add_lt_add_right
    apply div_lt_div_of_pos_right
    · exact mul_lt_mul_of_pos_left this h_width_pos
    · exact h_n_pos
  x_tag_between i := by
    constructor
    · -- i.castSucc.val = i.val
      rfl
    · -- i.castSucc.val ≤ i.succ.val
      have h_width_nonneg : 0 ≤ I.b - I.a := by linarith
      have h_n_pos : 0 < (n : ℝ) := Nat.cast_pos.mpr hn
      show I.a + (I.b - I.a) * (i.castSucc.val : ℝ) / n ≤ I.a + (I.b - I.a) * (i.succ.val : ℝ) / n
      rw [show i.castSucc.val = i.val from rfl, Fin.val_succ]
      apply add_le_add_right
      apply div_le_div_of_nonneg_right
      · apply mul_le_mul_of_nonneg_left _ h_width_nonneg
        norm_num
      · linarith

/-- For any positive interval and δ > 0, there exists a tagged partition with norm ≤ δ. -/
lemma TaggedPartition.exists_norm_le (I: BoundedInterval) (hI: I = Icc I.a I.b) (hab: I.a < I.b) (δ : ℝ) (hδ : 0 < δ) :
    ∃ (n : ℕ) (P : TaggedPartition I n), P.norm ≤ δ := by
  sorry

/-- The filter `TaggedPartition.nhds_zero` is non-trivial when the interval has positive length. -/
instance TaggedPartition.nhds_zero_neBot (I: BoundedInterval) (hI: I = Icc I.a I.b) (hab: I.a < I.b) :
    Filter.NeBot (TaggedPartition.nhds_zero I) := by
  unfold TaggedPartition.nhds_zero
  rw [Filter.comap_neBot_iff]
  intro t ht
  -- t is a neighborhood of 0, so it contains some ball around 0
  rw [Metric.mem_nhds_iff] at ht
  obtain ⟨δ, hδ_pos, hδ_sub⟩ := ht
  -- Construct a partition with norm < δ
  obtain ⟨n, P, hP_norm⟩ := TaggedPartition.exists_norm_le I hI hab (δ / 2) (half_pos hδ_pos)
  use ⟨n, P⟩
  apply hδ_sub
  rw [Metric.mem_ball, Real.dist_eq, sub_zero, abs_of_nonneg]
  · calc P.norm ≤ δ / 2 := hP_norm
      _ < δ := half_lt_self hδ_pos
  · -- Show P.norm is nonnegative
    unfold TaggedPartition.norm
    by_cases h_n_zero : n = 0
    · subst h_n_zero
      simp [iSup]
    · have h_n_pos : n > 0 := Nat.pos_of_ne_zero h_n_zero
      let i0 : Fin n := ⟨0, h_n_pos⟩
      have h_delta_nonneg : 0 ≤ P.delta i0 := by
        unfold TaggedPartition.delta
        have h_lt : i0.castSucc < i0.succ := Fin.castSucc_lt_succ
        have h_x_lt : P.x i0.castSucc < P.x i0.succ := P.x_mono h_lt
        linarith
      have h_bdd : BddAbove (Set.range P.delta) := Set.Finite.bddAbove (Set.finite_range P.delta)
      have h_le_sup : P.delta i0 ≤ iSup P.delta := le_ciSup h_bdd i0
      linarith

/-- We enforce {lean}`I` to be closed and nonempty for the definition of Riemann integrability.
    The nonempty constraint ensures meaningful integration and excludes degenerate cases. -/
-- A function is Riemann integrable on a closed interval if Riemann sums converge to some value.
abbrev RiemannIntegrableOn (f: ℝ → ℝ) (I: BoundedInterval) : Prop :=
  I = Icc I.a I.b ∧ I.toSet.Nonempty ∧ ∃ R, riemann_integral_eq f I R

open Classical in
-- The Riemann integral value: the limit of Riemann sums (zero if not integrable).
noncomputable def riemannIntegral (f: ℝ → ℝ) (I: BoundedInterval) : ℝ := if h:RiemannIntegrableOn f I then h.2.2.choose else 0

/-- Definition 1.1.15 (Riemann integrability) -/
-- Characterization of the Riemann integral: R is the integral iff the Riemann sums converge to R.
lemma riemann_integral_eq_iff_of_integrable {f:ℝ → ℝ} {I: BoundedInterval} (h: RiemannIntegrableOn f I) (R:ℝ): riemann_integral_eq f I R ↔ R = riemannIntegral f I := by
  sorry

/-- Definition 1.1.15.  (Riemann integrability)  -/
-- Any function is Riemann integrable on a degenerate interval [a,a] with integral zero.
lemma RiemannIntegrable.of_zero_length (f: ℝ → ℝ) {I: BoundedInterval} {a : ℝ} (h: I = Icc a a) : RiemannIntegrableOn f I ∧ riemannIntegral f I = 0 := by
  sorry

/-- Helper: Modify a tagged partition by changing one tag -/
def TaggedPartition.changeTag {I: BoundedInterval} {n:ℕ} (P: TaggedPartition I n)
    (k: Fin n) (t: ℝ) (ht: P.x k.castSucc ≤ t ∧ t ≤ P.x k.succ) : TaggedPartition I n where
  x := P.x
  x_tag := Function.update P.x_tag k t
  x_start := P.x_start
  x_end := P.x_end
  x_mono := P.x_mono
  x_tag_between := fun i => by
    by_cases hik : i = k
    · subst hik; rw [Function.update_self]; exact ht
    · rw [Function.update_of_ne hik]; exact P.x_tag_between i

/-- For any x in \[a,b\], find the subinterval index containing x -/
noncomputable def findSubintervalIndex (lo hi : ℝ) (n : ℕ) (hn : n > 0) (x : ℝ) (_hx : lo ≤ x ∧ x ≤ hi) : Fin n :=
  let k := min (Nat.floor ((x - lo) / ((hi - lo) / n))) (n - 1)
  ⟨k, by omega⟩

/-- Definition 1.1.15 -/
theorem RiemannIntegrable.bounded {f: ℝ → ℝ} {I: BoundedInterval} (h: RiemannIntegrableOn f I) : ∃ M, ∀ x ∈ I, |f x| ≤ M := by
  sorry

@[ext]
-- A function that is constant on each interval in a partition of I.
structure PiecewiseConstantFunction (I: BoundedInterval) where
  f : ℝ → ℝ
  T : Finset BoundedInterval
  c : T → ℝ
  disjoint: (T : Set BoundedInterval).PairwiseDisjoint BoundedInterval.toSet
  cover : I.toSet = ⋃ J ∈ T, J.toSet
  const : ∀ J:T, ∀ x ∈ J.val, f x = c J

-- Two functions agree if they are equal on the interval I.
abbrev PiecewiseConstantFunction.agreesWith {I: BoundedInterval} (F: PiecewiseConstantFunction I) (f: ℝ → ℝ) : Prop := I.toSet.EqOn f F.f

-- A function is piecewise constant on I if it can be represented as a piecewise constant function.
def PiecewiseConstantOn (f: ℝ → ℝ) (I: BoundedInterval) : Prop := ∃ F: PiecewiseConstantFunction I, F.agreesWith f

-- The integral of a piecewise constant function: sum of (constant value × interval length) over all intervals.
def PiecewiseConstantFunction.integral {I: BoundedInterval} (g: PiecewiseConstantFunction I) : ℝ :=
  ∑ J : g.T, g.c J * |J|ₗ

/-- Exercise 1.1.20 (Piecewise constant functions) -/
-- The integral is well-defined: different representations of the same piecewise constant function have the same integral.
theorem PiecewiseConstantFunction.integral_eq (f: ℝ → ℝ) {I: BoundedInterval} (F F': PiecewiseConstantFunction I) (hF: F.agreesWith f) (hF': F'.agreesWith f) : F.integral = F'.integral := by
  sorry

-- The integral of a piecewise constant function on I.
noncomputable def PiecewiseConstantOn.integral (f: ℝ → ℝ) {I: BoundedInterval} (h: PiecewiseConstantOn f I) : ℝ := h.choose.integral

/-- Exercise 1.1.21 (a) (Linearity of the piecewise constant integral) -/
-- A scalar multiple of a piecewise constant function is piecewise constant.
theorem PiecewiseConstantOn.smul {I: BoundedInterval} (c:ℝ) {f: ℝ → ℝ} (h: PiecewiseConstantOn f I) : PiecewiseConstantOn (c • f) I := by
  sorry

/-- Exercise 1.1.21 (a) (Linearity of the piecewise constant integral) -/
-- The integral is linear: integral(c * f) = c * integral(f).
theorem PiecewiseConstantFunction.integral_smul {I:BoundedInterval} (c:ℝ) {f: ℝ → ℝ} (h: PiecewiseConstantOn f I) : (h.smul c).integral = h.integral := by
  sorry

/-- Exercise 1.1.21 (a) (Linearity of the piecewise constant integral) -/
-- The sum of two piecewise constant functions is piecewise constant.
theorem PiecewiseConstantOn.add {I: BoundedInterval} {f g: ℝ → ℝ} (hf: PiecewiseConstantOn f I) (hg: PiecewiseConstantOn g I) : PiecewiseConstantOn (f + g) I := by
  sorry

/-- Exercise 1.1.21 (a) (Linearity of the piecewise constant integral) -/
-- The integral is linear: integral(f + g) = integral(f) + integral(g).
theorem PiecewiseConstantFunction.integral_add {I: BoundedInterval} {f g: ℝ → ℝ} (hf: PiecewiseConstantOn f I) (hg: PiecewiseConstantOn g I) : (hf.add hg).integral = hf.integral + hg.integral := by
  sorry

/-- Exercise 1.1.21 (c) (Piecewise constant integral of indicator functions) -/
-- The indicator function of an elementary set is piecewise constant.
theorem PiecewiseConstantOn.indicator_of_elem (I: BoundedInterval) {E:Set ℝ} (hE: IsElementary (Real.equiv_EuclideanSpace' '' E) ) : PiecewiseConstantOn E.indicator' I := by
  sorry

/-- Exercise 1.1.21 (c) (Piecewise constant integral of indicator functions) -/
-- The integral of an indicator function of an elementary set equals its elementary measure.
theorem PiecewiseConstantFunction.integral_of_elem {I: BoundedInterval} {E:Set ℝ} (hE: IsElementary (Real.equiv_EuclideanSpace' '' E) ) (hsub: E ⊆ I.toSet) : (PiecewiseConstantOn.indicator_of_elem I hE).integral = hE.measure := by
  sorry

/-- Definition 1.1.6 (Darboux integral) -/
-- The lower Darboux integral: supremum of integrals of piecewise constant functions that underestimate f.
noncomputable def LowerDarbouxIntegral (f:ℝ → ℝ) (I: BoundedInterval) : ℝ := sSup { R | ∃ g: PiecewiseConstantFunction I, g.integral = R ∧ ∀ x ∈ I.toSet, g.f x ≤ f x }

/-- Definition 1.1.6 (Darboux integral) -/
-- The upper Darboux integral: infimum of integrals of piecewise constant functions that overestimate f.
noncomputable def UpperDarbouxIntegral (f:ℝ → ℝ) (I: BoundedInterval) : ℝ := sInf { R | ∃ h: PiecewiseConstantFunction I, h.integral = R ∧ ∀ x ∈ I.toSet, f x ≤ h.f x }

namespace PiecewiseConstantFunction
/-- Helper: Construct a constant piecewise constant function with a given value -/
def mkConst (I: BoundedInterval) (c: ℝ) : PiecewiseConstantFunction I where
  f := fun _ => c
  T := {I}
  c := fun _ => c
  disjoint := by simp [Set.pairwiseDisjoint_singleton]
  cover := by simp
  const := by intro J x hx; rfl

/-- Helper: Construct the negation of a piecewise constant function -/
def neg {I: BoundedInterval} (g: PiecewiseConstantFunction I) : PiecewiseConstantFunction I where
  f := fun x => -g.f x
  T := g.T
  c := fun J => -g.c J
  disjoint := g.disjoint
  cover := g.cover
  const := by
    intro J x hx
    have h_const : g.f x = g.c J := g.const J x hx
    simp [h_const]

/-- Helper: Convert a `PiecewiseConstantFunction` to `PiecewiseConstantOn` and relate integrals -/
lemma to_PiecewiseConstantOn {I: BoundedInterval} (g: PiecewiseConstantFunction I) :
    ∃ (h: PiecewiseConstantOn g.f I), h.integral = g.integral := by
  sorry

end PiecewiseConstantFunction

/-- Helper: The upper Darboux set is bounded below -/
lemma UpperDarbouxIntegral.bddBelow {f:ℝ → ℝ} {I: BoundedInterval} (M: ℝ) (hM: ∀ x ∈ I, |f x| ≤ M) :
    BddBelow ({ R | ∃ h: PiecewiseConstantFunction I, h.integral = R ∧ ∀ x ∈ I.toSet, f x ≤ h.f x } : Set ℝ) := by
  sorry

/-- Definition 1.1.6 (Darboux integral) -/
-- For any bounded function, the lower Darboux integral is at most the upper Darboux integral.
lemma lower_darboux_le_upper_darboux {f:ℝ → ℝ} {I: BoundedInterval} (hbound: ∃ M, ∀ x ∈ I, |f x| ≤ M) : LowerDarbouxIntegral f I ≤ UpperDarbouxIntegral f I := by
  sorry

/-- Definition 1.1.6 (Darboux integral) -/
-- A function is Darboux integrable if it is bounded and its lower and upper Darboux integrals coincide.
noncomputable def DarbouxIntegrableOn (f:ℝ → ℝ) (I: BoundedInterval) : Prop := (I = Icc I.a I.b) ∧ ∃ M, ∀ x ∈ I, |f x| ≤ M ∧ LowerDarbouxIntegral f I = UpperDarbouxIntegral f I

/-- We give the Darboux integral the "junk" value of the lower Darboux integral when the function is not integrable. -/
-- The Darboux integral: equals the common value if integrable, otherwise the lower Darboux integral.
noncomputable def darbouxIntegral (f:ℝ → ℝ) (I: BoundedInterval) : ℝ := LowerDarbouxIntegral f I

/-- Definition 1.1.6 (Darboux integral) -/
-- For the negation of a function, the upper Darboux integral of -f equals minus the lower Darboux integral of f.
lemma UpperDarbouxIntegral.neg {f:ℝ → ℝ} {I: BoundedInterval} (hbound: ∃ M, ∀ x ∈ I, |f x| ≤ M) : UpperDarbouxIntegral (-f) I = -LowerDarbouxIntegral f I := by
  sorry

/-- Exercise 1.1.22 -/
-- Riemann integrability is equivalent to Darboux integrability for bounded functions.
lemma RiemannIntegrableOn.iff_darbouxIntegrable {f:ℝ → ℝ} {I: BoundedInterval} (hbound: ∃ M, ∀ x ∈ I, |f x| ≤ M) : RiemannIntegrableOn f I ↔ DarbouxIntegrableOn f I := by
  sorry

/-- Exercise 1.1.22 -/
-- For Riemann integrable functions, the Riemann integral equals the Darboux integral.
lemma riemann_integral_eq_darboux_integral {f:ℝ → ℝ} {I: BoundedInterval} (hf: RiemannIntegrableOn f I) : riemannIntegral f I = darbouxIntegral f I := by
  sorry

/-- Exercise 1.1.23 -/
-- Any function continuous on a closed interval is Riemann integrable.
lemma RiemannIntegrableOn.continuous {f:ℝ → ℝ} {I: BoundedInterval} (hI: I = Icc I.a I.b) (hcont: ContinuousOn f I.toSet) : RiemannIntegrableOn f I := by
  sorry

-- A function that is continuous on each piece of a partition is Riemann integrable on the whole interval.
lemma RiemannIntegrableOn.piecewise_continuous {f:ℝ → ℝ} {I: BoundedInterval} (hI: I = Icc I.a I.b)
 (T: Finset BoundedInterval)  (hdisjoint: (T : Set BoundedInterval).PairwiseDisjoint BoundedInterval.toSet)
 (hcover : I.toSet = ⋃ J ∈ T, J.toSet) (hcont: ∀ J ∈ T, ContinuousOn f J.toSet) : RiemannIntegrableOn f I := by
  sorry

/-- Exercise 1.1.24 (a) (Linearity of the piecewise constant integral) -/
-- A scalar multiple of a Riemann integrable function is Riemann integrable.
theorem RiemannIntegrableOn.smul {I: BoundedInterval} (c:ℝ) {f: ℝ → ℝ} (h: RiemannIntegrableOn f I) : RiemannIntegrableOn (c • f) I := by
  sorry

/-- Exercise 1.1.24 (a) (Linearity of the piecewise constant integral) -/
-- The integral of a scalar multiple: integral(c * f) = c * integral(f).
theorem riemann_integral_smul {I:BoundedInterval} (c:ℝ) {f: ℝ → ℝ} (h: RiemannIntegrableOn f I) : riemannIntegral (c • f) = c • (riemannIntegral f) := by
  sorry

/-- Exercise 1.1.24 (a) (Linearity of the piecewise constant integral) -/
-- The sum of two Riemann integrable functions is Riemann integrable.
theorem RiemannIntegrableOn.add {I: BoundedInterval} {f g: ℝ → ℝ} (hf: RiemannIntegrableOn f I) (hg: RiemannIntegrableOn g I) : RiemannIntegrableOn (f + g) I := by
  sorry

/-- Exercise 1.1.24 (a) (Linearity of the piecewise constant integral) -/
-- The integral of a sum: integral(f + g) = integral(f) + integral(g).
theorem riemann_integral_add {I: BoundedInterval} {f g: ℝ → ℝ} (hf: RiemannIntegrableOn f I) (hg: RiemannIntegrableOn g I) : riemannIntegral (f+g) = riemannIntegral f + riemannIntegral g := by
  sorry

/-- Exercise 1.1.24 (b) (Monotonicity of the piecewise constant integral) -/
-- The integral is monotone: if f ≤ g pointwise, then integral(f) ≤ integral(g).
theorem riemann_integral_mono {I: BoundedInterval} {f g: ℝ → ℝ} (hf: RiemannIntegrableOn f I) (hg: RiemannIntegrableOn g I) (hmono: ∀ x ∈ I.toSet, f x ≤ g x): riemannIntegral f ≤ riemannIntegral g := by
  sorry

/-- Exercise 1.1.24 (c) (Indicator functions) -/
-- The indicator function of a Jordan measurable set is Riemann integrable.
theorem RiemannIntegrableOn.indicator_of_elem (I: BoundedInterval) {E:Set ℝ} (hE: JordanMeasurable (Real.equiv_EuclideanSpace' '' E) ) : RiemannIntegrableOn E.indicator' I := by
  sorry

/-- Exercise 1.1.24 (c) (Piecewise constant integral of indicator functions) -/
-- The integral of an indicator function equals the measure of the set it indicates.
theorem riemann_integral_of_elem {I: BoundedInterval} {E:Set ℝ} (hE: JordanMeasurable (Real.equiv_EuclideanSpace' '' E) ) (hsub: E ⊆ I.toSet) : riemannIntegral E.indicator' I = hE.measure := by
  sorry

/-- Exercise 1.1.24 (Uniqueness) -/
-- The Riemann integral is the unique integral satisfying linearity, monotonicity, and normalization on indicator functions.
theorem riemann_integral_unique {I: BoundedInterval} (integ: (ℝ → ℝ) → ℝ)
  (hsmul: ∀ (c:ℝ) (f: ℝ → ℝ) (hf: RiemannIntegrableOn f I), integ (c • f) = c • (integ f))
  (hadd: ∀ (f g: ℝ → ℝ) (hf: RiemannIntegrableOn f I) (hg: RiemannIntegrableOn g I), integ (f + g) = integ f + integ g)
  (hmono: ∀ (f g: ℝ → ℝ) (hf: RiemannIntegrableOn f I) (hg: RiemannIntegrableOn g I) (hmono: ∀ x ∈ I.toSet, f x ≤ g x), integ f ≤ integ g)
  (hindicator: ∀ (E:Set ℝ) (hE: JordanMeasurable (Real.equiv_EuclideanSpace' '' E) ) (hsub: E ⊆ I.toSet), integ E.indicator' = hE.measure) :
  ∀ f, RiemannIntegrableOn f I → integ f = riemannIntegral f I := by
  sorry

/-- Exercise 1.1.25 (Area interpretation of Riemann integral) -/
-- The region under the graph of a Riemann integrable function is Jordan measurable.
theorem RiemannIntegrableOn.measurable_upper {I: BoundedInterval}
  {f: ℝ → ℝ} (hfint: RiemannIntegrableOn f I) :
  JordanMeasurable { p:EuclideanSpace' 2 | p 0 ∈ I.toSet ∧ 0 ≤ p 1 ∧ p 1 ≤ f (p 0) } := by
  sorry

/-- Exercise 1.1.25 (Area interpretation of Riemann integral) -/
-- The region below the graph of a Riemann integrable function is Jordan measurable.
theorem RiemannIntegrableOn.measurable_lower {I: BoundedInterval}
  {f: ℝ → ℝ} (hfint: RiemannIntegrableOn f I) :
  JordanMeasurable { p:EuclideanSpace' 2 | p 0 ∈ I.toSet ∧ f (p 0) ≤ p 1 ∧ p 1 ≤ 0 } := by
  sorry

/-- Exercise 1.1.25 (Area interpretation of Riemann integral) -/
-- A function is Riemann integrable iff the regions above and below its graph are both Jordan measurable.
theorem JordanMeasurable.iff_integrable {I: BoundedInterval} (hI: I = Icc I.a I.b)
  {f: ℝ → ℝ} (hf: ∃ M, ∀ x ∈ I.toSet, |f x| ≤ M) : RiemannIntegrableOn f I ↔
  JordanMeasurable { p:EuclideanSpace' 2 | p 0 ∈ I.toSet ∧ 0 ≤ p 1 ∧ p 1 ≤ f (p 0) } ∧
  JordanMeasurable { p:EuclideanSpace' 2 | p 0 ∈ I.toSet ∧ f (p 0) ≤ p 1 ∧ p 1 ≤ 0 }
  := by
  sorry

/-- Exercise 1.1.25 (Area interpretation of Riemann integral) -/
-- The Riemann integral equals the difference between the measures of the upper and lower regions.
theorem RiemannIntegrableOn.eq_measure {I: BoundedInterval}
  {f: ℝ → ℝ} (hfint: RiemannIntegrableOn f I) :
  riemannIntegral f I = hfint.measurable_upper.measure - hfint.measurable_lower.measure := by
  sorry

/- Exercise 1.1.26: Extend the definition of the Riemann and Darboux integrals to higher dimensions, in such a way that analogues of all the previous results hold; state and prove those analogues. -/
