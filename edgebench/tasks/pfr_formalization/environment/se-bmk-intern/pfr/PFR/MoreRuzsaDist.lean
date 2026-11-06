module

public import PFR.ForMathlib.Entropy.RuzsaDist
public import PFR.HundredPercent
public import PFR.Mathlib.Algebra.BigOperators.Fin
public import PFR.Mathlib.Data.Fin.Basic
public import PFR.Mathlib.MeasureTheory.Group.Arithmetic
public import PFR.Mathlib.Order.Interval.Finset.Fin

/-!
# More results about Ruzsa distance

More facts about Ruzsa distance and related inequalities, for use in the m-torsion version of PFR.

## Main definitions

* `multiDist`: An analogue of `rdist` for the m-torsion version of PFR.
* `condMultiDist`: A conditional analogue of `multiDist`

## Main results

* `kvm_ineq_I`, `kvm_ineq_II`, `kvm_ineq_III`: Variants of the Kaimanovich-Versik-Madiman inequality
* `multiDist_chainRule`: A chain rule for `multiDist`
* `cor_multiDist_chainRule`: The corollary of the chain rule needed for the m-torsion version of PFR
* `ent_sub_zsmul_sub_ent_le`: Controlling `H[X - aY]` in terms of `H[X]` and `d[X ; Y]`.
-/

public section

open Filter Function MeasureTheory Measure ProbabilityTheory

universe uG

