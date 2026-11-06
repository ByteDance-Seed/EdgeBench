import Analysis.MeasureTheory.Section_1_1_1
import Mathlib.LinearAlgebra.AffineSpace.Simplex.Basic

/-!
# Introduction to Measure Theory, Section 1.1.2: Jordan measure

A companion to Section 1.1.2 of the book "An introduction to Measure Theory".

-/

/-- Definition 1.1.4.  We intend these concepts to only be applied for bounded sets {lean}`E`, but
it is convenient to permit {lean}`E` to be unbounded for the purposes of making the definitions.
-/
noncomputable abbrev Jordan_inner_measure {d:ℕ} (E: Set (EuclideanSpace' d)) : ℝ :=
  sSup { m:ℝ | ∃ (A: Set (EuclideanSpace' d)), ∃ hA: IsElementary A, A ⊆ E ∧ m = hA.measure }

noncomputable abbrev Jordan_outer_measure {d:ℕ} (E: Set (EuclideanSpace' d)) : ℝ :=
  sInf { m:ℝ | ∃ (A: Set (EuclideanSpace' d)), ∃ hA: IsElementary A, E ⊆ A ∧ m = hA.measure }

/-- A bounded set is Jordan measurable if its inner and outer Jordan measures coincide. -/
noncomputable abbrev JordanMeasurable {d:ℕ} (E: Set (EuclideanSpace' d)) : Prop :=
  Bornology.IsBounded E ∧ Jordan_inner_measure E = Jordan_outer_measure E

/-- The Jordan measure of a Jordan measurable set (equals both inner and outer measure). -/
noncomputable abbrev JordanMeasurable.measure {d:ℕ} {E: Set (EuclideanSpace' d)} (_: JordanMeasurable E) : ℝ :=
  Jordan_inner_measure E

/-- Jordan measure equals the inner Jordan measure by definition. -/
theorem JordanMeasurable.eq_inner {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E) : hE.measure = Jordan_inner_measure E := by
  sorry

/-- For Jordan measurable sets, the measure also equals the outer Jordan measure. -/
theorem JordanMeasurable.eq_outer {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E) : hE.measure = Jordan_outer_measure E := by
  sorry

/-- The inner Jordan measure is always non-negative. -/
theorem Jordan_inner_measure_nonneg {d:ℕ} (E: Set (EuclideanSpace' d)) : 0 ≤ Jordan_inner_measure E := by
  sorry

/-- The outer Jordan measure is always non-negative. -/
theorem Jordan_outer_measure_nonneg {d:ℕ} (E: Set (EuclideanSpace' d)) : 0 ≤ Jordan_outer_measure E := by
  sorry

/-- For bounded sets, inner Jordan measure is at most outer Jordan measure. -/
theorem Jordan_inner_le_outer {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) : Jordan_inner_measure E ≤ Jordan_outer_measure E := by
  sorry

/-- Elementary measure of a subset is a lower bound for inner Jordan measure. -/
theorem le_Jordan_inner {d:ℕ} {E A: Set (EuclideanSpace' d)}
  (hA: IsElementary A) (hAE: A ⊆ E) : hA.measure ≤ Jordan_inner_measure A := by
  sorry

/-- Elementary measure of a superset is an upper bound for outer Jordan measure. -/
theorem Jordan_outer_le {d:ℕ} {E A: Set (EuclideanSpace' d)}
  (hA: IsElementary A) (hAE: E ⊆ A) : Jordan_outer_measure A ≤ hA.measure := by
  sorry

/-- If m < inner measure, there exists an elementary subset with measure > m. -/
theorem Jordan_inner_le {d:ℕ} {E: Set (EuclideanSpace' d)} {m:ℝ}
  (hm: m < Jordan_inner_measure E) : ∃ A: Set (EuclideanSpace' d), ∃ hA: IsElementary A, A ⊆ E ∧ m < hA.measure := by
  sorry

/-- If outer measure < m, there exists an elementary superset with measure < m. -/
theorem le_Jordan_outer {d:ℕ} {E: Set (EuclideanSpace' d)} {m:ℝ}
  (hm: Jordan_outer_measure E < m) (hbound: Bornology.IsBounded E) :
  ∃ A: Set (EuclideanSpace' d), ∃ hA: IsElementary A, E ⊆ A ∧ hA.measure < m := by
  sorry

/-- Exercise 1.1.5 -/
-- Equivalent characterizations of Jordan measurability: inner and outer measures coincide.
theorem JordanMeasurable.equiv {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) :
 [JordanMeasurable E,
  ∀ ε>0, ∃ A, ∃ B, ∃ hA: IsElementary A, ∃ hB: IsElementary B,
    A ⊆ E ∧ E ⊆ B ∧ (hB.sdiff hA).measure ≤ ε,
  ∀ ε>0, ∃ A, ∃ hA: IsElementary A, Jordan_outer_measure (symmDiff E A) ≤ ε].TFAE := by
  sorry

/-- Every elementary set is Jordan measurable. -/
theorem IsElementary.jordanMeasurable {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E) : JordanMeasurable E := by
  sorry

/-- The Jordan measure of an elementary set equals its elementary measure. -/
theorem JordanMeasurable.mes_of_elementary {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E) : hE.jordanMeasurable.measure = hE.measure := by
  sorry

/-- The empty set is Jordan measurable. -/
theorem JordanMeasurable.empty (d:ℕ) : JordanMeasurable (∅: Set (EuclideanSpace' d)) := by
  sorry

/-- The empty set has Jordan measure zero. -/
@[simp]
theorem JordanMeasurable.mes_of_empty (d:ℕ) : (JordanMeasurable.empty d).measure = 0 := by
  sorry

/-- Exercise 1.1.6 (i) (Boolean closure) -/
theorem JordanMeasurable.union {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) : JordanMeasurable (E ∪ F) := by
  sorry

/-- The union of a finset of Jordan measurable sets is Jordan measurable. -/
lemma JordanMeasurable.union' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, JordanMeasurable E) : JordanMeasurable (⋃ E ∈ S, E) := by
  sorry

/-- Exercise 1.1.6 (i) (Boolean closure) -/
theorem JordanMeasurable.inter {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) : JordanMeasurable (E ∩ F) := by
  sorry

/-- Exercise 1.1.6 (i) (Boolean closure) -/
theorem JordanMeasurable.sdiff {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) : JordanMeasurable (E \ F) := by
  sorry

/-- Exercise 1.1.6 (i) (Boolean closure) -/
theorem JordanMeasurable.symmDiff {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) : JordanMeasurable (symmDiff E F) := by
  sorry

/-- Exercise 1.1.6 (ii) (non-negativity) -/
theorem JordanMeasurable.nonneg {d:ℕ} {E : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) : 0 ≤ hE.measure := by
  sorry

/- Exercise 1.1.6 (iii) (finite additivity) -/
noncomputable section JordanFiniteAdditivityLemmas

/-
The sum of the inner Jordan measures of two disjoint bounded sets is at most the inner Jordan measure of their union.
-/
theorem Jordan_inner_add_le {d:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: Bornology.IsBounded E) (hF: Bornology.IsBounded F) (hdisj: Disjoint E F) :
  Jordan_inner_measure E + Jordan_inner_measure F ≤ Jordan_inner_measure (E ∪ F) := by
  sorry

/-
The outer Jordan measure is subadditive for bounded sets.
-/
theorem Jordan_outer_subadd {d:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: Bornology.IsBounded E) (hF: Bornology.IsBounded F) :
  Jordan_outer_measure (E ∪ F) ≤ Jordan_outer_measure E + Jordan_outer_measure F := by
  sorry

end JordanFiniteAdditivityLemmas

theorem JordanMeasurable.mes_of_disjUnion {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) (hEF: Disjoint E F)
  : (hE.union hF).measure = hE.measure + hF.measure := by
  sorry

/-- Exercise 1.1.6 (iii) (finite additivity) -/
lemma JordanMeasurable.measure_of_disjUnion' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, JordanMeasurable E) (hdisj: (S : Set (Set (EuclideanSpace' d))).PairwiseDisjoint id):
  (JordanMeasurable.union' hE).measure = ∑ E:S, (hE E.val E.property).measure := by
  sorry

/-- Exercise 1.1.6 (iv) (monotonicity) -/
theorem JordanMeasurable.mono {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F) (hEF: E ⊆ F)
  : hE.measure ≤ hF.measure := by
  sorry

/-- Exercise 1.1.6 (v) (finite subadditivity) -/
theorem JordanMeasurable.mes_of_union {d:ℕ} {E F : Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F)
  : (hE.union hF).measure ≤ hE.measure + hF.measure := by
  sorry

/-- Exercise 1.1.6 (v) (finite subadditivity) -/
lemma JordanMeasurable.measure_of_union' {d:ℕ} {S: Finset (Set (EuclideanSpace' d))}
(hE: ∀ E ∈ S, JordanMeasurable E) :
  (JordanMeasurable.union' hE).measure ≤ ∑ E:S, (hE E.val E.property).measure := by
  sorry

open Pointwise

/-- Exercise 1.1.6 (vi) (translation invariance) -/
theorem JordanMeasurable.translate {d:ℕ} {E: Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (x: EuclideanSpace' d) : JordanMeasurable (E + {x}) := by
  sorry

/-- Exercise 1.1.6 (vi) (translation invariance) -/
lemma JordanMeasurable.measure_of_translate {d:ℕ} {E: Set (EuclideanSpace' d)}
(hE: JordanMeasurable E) (x: EuclideanSpace' d):
  (hE.translate x).measure ≤ hE.measure := by
  sorry

/-- Exercise 1.1.7 (i) (Regions under graphs are Jordan measurable) -/
lemma JordanMeasurable.graph {d:ℕ} {B:Box d} {f: EuclideanSpace' d → ℝ} (hf: ContinuousOn f B.toSet) : JordanMeasurable { p | ∃ x ∈ B.toSet, EuclideanSpace'.prod_equiv d 1 p = ⟨ x, f x ⟩ } := by
  sorry

/-- Exercise 1.1.7 (i) (Regions under graphs are Jordan measurable) -/
lemma JordanMeasurable.measure_of_graph {d:ℕ} {B:Box d} {f: EuclideanSpace' d → ℝ} (hf: ContinuousOn f B.toSet) : (JordanMeasurable.graph hf).measure = 0 := by
  sorry

/-- Exercise 1.1.7 (i) (Regions under graphs are Jordan measurable) -/
lemma JordanMeasurable.undergraph {d:ℕ} {B:Box d} {f: EuclideanSpace' d → ℝ} (hf: ContinuousOn f B.toSet) : JordanMeasurable { p | ∃ x ∈ B.toSet, ∃ t:ℝ, EuclideanSpace'.prod_equiv d 1 p = ⟨ x, t ⟩ ∧ 0 ≤ t ∧ t ≤ f x } := by
  sorry

/-- Exercise 1.1.8 -/
-- A triangle is Jordan measurable.
lemma JordanMeasurable.triangle (T: Affine.Triangle ℝ (EuclideanSpace' 2)) : JordanMeasurable T.closedInterior := by
  sorry

/-- The 2D wedge product (signed area parallelogram factor) of two vectors. -/
abbrev EuclideanSpace'.plane_wedge (x y: EuclideanSpace' 2) := x 1 * y 0 - x 0 * y 1

/-- Exercise 1.1.8 -/
-- The Jordan measure of a triangle equals half the absolute value of the wedge product of two edge vectors.
lemma JordanMeasurable.measure_triangle (T: Affine.Triangle ℝ (EuclideanSpace' 2)) : (JordanMeasurable.triangle T).measure = |(T.points 1 - T.points 0).plane_wedge (T.points 2 - T.points 0)| / 2 := by
  sorry

/-- Exercise 1.1.9  A polytope is the convex hull of a finite set of vertices. -/
abbrev IsPolytope {d:ℕ} (P: Set (EuclideanSpace' d)) : Prop :=
  ∃ (V: Finset (EuclideanSpace' d)), P = convexHull ℝ (V : Set _)

/-- Exercise 1.1.9: Every polytope is Jordan measurable. -/
lemma JordanMeasurable.polytope {d:ℕ} {P: Set (EuclideanSpace' d)} (hP: IsPolytope P) : JordanMeasurable P := by
  sorry

/-- Exercise 1.1.10 (1) -/
-- An open ball is Jordan measurable.
lemma JordanMeasurable.ball {d:ℕ} (x₀: EuclideanSpace' d) {r: ℝ} (hr: 0 < r) : JordanMeasurable (Metric.ball x₀ r) := by
  sorry

/-- Exercise 1.1.10 (1) -/
-- A closed ball is Jordan measurable.
lemma JordanMeasurable.closedBall {d:ℕ} (x₀: EuclideanSpace' d) {r: ℝ} (hr: 0 < r) : JordanMeasurable (Metric.closedBall x₀ r) := by
  sorry

/-- Exercise 1.1.10 (1) -/
-- The Jordan measure of a ball is proportional to r^d with a dimension-dependent constant.
lemma JordanMeasurable.measure_ball (d:ℕ) : ∃ c, ∀ (x₀: EuclideanSpace' d) (r: ℝ) (hr: 0 < r), (ball x₀ hr).measure = c * r^d := by
  sorry

/-- The Jordan measure of a closed ball equals that of the open ball. -/
lemma JordanMeasurable.measure_closedBall {d:ℕ} (x₀: EuclideanSpace' d) {r: ℝ} (hr: 0 < r): (closedBall x₀ hr).measure = (ball x₀ hr).measure := by
  sorry

/-- Exercise 1.1.10 (2) -/
-- The ball measure constant is bounded above by 2^d.
lemma JordanMeasurable.measure_ball_le (d:ℕ) : (measure_ball d).choose ≤ 2^d := by
  sorry

/-- Exercise 1.1.10 (2) -/
-- The ball measure constant is bounded below by 2^d / d!.
lemma JordanMeasurable.le_measure_ball (d:ℕ) : 2^d/d.factorial ≤ (measure_ball d).choose := by
  sorry

/-- Exercise 1.1.11 (1) -/
-- The linear image of an elementary set is Jordan measurable.
lemma JordanMeasurable.linear_of_elem {d:ℕ} (T: EuclideanSpace' d ≃ₗ[ℝ] EuclideanSpace' d)
{E: Set (EuclideanSpace' d)} (hE: IsElementary E): JordanMeasurable (T '' E) := by
  sorry

/-- Exercise 1.1.11 (1) -/
-- The measure of a linear image of an elementary set scales by a fixed factor depending on the transformation.
lemma JordanMeasurable.measure_linear_of_elem {d:ℕ} (T: EuclideanSpace' d ≃ₗ[ℝ] EuclideanSpace' d) : ∃ D > 0, ∀ (E: Set (EuclideanSpace' d)) (hE: IsElementary E), (linear_of_elem T hE).measure = D * hE.measure := by
  sorry

/-- Exercise 1.1.11 (2) -/
-- The linear image of a Jordan measurable set is Jordan measurable.
lemma JordanMeasurable.linear {d:ℕ} (T: EuclideanSpace' d ≃ₗ[ℝ] EuclideanSpace' d)
{E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E): JordanMeasurable (T '' E) := by
  sorry

/-- Exercise 1.1.11 (2) -/
-- The measure of a linear image of a Jordan measurable set equals the original measure (up to determinant scaling).
lemma JordanMeasurable.measure_linear {d:ℕ} (T: EuclideanSpace' d ≃ₗ[ℝ] EuclideanSpace' d) :
∃ D > 0, ∀ (E: Set (EuclideanSpace' d)) (hE: JordanMeasurable E), (linear T hE).measure = hE.measure := by
  sorry

/-- An invertible matrix defines a linear equivalence on Euclidean space. -/
noncomputable def Matrix.linear_equiv {d:ℕ} (A: Matrix (Fin d) (Fin d) ℝ) [Invertible A] :
EuclideanSpace' d ≃ₗ[ℝ] EuclideanSpace' d where
  toFun x := .toLp 2 (toLin' A x.ofLp)
  map_add' x y := by
    apply PiLp.ext; intro i; simp [map_add]
  map_smul' r x := by
    apply PiLp.ext; intro i; simp [map_smul]
  invFun x := .toLp 2 (toLin' A⁻¹ x.ofLp)
  left_inv x := by
    apply PiLp.ext; intro i; simp
  right_inv x := by
    apply PiLp.ext; intro i; simp

/-- Exercise 1.1.11 (3) -/
-- For a linear map from an invertible matrix, the measure scaling factor equals the absolute value of the determinant.
lemma JordanMeasurable.measure_linear_det {d:ℕ} (A: Matrix (Fin d) (Fin d) ℝ) [Invertible A] :
(measure_linear A.linear_equiv).choose = |A.det| := by
  sorry

/-- A set is Jordan null if it is Jordan measurable with measure zero. -/
abbrev JordanMeasurable.null {d:ℕ} (E: Set (EuclideanSpace' d)) : Prop := ∃ hE: JordanMeasurable E, hE.measure = 0

/-- A set is Jordan null iff it's bounded with outer Jordan measure zero. -/
lemma JordanMeasurable.null_iff {d:ℕ} {E: Set (EuclideanSpace' d)} : null E ↔ Bornology.IsBounded E ∧ Jordan_outer_measure E = 0 := by
  sorry

/-- Exercise 1.1.12 -/
-- A subset of a Jordan null set is also Jordan null.
lemma JordanMeasurable.null_mono {d:ℕ} {E F: Set (EuclideanSpace' d)} (h: null E) (hEF: F ⊆ E) : null F := by
  sorry

/-- Exercise 1.1.13 -/
-- The Jordan measure equals the limit of scaled lattice point counts in the set.
theorem JordanMeasure.measure_eq {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E):
  Filter.atTop.Tendsto (fun N:ℕ ↦ (N:ℝ)^(-d:ℝ) * Nat.card ↥(E ∩ (Set.range (fun (n:Fin d → ℤ) ↦ .toLp 2 (fun i ↦ (N:ℝ)⁻¹*(n i))))))
  (nhds hE.measure) := by
  sorry

/-- A dyadic box at scale 2^(-n) with multi-index i: the half-open cube \[i/2^n, (i+1)/2^n). -/
noncomputable abbrev Box.dyadic {d:ℕ} (n:ℤ) (i:Fin d → ℤ) : Box d where
  side j := BoundedInterval.Ico ((i j)/2^n) ((i j + 1)/2^n)

/-- Lower metric entropy: count of dyadic boxes at scale n fully contained in E. -/
noncomputable abbrev metric_entropy_lower {d:ℕ} (E: Set (EuclideanSpace' d)) (n:ℤ) : ℕ := Nat.card { i:Fin d → ℤ | (Box.dyadic n i).toSet ⊆ E }

/-- Upper metric entropy: count of dyadic boxes at scale n that intersect E. -/
noncomputable abbrev metric_entropy_upper {d:ℕ} (E: Set (EuclideanSpace' d)) (n:ℤ) : ℕ := Nat.card { i:Fin d → ℤ | (Box.dyadic n i).toSet ∩ E ≠ ∅ }

/-- Exercise 1.1.14 -/
-- Jordan measurability is characterized by convergence of scaled dyadic metric entropy difference to zero.
theorem JordanMeasure.iff {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) :
  JordanMeasurable E ↔ Filter.atTop.Tendsto (fun n ↦ (2:ℝ)^(-(d*n:ℤ)) * ((metric_entropy_upper E n - metric_entropy_lower E n))) (nhds 0) := by
  sorry

/-- Jordan measure equals the limit of scaled lower metric entropy. -/
theorem JordanMeasure.eq_lim_lower {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E) :
   Filter.atTop.Tendsto (fun n ↦ (2:ℝ)^(-(d*n:ℤ)) * (metric_entropy_lower E n)) (nhds hE.measure) := by
  sorry

/-- Jordan measure equals the limit of scaled upper metric entropy. -/
theorem JordanMeasure.eq_lim_upper {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: JordanMeasurable E) :
   Filter.atTop.Tendsto (fun n ↦ (2:ℝ)^(-(d*n:ℤ)) * (metric_entropy_upper E n)) (nhds hE.measure) := by
  sorry

/-- Exercise 1.1.15 (Uniqueness of Jordan measure) -/
theorem JordanMeasure.measure_uniq {d:ℕ} {m': (E: Set (EuclideanSpace' d)) → (JordanMeasurable E) → ℝ}
  (hnonneg: ∀ E: Set (EuclideanSpace' d), ∀ hE: JordanMeasurable E, m' E hE ≥ 0)
  (hadd: ∀ E F: Set (EuclideanSpace' d), ∀ (hE: JordanMeasurable E) (hF: JordanMeasurable F),
   Disjoint E F → m' (E ∪ F) (hE.union hF) = m' E hE + m' F hF)
  (htrans: ∀ E: Set (EuclideanSpace' d), ∀ (hE: JordanMeasurable E) (x: EuclideanSpace' d), m' (E + {x}) (hE.translate x) = m' E hE) : ∃ c, c ≥ 0 ∧ ∀ E: Set (EuclideanSpace' d), ∀ hE: JordanMeasurable E, m' E hE = c * hE.measure := by
  sorry

/-- With unit cube normalization, the unique such function equals Jordan measure. -/
theorem JordanMeasure.measure_uniq' {d:ℕ} {m': (E: Set (EuclideanSpace' d)) → (JordanMeasurable E) → ℝ}
  (hnonneg: ∀ E: Set (EuclideanSpace' d), ∀ hE: JordanMeasurable E, m' E hE ≥ 0)
  (hadd: ∀ E F: Set (EuclideanSpace' d), ∀ (hE: JordanMeasurable E) (hF: JordanMeasurable F),
   Disjoint E F → m' (E ∪ F) (hE.union hF) = m' E hE + m' F hF)
  (htrans: ∀ E: Set (EuclideanSpace' d), ∀ (hE: JordanMeasurable E) (x: EuclideanSpace' d), m' (E + {x}) (hE.translate x) = m' E hE)
  (hcube : m' (Box.unit_cube d) (IsElementary.box _).jordanMeasurable = 1) :
  ∀ E: Set (EuclideanSpace' d), ∀ hE: JordanMeasurable E, m' E hE = hE.measure := by
  sorry

/-- Exercise 1.1.16 -/
theorem JordanMeasurable.prod {d₁ d₂:ℕ} {E₁: Set (EuclideanSpace' d₁)} {E₂: Set (EuclideanSpace' d₂)}
  (hE₁: JordanMeasurable E₁) (hE₂: JordanMeasurable E₂) : JordanMeasurable (EuclideanSpace'.prod E₁ E₂) := by
  sorry

/-- Jordan measure is multiplicative on products: μ(E₁ × E₂) = μ(E₁) \* μ(E₂). -/
theorem JordanMeasurable.measure_of_prod {d₁ d₂:ℕ} {E₁: Set (EuclideanSpace' d₁)} {E₂: Set (EuclideanSpace' d₂)}
  (hE₁: JordanMeasurable E₁) (hE₂: JordanMeasurable E₂)
  : (hE₁.prod hE₂).measure = hE₁.measure * hE₂.measure := by
  sorry

/-- Two sets are isometric if one is an orthogonal transformation plus translation of the other. -/
abbrev Isometric {d:ℕ} (E F: Set (EuclideanSpace' d)) : Prop :=
 ∃ A ∈ Matrix.orthogonalGroup (Fin d) ℝ, ∃ x₀, F = ((fun x => WithLp.toLp 2 (Matrix.toLin' A x.ofLp)) '' E) + {x₀}

/-- Exercise 1.1.17 -/
theorem JordanMeasurable.measure_of_equidecomposable {d n:ℕ} {E F: Set (EuclideanSpace' d)}
  (hE: JordanMeasurable E) (hF: JordanMeasurable F)
  {P Q: Fin n → Set (EuclideanSpace' d)} (hPQ: ∀ i, Isometric (P i) (Q i))
  (hPE: E = ⋃ i, P i) (hQF: F = ⋃ i, Q i) (hPdisj: Set.PairwiseDisjoint .univ P)
  (hQdisj: Set.PairwiseDisjoint .univ (fun i ↦ (interior (Q i)))) : hE.measure = hF.measure := by
  sorry

/-- Exercise 1.1.18 (1) -/
-- The outer Jordan measure of a set equals the outer measure of its closure.
theorem JordanMeasurable.outer_measure_of_closure {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) :
  Jordan_outer_measure (closure E) = Jordan_outer_measure E := by
  sorry

/-- Exercise 1.1.18 (2) -/
-- The inner Jordan measure of a set equals the inner measure of its interior.
theorem JordanMeasurable.inner_measure_of_interior {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) :
  Jordan_inner_measure (interior E) = Jordan_inner_measure E := by
  sorry

/-- Exercise 1.1.18 (3) -/
-- A bounded set is Jordan measurable if and only if its boundary is Jordan null.
theorem JordanMeasurable.iff_boundary_null {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) :
  JordanMeasurable E ↔ JordanMeasurable.null (frontier E) := by
  sorry

/-- The unit square with all rational points removed (not Jordan measurable). -/
abbrev bullet_riddled_square : Set (EuclideanSpace' 2) := { x | ∀ i, x i ∈ Set.Icc 0 1 ∧ x i ∉ (fun (q:ℚ) ↦ (q:ℝ)) '' .univ}

/-- The set of rational points in the unit square (not Jordan measurable). -/
abbrev bullets : Set (EuclideanSpace' 2) := { x | ∀ i, x i ∈ Set.Icc 0 1 ∧ x i ∈ (fun (q:ℚ) ↦ (q:ℝ)) '' .univ}

/-- The bullet-riddled square has inner Jordan measure 0 (no elementary subset). -/
theorem bullet_riddled_square.inner : Jordan_inner_measure bullet_riddled_square = 0 := by
  sorry

/-- The bullet-riddled square has outer Jordan measure 1 (fills the unit square). -/
theorem bullet_riddled_square.outer : Jordan_outer_measure bullet_riddled_square = 1 := by
  sorry

/-- The rational points in the unit square have inner Jordan measure 0. -/
theorem bullets.inner : Jordan_inner_measure bullets = 0 := by
  sorry

/-- The rational points in the unit square have outer Jordan measure 1. -/
theorem bullets.outer : Jordan_outer_measure bullets = 1 := by
  sorry

/-- The bullet-riddled square is not Jordan measurable (inner ≠ outer). -/
theorem bullet_riddled_square.not_jordanMeasurable : ¬ JordanMeasurable bullet_riddled_square := by
  sorry

/-- The set of rational points is not Jordan measurable (inner ≠ outer). -/
theorem bullets.not_jordanMeasurable : ¬ JordanMeasurable bullets := by
  sorry

/-- Exercise 1.1.19 (Caratheodory property) -/
theorem JordanMeasurable.caratheodory {d:ℕ} {E F: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) (hF: IsElementary F) :
  Jordan_outer_measure E = Jordan_outer_measure (E ∩ F) + Jordan_outer_measure (E \ F) := by
  sorry
