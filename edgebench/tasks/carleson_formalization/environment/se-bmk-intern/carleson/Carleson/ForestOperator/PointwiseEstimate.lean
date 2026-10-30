module

public import Carleson.Forest
public import Carleson.Operators
public import Carleson.ToMathlib.HardyLittlewood

@[expose] public section

open ShortVariables TileStructure
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
  {n j j' : ℕ} {t : Forest X n} {u u₁ u₂ p : 𝔓 X} {x x' : X} {𝔖 : Set (𝔓 X)}
  {f f₁ f₂ g g₁ g₂ : X → ℂ} {I J J' L : Grid X}
variable {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure Filter
open scoped NNReal ENNReal ComplexConjugate

namespace TileStructure.Forest

/-! ## Section 7.1 and Lemma 7.1.3 -/

open scoped Classical in
variable (t) in
/-- The definition `σ(u, x)` given in Section 7.1.
We may assume `u ∈ t` whenever proving things about this definition. -/
def σ (u : 𝔓 X) (x : X) : Finset ℤ := .image 𝔰 { p | p ∈ t u ∧ x ∈ E p }

variable (t) in
private lemma exists_p_of_mem_σ (u : 𝔓 X) (x : X) {s : ℤ} (hs : s ∈ t.σ u x) :
    ∃ p ∈ t.𝔗 u, x ∈ E p ∧ 𝔰 p = s := by
  sorry

/- \overline{σ} from the blueprint. -/
variable (t) in
def σMax (u : 𝔓 X) (x : X) (hσ : (t.σ u x).Nonempty) : ℤ :=
  t.σ u x |>.max' hσ

/- \underline{σ} from the blueprint. -/
variable (t) in
def σMin (u : 𝔓 X) (x : X) (hσ : (t.σ u x).Nonempty) : ℤ :=
  t.σ u x |>.min' hσ

variable (t) in
private lemma σMax_mem_σ (u : 𝔓 X) (x : X) (hσ : (t.σ u x).Nonempty) : σMax t u x hσ ∈ t.σ u x := by
  sorry

/-- The definition of `𝓙₀(𝔖), defined above Lemma 7.1.2 -/
def 𝓙₀ (𝔖 : Set (𝔓 X)) : Set (Grid X) :=
  {J : Grid X | s J = -S ∨ ∀ p ∈ 𝔖, ¬(𝓘 p : Set X) ⊆ ball (c J) (100 * D ^ (s J + 1))}

/-- The definition of `𝓙(𝔖), defined above Lemma 7.1.2 -/
def 𝓙 (𝔖 : Set (𝔓 X)) : Set (Grid X) :=
  {x | Maximal (· ∈ 𝓙₀ 𝔖) x}

lemma 𝓙_subset_𝓙₀ {𝔖 : Set (𝔓 X)} : 𝓙 𝔖 ⊆ 𝓙₀ 𝔖 := by
  sorry

lemma pairwiseDisjoint_𝓙 : (𝓙 𝔖).PairwiseDisjoint (fun I ↦ (I : Set X)) := by
  sorry

lemma S_eq_zero_of_topCube_mem_𝓙₀ {𝔖 : Set (𝔓 X)} (h𝔖 : 𝔖.Nonempty) (h : topCube ∈ 𝓙₀ 𝔖) :
    S = 0 := by
  sorry

/-- The definition of `𝓛₀(𝔖), defined above Lemma 7.1.2 -/
def 𝓛₀ (𝔖 : Set (𝔓 X)) : Set (Grid X) :=
  {L : Grid X | s L = -S ∨ (∃ p ∈ 𝔖, L ≤ 𝓘 p) ∧ ∀ p ∈ 𝔖, ¬𝓘 p ≤ L}

/-- The definition of `𝓛(𝔖), defined above Lemma 7.1.2 -/
def 𝓛 (𝔖 : Set (𝔓 X)) : Set (Grid X) :=
  {x | Maximal (· ∈ 𝓛₀ 𝔖) x}

lemma 𝓛_subset_𝓛₀ {𝔖 : Set (𝔓 X)} : 𝓛 𝔖 ⊆ 𝓛₀ 𝔖 := by
  sorry

private lemma s_le_s_of_mem_𝓛 {𝔖 : Set (𝔓 X)} {L : Grid X} (hL : L ∈ 𝓛 𝔖)
    {p : 𝔓 X} (hp : p ∈ 𝔖) (hpL : ¬ Disjoint (𝓘 p : Set X) (L : Set X)) : s L ≤ s (𝓘 p) := by
  sorry

private lemma subset_of_mem_𝓛 {𝔖 : Set (𝔓 X)} {L : Grid X} (hL : L ∈ 𝓛 𝔖) {p : 𝔓 X}
    (hp : p ∈ 𝔖) (hpL : ¬ Disjoint (𝓘 p : Set X) (L : Set X)) : (L : Set X) ⊆ (𝓘 p : Set X) := by
  sorry

lemma le_of_mem_𝓛 {𝔖 : Set (𝔓 X)} {L : Grid X} (hL : L ∈ 𝓛 𝔖) {p : 𝔓 X}
    (hp : p ∈ 𝔖) (hpL : ¬Disjoint (𝓘 p : Set X) (L : Set X)) : L ≤ 𝓘 p := by
  sorry

open scoped Classical in
/-- The projection operator `P_𝓒 f(x)`, given above Lemma 7.1.3.
In lemmas the `c` will be pairwise disjoint on `C`. -/
def approxOnCube (C : Set (Grid X)) (f : X → E') (x : X) : E' :=
  ∑ J with J ∈ C, (J : Set X).indicator (fun _ ↦ ⨍ y in J, f y) x

lemma stronglyMeasurable_approxOnCube (C : Set (Grid X)) (f : X → E') :
    StronglyMeasurable (approxOnCube (X := X) (K := K) C f) := by
  sorry

lemma integrable_approxOnCube (C : Set (Grid X)) {f : X → E'} : Integrable (approxOnCube C f) := by
  sorry

lemma approxOnCube_nonneg {C : Set (Grid X)} {f : X → ℝ} (hf : ∀ (y : X), f y ≥ 0) {x : X} :
    approxOnCube C f x ≥ 0 := by
  sorry

open scoped Classical in
lemma approxOnCube_apply {C : Set (Grid X)} (hC : C.PairwiseDisjoint (fun I ↦ (I : Set X)))
    (f : X → E') {x : X} {J : Grid X} (hJ : J ∈ C) (xJ : x ∈ J) :
    (approxOnCube C f) x = ⨍ y in J, f y := by
  sorry

lemma boundedCompactSupport_approxOnCube {𝕜 : Type*} [RCLike 𝕜] {C : Set (Grid X)} {f : X → 𝕜} :
    BoundedCompactSupport (approxOnCube C f) := by
  sorry

-- Used in the proof of Lemma 7.1.6
lemma lintegral_eq_lintegral_approxOnCube {C : Set (Grid X)}
    (hC : C.PairwiseDisjoint fun I ↦ (I : Set X)) {J : Grid X} (hJ : J ∈ C) {f : X → ℂ}
    (hf : BoundedCompactSupport f) :
    ∫⁻ y in J, ‖f y‖ₑ = ∫⁻ y in J, ‖approxOnCube C (fun x ↦ (‖f x‖ : ℂ)) y‖ₑ := by
  sorry

lemma approxOnCube_ofReal (C : Set (Grid X)) (f : X → ℝ) (x : X) :
    approxOnCube C (Complex.ofReal <| f ·) x = Complex.ofReal (approxOnCube C f x) := by
  sorry

lemma norm_approxOnCube_le_approxOnCube_norm {C : Set (Grid X)} {f : X → E'} {x : X} :
    ‖approxOnCube C f x‖ ≤ approxOnCube C (‖f ·‖) x := by
  sorry

/-- The definition `I_i(x)`, given above Lemma 7.1.3.
The cube of scale `s` that contains `x`. There is at most 1 such cube, if it exists. -/
def cubeOf (i : ℤ) (x : X) : Grid X :=
  Classical.epsilon (fun I ↦ x ∈ I ∧ s I = i)

lemma cubeOf_spec {i : ℤ} (hi : i ∈ Icc (-S : ℤ) S) (I : Grid X) {x : X} (hx : x ∈ I) :
    x ∈ cubeOf i x ∧ s (cubeOf i x) = i := by
  sorry

/-- The definition `T_𝓝^θ f(x)`, given in (7.1.3).
For convenience, the suprema are written a bit differently than in the blueprint
(avoiding `cubeOf`), but this should be equivalent.
This is `0` if `x` doesn't lie in a cube. -/
def nontangentialMaximalFunction (θ : Θ X) (f : X → ℂ) (x : X) : ℝ≥0∞ :=
  ⨆ (I : Grid X) (_ : x ∈ I) (x' ∈ I) (s₂ ∈ Icc (s I) S)
  (_ : ENNReal.ofReal (D ^ (s₂ - 1)) ≤ upperRadius Q θ x'),
  ‖∑ i ∈ Icc (s I) s₂, ∫ y, Ks i x' y * f y‖ₑ

protected theorem MeasureTheory.Measurable.nontangentialMaximalFunction {θ : Θ X} {f : X → ℂ} :
    Measurable (nontangentialMaximalFunction θ f) := by
  sorry

-- Set used in definition of `boundaryOperator`
open scoped Classical in
variable (t) (u) in def 𝓙' (x : X) (i : ℤ) : Finset (Grid X) :=
  { J | J ∈ 𝓙 (t u) ∧ (J : Set X) ⊆ ball x (16 * D ^ i) ∧ s J ≤ i }

private lemma mem_𝓙_of_mem_𝓙' {x : X} {i : ℤ} {J : Grid X} : J ∈ 𝓙' t u x i → J ∈ 𝓙 (t u) := by
  sorry

variable (f I J) in
/-- Scaled integral appearing in the definition of `boundaryOperator`. -/
def ijIntegral : ℝ≥0∞ :=
  D ^ ((s J - s I) / (a : ℝ)) / volume (ball (c I) (16 * D ^ (s I))) * ∫⁻ y in J, ‖f y‖ₑ

lemma ijIntegral_lt_top (hf : BoundedCompactSupport f) : ijIntegral f I J < ⊤ := by
  sorry

variable (t) in
/-- The operator `S_{1,𝔲} f(x)`, given in (7.1.4). -/
def boundaryOperator (u : 𝔓 X) (f : X → ℂ) (x : X) : ℝ≥0∞ :=
  ∑ I : Grid X, (I : Set X).indicator (fun _ ↦ ∑ J ∈ 𝓙' t u (c I) (s I), ijIntegral f I J) x

lemma measurable_boundaryOperator {u : 𝔓 X} {f : X → ℂ} : Measurable (t.boundaryOperator u f) := by
  sorry

lemma boundaryOperator_lt_top (hf : BoundedCompactSupport f) : t.boundaryOperator u f x < ⊤ := by
  sorry

/-- The indexing set for the collection of balls 𝓑, defined above Lemma 7.1.3. -/
def 𝓑 : Set (ℕ × ℕ × Grid X) := Iic (S + 5) ×ˢ Iic (2 * S + 3) ×ˢ univ

/-- The center function for the collection of balls 𝓑. -/
def c𝓑 (z : ℕ × ℕ × Grid X) : X := c z.2.2

/-- The radius function for the collection of balls 𝓑. -/
def r𝓑 (z : ℕ × ℕ × Grid X) : ℝ := 2 ^ z.1 * D ^ (s z.2.2 + z.2.1)

lemma 𝓑_finite : (𝓑 (X := X)).Finite := by
  sorry

lemma laverage_le_biInf_MB' {c₀ : X} {r₀ : ℝ} (hr : 4 * D ^ s J + dist (c J) c₀ ≤ r₀)
    (h : ∃ i ∈ 𝓑, c𝓑 i = c₀ ∧ r𝓑 i = r₀) :
    ⨍⁻ x in ball c₀ r₀, ‖f x‖ₑ ∂volume ≤ ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

lemma laverage_le_biInf_MB {r₀ : ℝ} (hr : 4 * D ^ s J ≤ r₀)
    (h : ∃ i ∈ 𝓑, c𝓑 i = c J ∧ r𝓑 i = r₀) :
    ⨍⁻ x in ball (c J) r₀, ‖f x‖ₑ ∂volume ≤ ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- Lemma 7.1.1, freely translated. -/
lemma convex_scales (hu : u ∈ t) : OrdConnected (t.σ u x : Set ℤ) := by
  sorry

/-- Part of Lemma 7.1.2 -/
@[simp]
lemma biUnion_𝓙 : ⋃ J ∈ 𝓙 𝔖, J = ⋃ I : Grid X, (I : Set X) := by
  sorry

/-- Part of Lemma 7.1.2 -/
@[simp]
lemma biUnion_𝓛 : ⋃ J ∈ 𝓛 𝔖, J = ⋃ I : Grid X, (I : Set X) := by
  sorry

/-- Part of Lemma 7.1.2 -/
lemma pairwiseDisjoint_𝓛 : (𝓛 𝔖).PairwiseDisjoint (fun I ↦ (I : Set X)) := by
  sorry

/-- The constant used in `first_tree_pointwise`.
Has value `10 * 2 ^ (104 * a ^ 3)` in the blueprint. -/
-- Todo: define this recursively in terms of previous constants
irreducible_def C7_1_4 (a : ℕ) : ℝ≥0 := 10 * 2 ^ ((𝕔 + 4) * a ^ 3)

-- Used in the proof of `exp_sub_one_le`, which is used to prove Lemma 7.1.4
private lemma exp_Lipschitz : LipschitzWith 1 (fun (t : ℝ) ↦ exp (.I * t)) := by
  sorry

-- Used in the proof of Lemma 7.1.4
private lemma exp_sub_one_le (t : ℝ) : ‖exp (.I * t) - 1‖ ≤ ‖t‖ := by
  sorry

-- Used in the proofs of Lemmas 7.1.4 and 7.1.5
private lemma dist_lt_5 (hu : u ∈ t) (mp : p ∈ t.𝔗 u) (Qxp : Q x ∈ Ω p) :
    dist_(p) (𝒬 u) (Q x) < 5 := by
  sorry

-- The bound in the third display in the proof of Lemma 7.1.4
private lemma L7_1_4_bound (hu : u ∈ t) {s : ℤ} (hs : s ∈ t.σ u x) {y : X} (hKxy : Ks s x y ≠ 0) :
    ‖exp (.I * (-𝒬 u y + Q x y + 𝒬 u x - Q x x)) - 1‖ₑ ≤
    5 * 2 ^ (4 * a) * 2 ^ (s - σMax t u x ⟨s, hs⟩) := by
  sorry

-- The bound used implicitly in the fourth displayed inequality in the proof of Lemma 7.1.4
variable (f) in
private lemma L7_1_4_integrand_bound (hu : u ∈ t) {s : ℤ} (hs : s ∈ t.σ u x) (y : X) :
    ‖(exp (.I * (-𝒬 u y + Q x y + 𝒬 u x - Q x x)) - 1) * Ks s x y * f y‖ₑ ≤
    5 * 2 ^ (s - σMax t u x ⟨s, hs⟩) *
      (2 ^ ((𝕔 + 3) * a ^ 3) / volume (ball x (D ^ s))) * ‖f y‖ₑ := by
  sorry

-- The geometric sum used to prove `L7_1_4_sum`
private lemma sum_pow_two_le (a b : ℤ) : ∑ s ∈ Finset.Icc a b, (2 : ℝ≥0∞) ^ s ≤ 2 ^ (b + 1) := by
  sorry

-- The sum used in the proof of Lemma 7.1.4
private lemma L7_1_4_sum (hσ : (t.σ u x).Nonempty) :
    ∑ s ∈ t.σ u x, (2 : ℝ≥0∞) ^ (s - t.σMax u x hσ) ≤ 2 := by
  sorry

-- Inequality used twice in the proof of Lemma 7.1.4
private lemma L7_1_4_dist_le {p : 𝔓 X} (xp : x ∈ E p) {J : Grid X}
    (hJ : ((J : Set X) ∩ ball x (D ^ 𝔰 p / 2)).Nonempty) :
    dist (c J) (𝔠 p) ≤ 4 * D ^ (s J) + 4.5 * D ^ (𝔰 p) := by
  sorry

-- Inequality needed for the proof of `L7_1_4_integral_le_integral`
private lemma s_le_s {p : 𝔓 X} (pu : p ∈ t.𝔗 u) (xp : x ∈ E p)
    {J : Grid X} (hJ : J ∈ 𝓙 (t.𝔗 u) ∧ ((J : Set X) ∩ ball x (D ^ 𝔰 p / 2)).Nonempty) :
    s J ≤ 𝔰 p := by
  sorry

private lemma ball_covered_by_𝓙 (hu : u ∈ t) {p : 𝔓 X} (pu : p ∈ t u) (xp : x ∈ E p) :
    ball x (D ^ 𝔰 p / 2) ⊆ ⋃ J ∈ 𝓙 (t.𝔗 u), (J : Set X) := by
  sorry

private lemma Grid_subset_ball' {J : Grid X} {p : 𝔓 X} (pu : p ∈ t.𝔗 u) {x : X} (xp : x ∈ E p)
  (hJ : J ∈ 𝓙 (t.𝔗 u) ∧ (↑J ∩ ball x (↑D ^ 𝔰 p / 2)).Nonempty) :
  (J : Set X) ⊆ ball (𝔠 p) (16 * ↑D ^ 𝔰 p) := by
  sorry

-- The integral bound needed for the proof of Lemma 7.1.4
private lemma L7_1_4_integral_le_integral (hu : u ∈ t) (hf : BoundedCompactSupport f) {p : 𝔓 X}
    (pu : p ∈ t u) (xp : x ∈ E p) : ∫⁻ y in ball x (D ^ 𝔰 p / 2), ‖f y‖ₑ ≤
    ∫⁻ y in ball (𝔠 p) (16 * D ^ 𝔰 p), ‖approxOnCube (𝓙 (t u)) (‖f ·‖) y‖ₑ := by
  sorry

-- An average over `ball (𝔠 p) (16 * D ^ 𝔰 p)` is bounded by `MB`; needed for Lemma 7.1.4
private lemma L7_1_4_laverage_le_MB (hL : L ∈ 𝓛 (t u)) (hx : x ∈ L) (hx' : x' ∈ L) (g : X → ℝ)
    {p : 𝔓 X} (pu : p ∈ t.𝔗 u) (xp : x ∈ E p) :
    (∫⁻ y in ball (𝔠 p) (16 * D ^ 𝔰 p), ‖g y‖ₑ) / volume (ball (𝔠 p) (16 * D ^ 𝔰 p)) ≤
    MB volume 𝓑 c𝓑 r𝓑 g x' := by
  sorry

/-- Lemma 7.1.4 -/
lemma first_tree_pointwise (hu : u ∈ t) (hL : L ∈ 𝓛 (t u)) (hx : x ∈ L) (hx' : x' ∈ L)
    (hf : BoundedCompactSupport f) :
    ‖∑ i ∈ t.σ u x, ∫ y, (exp (.I * (-𝒬 u y + Q x y + 𝒬 u x - Q x x)) - 1) * Ks i x y * f y‖ₑ ≤
    C7_1_4 a * MB volume 𝓑 c𝓑 r𝓑 (approxOnCube (𝓙 (t u)) (‖f ·‖)) x' := by
  sorry

/-- Lemma 7.1.5 -/
lemma second_tree_pointwise (hu : u ∈ t) (hL : L ∈ 𝓛 (t u)) (hx : x ∈ L) (hx' : x' ∈ L) :
    ‖∑ i ∈ t.σ u x, ∫ y, Ks i x y * approxOnCube (𝓙 (t u)) f y‖ₑ ≤
    nontangentialMaximalFunction (𝒬 u) (approxOnCube (𝓙 (t u)) f) x' := by
  sorry

/-- The constant used in `third_tree_pointwise`.
Has value `2 ^ (128 * a ^ 3)` in the blueprint. -/
irreducible_def C7_1_6 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 3 + 𝕔 / 4) * a ^ 3)

-- Used in the proof of Lemmas 7.1.3 and 7.1.6 to translate between `∑ p` into `∑ s`
open scoped Classical in
private lemma p_sum_eq_s_sum {α : Type*} [AddCommMonoid α] (I : ℤ → X → α) :
    ∑ p ∈ Finset.univ.filter (· ∈ t.𝔗 u), (E p).indicator (I (𝔰 p)) x =
    ∑ s ∈ t.σ u x, I s x := by
  sorry

-- Equation 7.1.10 from the blueprint
private lemma L7_1_6_integral_eq {J : Grid X} (hJ : J ∈ 𝓙 (t.𝔗 u)) {i : ℤ}
    (hf : BoundedCompactSupport f) : ∫ y in J, Ks i x y * (f y - approxOnCube (𝓙 (t u)) f y) =
    ∫ y in J, (⨍ z in J, (Ks i x y - Ks i x z)) * f y := by
  sorry

-- Integral norm bound used implicitly in the third display of the proof of Lemma 7.1.6.
private lemma L7_1_6_integral_le {J : Grid X} (hJ : J ∈ 𝓙 (t u)) {i : ℤ}
    (hf : BoundedCompactSupport f) : ‖∫ y in J, Ks i x y * (f y - approxOnCube (𝓙 (t u)) f y)‖ₑ ≤
    D2_1_3 a / volume (ball x (D ^ i)) * 2 ^ (3 / a : ℝ) *
    (D ^ ((s J - i) / (a : ℝ)) * ∫⁻ y in J, ‖f y‖ₑ) := by
  sorry

-- Prove an upper bound for the function `I` used in the proof of Lemma 7.1.6
private lemma L7_1_6_I_le (hu : u ∈ t) (hf : BoundedCompactSupport f) {p : 𝔓 X} (hp : p ∈ t u)
    {x : X} (hxp : x ∈ E p) : ‖∫ y, Ks (𝔰 p) x y * (f y - approxOnCube (𝓙 (t u)) f y)‖ₑ ≤
    D2_1_3 a / volume (ball x (D ^ 𝔰 p)) * 2 ^ (3 / a : ℝ) *
    ∑ J ∈ 𝓙' t u (𝔠 p) (𝔰 p), (D : ℝ≥0∞) ^ ((s J - 𝔰 p) / (a : ℝ)) * ∫⁻ y in J, ‖f y‖ₑ := by
  sorry

-- Translate `∑ p` into `∑ I, ∑ p` in the proof of Lemma 7.1.6
variable (t) (u) (x) in
open scoped Classical in
lemma sum_p_eq_sum_I_sum_p (f : X → ℤ → ℝ≥0∞) :
    ∑ p ∈ Finset.univ.filter (· ∈ t u), (E p).indicator 1 x * f (𝔠 p) (𝔰 p) =
    ∑ I : Grid X, ∑ p ∈ Finset.univ.filter (fun p ↦ p ∈ t u ∧ 𝓘 p = I),
    (E p).indicator 1 x * f (c I) (s I) := by
  sorry

lemma le_C7_1_6 (a4 : 4 ≤ a) :
    D2_1_3 a * defaultA a ^ 5 * (2 : ℝ≥0∞) ^ (3 / a : ℝ) ≤ C7_1_6 a := by
  sorry

/-- Lemma 7.1.6 -/
lemma third_tree_pointwise (hu : u ∈ t) (hL : L ∈ 𝓛 (t u)) (hx : x ∈ L) (hx' : x' ∈ L)
    (hf : BoundedCompactSupport f) :
    ‖∑ i ∈ t.σ u x, ∫ y, Ks i x y * (f y - approxOnCube (𝓙 (t u)) f y)‖ₑ ≤
    C7_1_6 a * t.boundaryOperator u (approxOnCube (𝓙 (t u)) (‖f ·‖)) x' := by
  sorry

/-- The constant used in `pointwise_tree_estimate`.
Has value `2 ^ (129 * a ^ 3)` in the blueprint. -/
irreducible_def C7_1_3 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 4 + 𝕔 / 4) * a ^ 3)

lemma C7_1_6_le_C7_1_3 {a : ℕ} : C7_1_6 a ≤ C7_1_3 a := by
  sorry

lemma C7_1_4_le_C7_1_3 {a : ℕ} (ha : 4 ≤ a) : C7_1_4 a ≤ C7_1_3 a := by
  sorry

/-- Lemma 7.1.3. -/
lemma pointwise_tree_estimate (hu : u ∈ t) (hL : L ∈ 𝓛 (t u)) (hx : x ∈ L) (hx' : x' ∈ L)
    (hf : BoundedCompactSupport f) :
    ‖carlesonSum (t u) (fun y ↦ exp (.I * - 𝒬 u y) * f y) x‖ₑ ≤
    C7_1_3 a * (MB volume 𝓑 c𝓑 r𝓑 (approxOnCube (𝓙 (t u)) (‖f ·‖)) x' +
    t.boundaryOperator u (approxOnCube (𝓙 (t u)) (‖f ·‖)) x') +
    nontangentialMaximalFunction (𝒬 u) (approxOnCube (𝓙 (t u)) f) x' := by
  sorry

end TileStructure.Forest