variable {Ω Ω' Ω'' Ω''' S T : Type*} {G : Type uG}
  [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
  [mΩ' : MeasurableSpace Ω'] {μ' : Measure Ω'}
  [mΩ'' : MeasurableSpace Ω''] {μ'' : Measure Ω''}
  [mΩ''' : MeasurableSpace Ω'''] {μ''' : Measure Ω'''}
  [hG : MeasurableSpace G] [MeasurableSingletonClass G] [AddCommGroup G] [Countable G]
  [Countable S] [MeasurableSpace S]
  [Countable T] [MeasurableSpace T]

variable {X : Ω → G} {Y : Ω' → G} {Z : Ω'' → G} -- [FiniteRange X] [FiniteRange Y] [FiniteRange Z]

/-
`TODO`: we had to add the hp `Fintype G` to the following lemma in order to use `condIndep_copies`,
which requires it. Actually, we already have `FiniteRange X` and `FiniteRange Y`, so it should be
possible to remove it, or to generalize the lemma to the case where `G` is not finite but the
random variables have finite range. One way to do it may be to write a lemma that tells us that
given a r.v., we can construct another r.v. that is identically distributed, which is defined the
immersion of the range of the initial r.v. inside the codomain (this would be a sort of canonical
version)-/

/-- If `X, Y` are `G`-valued, then `d[X;-Y] ≤ 3 d[X;Y]`. -/
lemma rdist_of_neg_le [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] (hX : Measurable X)
    (hY : Measurable Y) [Finite G] :
    d[X ; μ # -Y ; μ'] ≤ 3 * d[X ; μ # Y ; μ'] := by
  sorry

/-- If `n ≥ 0` and `X, Y₁, ..., Yₙ` are jointly independent `G`-valued random variables,
then `H[Y i₀ + ∑ i ∈ s, Y i; μ] - H[Y i₀; μ] ≤ ∑ i ∈ s, (H[Y i₀ + Y i; μ] - H[Y i₀; μ])`. -/
lemma kvm_ineq_I {I : Type*} {i₀ : I} {s : Finset I} (hs : ¬ i₀ ∈ s)
    {Y : I → Ω → G} [∀ i, FiniteRange (Y i)] (hY : ∀ i, Measurable (Y i))
    (h_indep : iIndepFun Y μ) :
    H[Y i₀ + ∑ i ∈ s, Y i ; μ] - H[Y i₀ ; μ] ≤ ∑ i ∈ s, (H[Y i₀ + Y i ; μ] - H[Y i₀ ; μ]) := by
  sorry

/-- If `n ≥ 1` and `X, Y₁, ..., Yₙ` are jointly independent `G`-valued random variables,
then `d[Y i₀; μ # ∑ i ∈ s, Y i; μ] ≤ 2 * ∑ i ∈ s, d[Y i₀; μ # Y i; μ]`. -/
lemma kvm_ineq_II {I : Type*} {i₀ : I} {s : Finset I} (hs : ¬ i₀ ∈ s)
    (hs' : Finset.Nonempty s) {Y : I → Ω → G} [∀ i, FiniteRange (Y i)]
    (hY : ∀ i, Measurable (Y i)) (h_indep : iIndepFun Y μ) :
    d[Y i₀; μ # ∑ i ∈ s, Y i; μ] ≤ 2 * ∑ i ∈ s, d[Y i₀; μ # Y i; μ] := by
  sorry

lemma kvm_ineq_III_aux {X Y Z : Ω → G} [FiniteRange X] [FiniteRange Y]
    [FiniteRange Z] (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (h_indep : iIndepFun ![X, Y, Z] μ) :
    d[X; μ # Y + Z; μ] ≤ d[X; μ # Y; μ] + (2 : ℝ)⁻¹ * (H[Y + Z; μ] - H[Y; μ]) := by
  sorry

/-- strengthen the above lemma by not requiring `X` to be independent of `Y`, `Z`. -/
lemma kvm_ineq_III_aux' {X Y Z : Ω → G} [FiniteRange X] [FiniteRange Y]
    [FiniteRange Z] (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (h_indep : IndepFun Y Z μ) [IsProbabilityMeasure μ] :
  d[X; μ # Y + Z; μ] ≤ d[X; μ # Y; μ] + (2 : ℝ)⁻¹ * (H[Y + Z; μ] - H[Y; μ]) := by
  sorry

/-- If `n ≥ 1` and `X, Y₁, ..., Yₙ`$ are jointly independent `G`-valued random variables,
then `d[Y i₀, ∑ i, Y i] ≤ d[Y i₀, Y i₁] + 2⁻¹ * (H[∑ i, Y i] - H[Y i₁])`.
-/
lemma kvm_ineq_III {I : Type*} {i₀ i₁ : I} {s : Finset I}
    (hs₀ : ¬ i₀ ∈ s) (hs₁ : ¬ i₁ ∈ s) (h01 : i₀ ≠ i₁)
    (Y : I → Ω → G) [∀ i, FiniteRange (Y i)]
    (hY : ∀ i, Measurable (Y i)) (h_indep : iIndepFun Y μ) :
    d[Y i₀; μ # Y i₁ + ∑ i ∈ s, Y i; μ]
      ≤ d[Y i₀; μ # Y i₁; μ] + (2 : ℝ)⁻¹ * (H[Y i₁ + ∑ i ∈ s, Y i; μ] - H[Y i₁; μ]) := by
  sorry

open scoped Classical in
private theorem entropy_kvm_step {Ω G : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [MeasurableSpace G] [MeasurableSingletonClass G] [AddCommGroup G] [Countable G] {I : Type*}
    {s t : Finset I} (hdisj : Disjoint s t) {X : I → Ω → G} (hX : ∀ i, Measurable (X i))
    [∀ i, FiniteRange (X i)] (hindep : iIndepFun X μ)
    (f : I → I) (hf : Finset.image f t ⊆ s) (i : I) (hi : i ∈ t) :
    H[-∑ i ∈ s \ {f i}, X i + -X (f i) + X i ; μ] - H[-∑ i ∈ s \ {f i}, X i + -X (f i) ; μ] ≤
      H[-X (f i) + X i ; μ] - H[-X (f i) ; μ] := by
  sorry

private theorem entropy_sum_le_entropy_neg_add {I : Type*} {s t : Finset I} (hdisj : Disjoint s t)
  (X : I → Ω → G) (hX : ∀ i, Measurable (X i)) [∀ i, FiniteRange (X i)]
  (hindep : iIndepFun X μ)
  (W_meas : Measurable (∑ i ∈ s, X i)) (U_meas : Measurable (∑ i ∈ t, X i)) :
  H[∑ i ∈ t, X i ; μ] ≤ H[-(∑ i ∈ s, X i) + ∑ i ∈ t, X i ; μ] := by
  sorry

private theorem entropy_kvm_decomposition {I : Type*} {s t : Finset I} (hdisj : Disjoint s t)
    (X : I → Ω → G) (hX : ∀ i, Measurable (X i))
    [∀ i, FiniteRange (X i)] (hindep : iIndepFun X μ) :
    H[-(∑ i ∈ s, X i) + ∑ i ∈ t, X i ; μ] ≤ H[-(∑ i ∈ s, X i) ; μ]
      + ∑ i ∈ t, (H[-(∑ i ∈ s, X i) + X i ; μ] - H[-(∑ i ∈ s, X i) ; μ]) := by
  sorry

open scoped Classical in
/-- Let `X₁, ..., Xₘ` and `Y₁, ..., Yₗ` be tuples of jointly independent random variables (so the
`X`'s and `Y`'s are also independent of each other), and let `f : {1,..., l} → {1,... ,m}` be a
function, then `H[∑ j, Y j] ≤ H[∑ i, X i] + ∑ j, H[Y j - X f(j)] - H[X_{f(j)}]`. -/
lemma ent_of_sum_le_ent_of_sum {I : Type*} {s t : Finset I} (hdisj : Disjoint s t)
    (X : I → Ω → G) (hX : ∀ i, Measurable (X i)) [∀ i, FiniteRange (X i)]
    (hindep : iIndepFun X μ) (f : I → I) (hf : Finset.image f t ⊆ s) :
    H[∑ i ∈ t, X i; μ] ≤ H[∑ i ∈ s, X i; μ] + ∑ i ∈ t, (H[ X i - X (f i); μ] - H[X (f i); μ]) := by
  sorry

open Classical in
/-- Let `X,Y,X'` be independent `G`-valued random variables, with `X'` a copy of `X`,
and let `a` be an integer. Then `H[X - (a+1)Y] ≤ H[X - aY] + H[X - Y - X'] - H[X]` -/
lemma ent_sub_zsmul_le {Y : Ω → G} {X' : Ω → G} [FiniteRange X] [FiniteRange Y] [FiniteRange X']
    [IsProbabilityMeasure μ] (hX : Measurable X) (hY : Measurable Y) (hX' : Measurable X')
    (h_indep : iIndepFun ![X, Y, X'] μ) (hident : IdentDistrib X X' μ μ) {a : ℤ} :
    H[X - (a+1) • Y; μ] ≤ H[X - a • Y; μ] + H[X - Y - X'; μ] - H[X; μ] := by
  sorry

/-- Let `X,Y,X'` be independent `G`-valued random variables, with `X'` a copy of `X`,
and let `a` be an integer. Then `H[X - (a+1)Y] ≤ H[X - aY] + H[X - Y - X'] - H[X]` -/
lemma ent_sub_nsmul_le {Y : Ω → G} {X' : Ω → G} [FiniteRange X] [FiniteRange Y] [FiniteRange X']
    [IsProbabilityMeasure μ] (hX : Measurable X) (hY : Measurable Y) (hX' : Measurable X')
    (h_indep : iIndepFun ![X, Y, X'] μ) (hident : IdentDistrib X X' μ μ) {a : ℕ} :
    H[X - (a + 1) • Y; μ] ≤ H[X - a • Y; μ] + H[X - Y - X'; μ] - H[X; μ] := by
  sorry

/-- Let `X,Y,X'` be independent `G`-valued random variables, with `X'` a copy of `X`,
and let `a` be an integer. Then `H[X - (a-1)Y] ≤ H[X - aY] + H[X - Y - X'] - H[X]` -/
lemma ent_of_sub_smul' {Y : Ω → G} {X' : Ω → G} [FiniteRange X] [FiniteRange Y] [FiniteRange X']
    [IsProbabilityMeasure μ] (hX : Measurable X) (hY : Measurable Y) (hX' : Measurable X')
    (h_indep : iIndepFun ![X, Y, X'] μ) (hident : IdentDistrib X X' μ μ) {a : ℤ} :
    H[X - (a-1) • Y; μ] ≤ H[X - a • Y; μ] + H[X - Y - X'; μ] - H[X; μ] := by
  sorry

/-- Let `X,Y` be independent `G`-valued random variables, and let `a` be an integer. Then
  `H[X - aY] - H[X] ≤ 4 |a| d[X ; Y]`. -/
lemma ent_sub_zsmul_sub_ent_le {Y : Ω → G} [IsProbabilityMeasure μ] [Finite G]
    (hX : Measurable X) (hY : Measurable Y) (h_indep : IndepFun X Y μ) {a : ℤ} :
    H[X - a • Y; μ] - H[X; μ] ≤ 4 * |a| * d[X ; μ # Y ; μ] := by
  sorry

/-- Let `X,Y` be independent `G`-valued random variables, and let `a` be a natural number. Then
`H[X - aY] - H[X] ≤ 4 a d[X ; Y]`. -/
lemma ent_sub_nsmul_sub_ent_le {Y : Ω → G} [IsProbabilityMeasure μ] [Finite G]
    (hX : Measurable X) (hY : Measurable Y) (h_indep : IndepFun X Y μ) {a : ℕ} :
    H[X - a • Y ; μ] - H[X ; μ] ≤ 4 * a * d[X ; μ # Y ; μ] := by
  sorry

/-- Let `X,Y` be independent `G`-valued random variables, and let `a` be a natural number. Then
`H[X + aY] - H[X] ≤ 4 a d[X ; Y]`. -/
lemma ent_add_nsmul_sub_ent_le {Y : Ω → G} [IsProbabilityMeasure μ] [Finite G]
    (hX : Measurable X) (hY : Measurable Y) (h_indep : IndepFun X Y μ) {a : ℕ} :
    H[X + a • Y ; μ] - H[X ; μ] ≤ 4 * a * d[X ; μ # Y ; μ] := by
  sorry

section multiDistance

open Filter Function MeasureTheory Measure ProbabilityTheory

variable {G : Type uG} [hG : MeasurableSpace G] [AddCommGroup G]

/-- Let `X_[m] = (X₁, ..., Xₘ)` be a non-empty finite tuple of `G`-valued random variables `X_i`.
Then we define `D[X_[m]] = H[∑ i, X_i'] - 1/m*∑ i, H[X_i']`, where the `X_i'` are independent copies
of the `X_i`. -/
@[expose] noncomputable def multiDist {m : ℕ} {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    (X : ∀ i, Ω i → G) : ℝ :=
  H[fun x ↦ ∑ i, x i; .pi (fun i ↦ (hΩ i).volume.map (X i))] - (m:ℝ)⁻¹ * ∑ i, H[X i]

@[inherit_doc multiDist] notation3:max "D[" X "; " hΩ "]" => multiDist hΩ X

variable [MeasurableSingletonClass G] [Countable G]

lemma multiDist_nonneg_of_indep [Finite G] {m : ℕ} {Ω : Type*} (hΩ : MeasureSpace Ω)
    [IsProbabilityMeasure hΩ.volume] (X : Fin m → Ω → G) (hX : ∀ i, Measurable (X i))
    (h_indep : iIndepFun X ℙ) :
    0 ≤ D[X ; fun _ ↦ hΩ] := by
  sorry

/-- We have `D[X_[m]] ≥ 0`. -/
lemma multiDist_nonneg [Finite G] {m : ℕ} {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    (hprob : ∀ i, IsProbabilityMeasure (ℙ : Measure (Ω i))) (X : ∀ i, Ω i → G)
    (hX : ∀ i, Measurable (X i)) :
    0 ≤ D[X ; hΩ] := by
  sorry

/-- The sum of `f` away from the diagonal. -/
abbrev offDiag_sum {m : ℕ} (f : Fin m → Fin m → ℝ) := ∑ j, ∑ k, (if j = k then (0:ℝ) else f j k)

set_option linter.flexible false in
/-- To prove multidist_ruzsa_I, we first establish a special case when the random variables are
defined on the same space and are jointly independent. -/
lemma multidist_ruzsa_I_indep {m : ℕ} (hm : m ≥ 1) {Ω : Type*} (hΩ : MeasureSpace Ω)
    [IsProbabilityMeasure (hΩ.volume)] (X : Fin m → Ω → G) (h_indep : iIndepFun X)
    (hmes : ∀ j, Measurable (X j)) (hfin : ∀ j, FiniteRange (X j)) :
    ∑ j, ∑ k, (if j = k then (0:ℝ) else d[X j # -X k]) ≤ m * (m - 1) * D[X; fun _ ↦ hΩ] := by
  sorry

/-- Let `m ≥ 1`, and let `X_[m]` be a tuple of `G`-valued random variables. Then
  `∑ (1 ≤ j, k ≤ m, j ≠ k), d[X_j; -X_k] ≤ m(m - 1) D[X_[m]].` -/
lemma multidist_ruzsa_I {m : ℕ} (hm : m ≥ 1) {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    {X : ∀ i, Ω i → G} (hmes : ∀ j, Measurable (X j))
    (hprob : ∀ j, IsProbabilityMeasure (hΩ j).volume) (hfin : ∀ j, FiniteRange (X j)) :
    ∑ j, ∑ k, (if j = k then (0:ℝ) else d[X j # -X k]) ≤ m * (m - 1) * D[X; hΩ] := by
  sorry

/-- Let `m ≥ 2`, and let `X_[m]` be a tuple of `G`-valued random variables. Then
  `∑ j, d[X_j;X_j] ≤ 2 m D[X_[m]]`. -/
lemma multidist_ruzsa_II {m : ℕ} (hm : m ≥ 2) {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    (hprob : ∀ i, IsProbabilityMeasure (hΩ i).volume) (X : ∀ i, Ω i → G)
    (hmes : ∀ i, Measurable (X i)) (hfin : ∀ i, FiniteRange (X i)) :
    ∑ j, d[X j # X j] ≤ 2 * m * D[X; hΩ] := by
  sorry

set_option linter.flexible false in
/-- A version of multidist_ruzsa_III assuming independence. -/
lemma multidist_ruzsa_III' {m : ℕ} (hm : m ≥ 2) {Ω : Type*} {hΩ : MeasureSpace Ω}
    {X : Fin (m + 1) → Ω → G} (hmes : ∀ i, Measurable (X i))
    (hident : ∀ j k, IdentDistrib (X j) (X k)) (hindep : iIndepFun X)
    (hfin : ∀ i, FiniteRange (X i)) [IsProbabilityMeasure (ℙ : Measure Ω)] (i₀ : Fin m) :
    D[Fin.init X ; fun _ ↦ hΩ] ≤ m * d[X i₀.castSucc # X i₀.castSucc] := by
  sorry

/-- Let `I` be an indexing set of size `m ≥ 2`, and let `X_[m]` be a tuple of `G`-valued random
variables. If the `X_i` all have the same distribution, then `D[X_[m]] ≤ m d[X_i;X_i]` for any
`1 ≤ i ≤ m`. -/
lemma multidist_ruzsa_III {m : ℕ} (hm : m ≥ 2) {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    (X : ∀ i, Ω i → G) (hident : ∀ j k, IdentDistrib (X j) (X k)) (hmes : ∀ i, Measurable (X i))
    (hprob : ∀ i, IsProbabilityMeasure (hΩ i).volume) (hfin : ∀ i, FiniteRange (X i)) (i₀ : Fin m) :
    D[X; hΩ] ≤ m * d[X i₀ # X i₀] := by
  sorry

universe u in
/-- Let `m ≥ 2`, and let `X_[m]` be a tuple of `G`-valued random
variables. Let `W := ∑ X_i`. Then `d[W;-W] ≤ 2 D[X_i]`. -/
lemma multidist_ruzsa_IV {m : ℕ} (hm : m ≥ 2) {Ω : Type u} [MeasureSpace Ω] (X : Fin m → Ω → G)
    (h_indep : iIndepFun X) (hmes : ∀ i, Measurable (X i)) [IsProbabilityMeasure (ℙ : Measure Ω)]
    (hfin : ∀ i, FiniteRange (X i)) :
    d[∑ i, X i # - ∑ i, X i] ≤ 2 * D[X; fun _ ↦ inferInstance] := by
  sorry

/-- If `D[X_[m]]=0`, then for each `i ∈ I` there is a finite subgroup `H_i ≤ G` such that
`d[X_i; U_{H_i}] = 0`. -/
lemma multidist_eq_zero [Finite G] {m : ℕ} (hm : m ≥ 2) {Ω : Fin m → Type*}
    (hΩ : ∀ i, MeasureSpace (Ω i)) (hprob : ∀ i, IsProbabilityMeasure (hΩ i).volume)
    (X : ∀ i, Ω i → G) (hvanish : D[X; hΩ] = 0) (hmes : ∀ i, Measurable (X i))
    (hfin : ∀ i, FiniteRange (X i)) (i) :
    ∃ (H : AddSubgroup G) (U : Ω i → G), Measurable U ∧ IsUniform H U ∧ d[X i # U] = 0 := by
  sorry

-- This is probably not the optimal spelling. For instance one could use the `μ "[|" t "]"` notation
-- from Mathlib.ConditionalProbability to simplify the invocation of `cond`
/-- If `X_[m] = (X_1, ..., X_m)` and `Y_[m] = (Y_1, ..., Y_m)` are tuples of random variables,
with the `X_i` being `G`-valued (but the `Y_i` need not be), then we define
`D[X_[m] | Y_[m]] = ∑_{(y_i)_{1 \leq i \leq m}} (∏ i, p_{Y_i}(y_i)) D[(X_i | Y_i = y_i)_{i=1}^m]`
where each `y_i` ranges over the support of `p_{Y_i}` for `1 ≤ i ≤ m`.
-/
@[expose]
noncomputable
def condMultiDist {m : ℕ} {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i)) {S : Type*} [Fintype S]
    (X : ∀ i, Ω i → G) (Y : ∀ i, Ω i → S) : ℝ :=
  ∑ ω : Fin m → S,
    (∏ i, volume.real (Y i ⁻¹' {ω i})) * D[X; fun i ↦ ⟨cond (hΩ i).volume (Y i ⁻¹' {ω i})⟩]

@[inherit_doc multiDist] notation3:max "D[" X " | " Y " ; " hΩ "]" => condMultiDist hΩ X Y

/-- Conditional multidistance is nonnegative. -/
theorem condMultiDist_nonneg [Finite G] {m : ℕ} {Ω : Fin m → Type*} (hΩ : ∀ i, MeasureSpace (Ω i))
    (hprob : ∀ i, IsProbabilityMeasure (ℙ : Measure (Ω i))) {S : Type*} [Fintype S]
    (X : ∀ i, Ω i → G) (Y : ∀ i, Ω i → S) (hX : ∀ i, Measurable (X i)) : 0 ≤ D[X | Y; hΩ] := by
  sorry

/-- A technical lemma: can push a constant into a product at a specific term -/
private lemma Finset.prod_mul {α β : Type*} [Fintype α] [DecidableEq α] [CommMonoid β] (f : α → β)
    (c : β) (i₀ : α) : (∏ i, f i) * c = ∏ i, if i = i₀ then f i * c else f i := by
  sorry

end multiDistance

section multiDistance_chainRule

/-- Let `π : G → H` be a homomorphism of abelian groups and let `X_[m]` be a tuple of jointly
independent `G`-valued random variables. Then `D[X_[m]]` is equal to
`D[X_[m] | π(X_[m])] + D[π(X_[m])] + I[∑ i, X_i : π(X_[m]) ; | ; π(∑ i, X_i)]`
where `π(X_[m]) := (π(X_1), ..., π(X_m))`.
-/
lemma multiDist_chainRule {G H : Type*} [hG : MeasurableSpace G] [MeasurableSingletonClass G]
    [AddCommGroup G] [Finite G] [hH : MeasurableSpace H]
    [MeasurableSingletonClass H] [AddCommGroup H]
    [Fintype H] (π : G →+ H) {m : ℕ} {Ω : Type*} (hΩ : MeasureSpace Ω)
    {X : Fin m → Ω → G} (hmes : ∀ i, Measurable (X i))
    (h_indep : iIndepFun X) :
    D[X; fun _ ↦ hΩ] = D[X | fun i ↦ π ∘ X i; fun _ ↦ hΩ]
      + D[fun i ↦ π ∘ X i; fun _ ↦ hΩ]
      + I[∑ i, X i : fun ω ↦ (fun i ↦ π (X i ω)) | π ∘ (∑ i, X i)] := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Let `π : G → H` be a homomorphism of abelian groups. Let `I` be a finite index set and let
`X_[m]` be a tuple of `G`-valued random variables. Let `Y_[m]` be another tuple of random variables
(not necessarily `G`-valued). Suppose that the pairs `(X_i, Y_i)` are jointly independent of one
another (but `X_i` need not be independent of `Y_i`). Then
`D[X_[m] | Y_[m]] = D[X_[m] ,|, π(X_[m]), Y_[m]] + D[π(X_[m]) ,| , Y_[m]]`
`+ I[∑ i, X_i : π(X_[m]) ; | ; π(∑ i, X_i), Y_[m]]`. -/
lemma cond_multiDist_chainRule {G H : Type*} [hG : MeasurableSpace G] [MeasurableSingletonClass G]
    [AddCommGroup G] [Finite G]
    [hH : MeasurableSpace H] [MeasurableSingletonClass H] [AddCommGroup H]
    [Fintype H] (π : G →+ H)
    {S : Type*} [Fintype S] [hS : MeasurableSpace S] [MeasurableSingletonClass S]
    {m : ℕ} {Ω : Type*} [hΩ : MeasureSpace Ω]
    {X : Fin m → Ω → G} (hX : ∀ i, Measurable (X i))
    {Y : Fin m → Ω → S} (hY : ∀ i, Measurable (Y i))
    (h_indep : iIndepFun (fun i ↦ ⟨X i, Y i⟩)) :
    D[X | Y; fun _ ↦ hΩ] = D[X | fun i ↦ ⟨π ∘ X i, Y i⟩; fun _ ↦ hΩ]
      + D[fun i ↦ π ∘ X i | Y; fun _ ↦ hΩ]
      + I[∑ i, X i : fun ω ↦ (fun i ↦ π (X i ω)) |
            ⟨π ∘ (∑ i, X i), fun ω ↦ (fun i ↦ Y i ω)⟩] := by
  sorry

/-- Let `m` be a positive integer. Suppose one has a sequence
`G_m → G_{m - 1} → ... → G_1 → G_0 = {0}` of homomorphisms between abelian groups `G_0, ...,G_m`,
and for each `d=0, ...,m`, let `π_d : G_m → G_d` be the homomorphism from `G_m` to `G_d` arising
from this sequence by composition
(so for instance `π_m` is the identity homomorphism and `π_0` is the zero homomorphism).
Let `X_[m] = (X_1, ..., X_m)` be a jointly independent tuple of `G_m`-valued random variables.
Then `D[X_[m]] = ∑ d, D[π_d(X_[m]) ,| , π_(d-1)(X_[m])]`
` + ∑_{d=1}^{m - 1}, I[∑ i, X_i : π_d(X_[m]) | π_d(∑ i, X_i), π_(d-1})(X_[m])]`. -/
lemma iter_multiDist_chainRule {m : ℕ}
    {G : Fin (m + 1) → Type*}
    [hG : ∀ i, MeasurableSpace (G i)] [hGs : ∀ i, MeasurableSingletonClass (G i)]
    [∀ i, AddCommGroup (G i)] [hGcount : ∀ i, Fintype (G i)]
    {φ : ∀ i : Fin m, G (i.succ) →+ G i.castSucc} {π : ∀ d, G ⊤ →+ G d}
    (hcomp: ∀ i : Fin m, π i.castSucc = (φ i) ∘ (π i.succ))
    {Ω : Type*} [hΩ : MeasureSpace Ω] {X : Fin m → Ω → G ⊤}
    (hX : ∀ i, Measurable (X i)) (h_indep : iIndepFun X) (n : Fin (m + 1)) :
    D[X | fun i ↦ (π 0) ∘ X i; fun _ ↦ hΩ] = D[X | fun i ↦ (π n) ∘ X i; fun _ ↦ hΩ]
      + ∑ d ∈ Finset.Iio n, (D[fun i ↦ (π (d+1)) ∘ X i | fun i ↦ (π d) ∘ X i; fun _ ↦ hΩ]
      + I[∑ i, X i : fun ω ↦ (fun i ↦ (π (d+1)) (X i ω)) |
            ⟨(π (d+1)) ∘ ∑ i, X i, fun ω ↦ (fun i ↦ (π d) (X i ω))⟩]) := by
  sorry

/-- Under the preceding hypotheses,
`D[X_[m]] ≥ ∑ d, D[π_d(X_[m])| π_(d-1})(X_[m])] + I[∑ i, X_i : π_1(X_[m]) | π_1(∑ i, X_i)]`. -/
lemma iter_multiDist_chainRule' {m : ℕ} (hm : m > 0)
    {G : Fin (m + 1) → Type*} [hG : ∀ i, MeasurableSpace (G i)]
    [hGs : ∀ i, MeasurableSingletonClass (G i)] [hGa : ∀ i, AddCommGroup (G i)]
    [hGcount : ∀ i, Fintype (G i)] {φ : ∀ i : Fin m, G (i.succ) →+ G i.castSucc}
    {π : ∀ d, G ⊤ →+ G d} (hπ0 : π 0 = 0) (hcomp : ∀ i : Fin m, π i.castSucc = φ i ∘ π i.succ)
    {Ω : Type*} [hΩ : MeasureSpace Ω] {X : Fin m → Ω → G ⊤}
    (hX : ∀ i, Measurable (X i)) (h_indep : iIndepFun X) :
    D[X; fun _ ↦ hΩ] ≥
      ∑ d : Fin m, D[fun i ↦ π d.succ ∘ X i | fun i ↦ π d.castSucc ∘ X i; fun _ ↦ hΩ]
      + I[∑ i : Fin m, X i : fun ω i ↦ π 1 (X i ω)| π 1 ∘ ∑ i : Fin m, X i] := by
  sorry

lemma cond_entropy_indep {Ω : Type*} [hΩ : MeasureSpace Ω] {S T U : Type*}
    {X : Ω → S} {Y : Ω → T} {Z : Ω → U}
    [MeasurableSpace S] [MeasurableSingletonClass S] [Finite S]
    [MeasurableSpace T] [MeasurableSingletonClass T] [Finite T]
    [MeasurableSpace U] [MeasurableSingletonClass U] [Finite U]
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [IsZeroOrProbabilityMeasure hΩ.volume] (hindep : IndepFun (⟨X, Y⟩) Z) :
    H[X | ⟨Y, Z⟩] = H[X | Y] := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Let `G` be an abelian group and let `m ≥ 2`. Suppose that `X_{i,j}`, `1 ≤ i, j ≤ m`, are
independent `G`-valued random variables. Then
`I[(∑ i, X_{i,j})_{j=1}^m : (∑ j, X_{i,j})_{i=1}^m | ∑ i j, X_{i,j}]`
is less than
`∑_{j=1}^{m - 1} (D[(X_{i, j})_{i=1}^m]`
`- D[(X_{i, j})_{i = 1}^m | (X_{i,j} + ... + X_{i,m})_{i=1}^m])`
`+ D[(X_{i,m})_{i=1}^m] - D[(∑ j, X_{i,j})_{i=1}^m],`
where all the multidistances here involve the indexing set `{1, ..., m}`. -/
lemma cor_multiDist_chainRule [Fintype G] {m : ℕ} {Ω : Type*} (hΩ : MeasureSpace Ω)
    (X : Fin (m + 1) × Fin (m + 1) → Ω → G) (hmes : ∀ i, Measurable (X i)) (h_indep : iIndepFun X)
    [IsProbabilityMeasure (ℙ : Measure Ω)]:
    I[fun ω ↦ (fun j ↦ ∑ i, X ⟨i, j⟩ ω) : fun ω ↦ (fun i ↦ ∑ j, X ⟨i, j⟩ ω) | ∑ p, X p]
      ≤ ∑ j : Fin m, (D[fun i ↦ X ⟨i, j.castSucc⟩; fun _ ↦ hΩ] - D[fun i ↦ X ⟨i, j.castSucc⟩ |
        fun i ↦ ∑ k ∈ Finset.Ici j.castSucc, X ⟨i, k⟩; fun _ ↦ hΩ]) +
          D[fun i ↦ X ⟨i, ⊤⟩; fun _ ↦ hΩ]
         - D[fun i ↦ ∑ j, X ⟨i, j⟩; fun _ ↦ hΩ] := by
  sorry

end multiDistance_chainRule
