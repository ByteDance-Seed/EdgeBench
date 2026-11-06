module

public import Mathlib.MeasureTheory.Measure.FiniteMeasureProd
public import PFR.ForMathlib.Entropy.Group
public import PFR.ForMathlib.Entropy.Kernel.RuzsaDist
public import PFR.ForMathlib.FiniteRange.IdentDistrib
public import PFR.Mathlib.MeasureTheory.Measure.ProbabilityMeasure

/-!
# Ruzsa distance

Here we define Ruzsa distance and establish its basic properties.

## Main definitions

* `rdist`: The Ruzsa distance $d[X ; Y]$ between two random variables
* `condRuzsaDist`: The conditional Ruzsa distance $d[X | Z ; Y | W]$ (or $d[X ; Y | W]$) between two
  random variables, conditioned on additional random variables

## Main results

* `rdist_triangle`: The Ruzsa triangle inequality for three random variables.
* `kaimanovich_vershik`. $$H[X + Y + Z] - H[X + Y] \leq H[Y+ Z] - H[Y]$$
* `ent_bsg`: If $Z=A+B$, then
  $$\sum_{z} P[Z=z] d[(A | Z = z) ; (B | Z = z)] \leq 3 I[A :B] + 2 H[Z] - H[A] - H[B]$$
-/

@[expose] public section

open Filter Function MeasureTheory Measure ProbabilityTheory
open scoped Topology

variable {Ω Ω' Ω'' Ω''' G S T : Type*}
  [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
  [mΩ' : MeasurableSpace Ω'] {μ' : Measure Ω'}
  [mΩ'' : MeasurableSpace Ω''] {μ'' : Measure Ω''}
  [mΩ''' : MeasurableSpace Ω'''] {μ''' : Measure Ω'''}
  [hG : MeasurableSpace G]

variable [AddCommGroup G]
  {X : Ω → G} {Y : Ω' → G} {Z : Ω'' → G}

/-- The Ruzsa distance `rdist X Y` or `d[X ; Y]` between two random variables is defined as
`H[X'- Y'] - H[X']/2 - H[Y']/2`, where `X', Y'` are independent copies of `X, Y`. -/
noncomputable
def rdist (X : Ω → G) (Y : Ω' → G) (μ : Measure Ω := by volume_tac)
    (μ' : Measure Ω' := by volume_tac) : ℝ :=
  H[fun x ↦ x.1 - x.2 ; (μ.map X).prod (μ'.map Y)] - H[X ; μ]/2 - H[Y ; μ']/2

/- Needed a new separator here, chose `#` arbitrarily, but am open to other suggestions -/
@[inherit_doc rdist] notation3:max "d[" X "; " μ " # " Y "; " μ' "]" => rdist X Y μ μ'

@[inherit_doc rdist] notation3:max "d[" X " # " Y "]" => rdist X Y volume volume

/-- Ruzsa distance depends continuously on the measure. -/
lemma continuous_rdist_restrict_probabilityMeasure [Finite G]
    [TopologicalSpace G] [DiscreteTopology G] [BorelSpace G] :
    Continuous
      (fun (μ : ProbabilityMeasure G × ProbabilityMeasure G) ↦
        d[id ; μ.1.toMeasure # id ; μ.2.toMeasure]) := by
  sorry

lemma continuous_rdist_restrict_probabilityMeasure₁ [Finite G]
    [TopologicalSpace G] [DiscreteTopology G] [BorelSpace G]
    (X : Ω → G) (P : Measure Ω := by volume_tac) [IsProbabilityMeasure P] (X_mble : Measurable X) :
    Continuous
      (fun (μ : ProbabilityMeasure G) ↦ d[id ; P.map X # id ; μ.toMeasure]) := by
  have obs : IsProbabilityMeasure (P.map X) := by
    refine ⟨by simp [Measure.map_apply X_mble MeasurableSet.univ]⟩
  let ι : ProbabilityMeasure G → ProbabilityMeasure G × ProbabilityMeasure G :=
      fun ν ↦ ⟨⟨P.map X, obs⟩, ν⟩
  have ι_cont : Continuous ι := Continuous.prodMk_right _
  convert continuous_rdist_restrict_probabilityMeasure.comp ι_cont

/-- Ruzsa distance between random variables equals Ruzsa distance between their distributions. -/
lemma rdist_eq_rdist_id_map : d[X ; μ # Y ; μ'] = d[id ; μ.map X # id ; μ'.map Y] := by
  sorry

/-- Ruzsa distance depends continuously on the second measure. -/
lemma continuous_rdist_restrict_probabilityMeasure₁' [Finite G]
    [TopologicalSpace G] [DiscreteTopology G] [BorelSpace G]
    (X : Ω → G) (P : Measure Ω := by volume_tac) [IsProbabilityMeasure P] (X_mble : Measurable X) :
    Continuous
      (fun (μ : ProbabilityMeasure G) ↦ d[X ; P # id ; μ.toMeasure]) := by
  simp only [@rdist_eq_rdist_id_map Ω G G mΩ P hG, Measure.map_id]
  exact continuous_rdist_restrict_probabilityMeasure₁ _ _ X_mble

/-- If `X', Y'` are copies of `X, Y` respectively then `d[X' ; Y'] = d[X ; Y]`. -/
lemma ProbabilityTheory.IdentDistrib.rdist_congr {X' : Ω'' → G} {Y' : Ω''' → G}
    (hX : IdentDistrib X X' μ μ'') (hY : IdentDistrib Y Y' μ' μ''') :
    d[X ; μ # Y ; μ'] = d[X' ; μ'' # Y' ; μ'''] := by
  sorry

section rdist

variable [Countable G] [MeasurableSingletonClass G]

/-- If `X, Y` are independent `G`-random variables then `d[X ; Y] = H[X - Y] - H[X]/2 - H[Y]/2`. -/
lemma ProbabilityTheory.IndepFun.rdist_eq [IsFiniteMeasure μ]
    {Y : Ω → G} (h : IndepFun X Y μ) (hX : Measurable X) (hY : Measurable Y) :
    d[X ; μ # Y ; μ] = H[X - Y ; μ] - H[X ; μ]/2 - H[Y ; μ]/2 := by
  sorry

/-- `d[X ; Y] ≤ H[X]/2 + H[Y]/2`. -/
lemma rdist_le_avg_ent {X : Ω → G} {Y : Ω' → G} [FiniteRange X] [FiniteRange Y] (hX : Measurable X)
    (hY : Measurable Y) (μ : Measure Ω := by volume_tac) (μ' : Measure Ω' := by volume_tac)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] :
    d[X ; μ # Y ; μ'] ≤ (H[X ; μ] + H[Y ; μ'])/2 := by
  rcases ProbabilityTheory.independent_copies_finiteRange hX hY μ μ'
    with ⟨ν, X', Y', hprob, hX', hY', h_indep, hidentX, hidentY, hfinX, hfinY⟩
  rw [← hidentX.rdist_congr hidentY,
    ← hidentX.entropy_congr, ← IdentDistrib.entropy_congr hidentY,
    h_indep.rdist_eq hX' hY']
  suffices H[X' - Y'; ν] ≤ H[X'; ν] + H[Y'; ν] by linarith
  change H[(fun x ↦ x.1 - x.2) ∘ ⟨X',Y' ⟩; ν] ≤ H[X'; ν] + H[Y'; ν]
  exact ((entropy_comp_le ν (by fun_prop) _).trans) (entropy_pair_le_add hX' hY' ν)

/-- `d[X ; Y] = d[Y ; X]` -/
lemma rdist_symm [IsFiniteMeasure μ] [IsFiniteMeasure μ'] :
    d[X ; μ # Y ; μ'] = d[Y ; μ' # X ; μ] := by
  sorry

omit [Countable G] in
/-- Ruzsa distance depends continuously on the first measure. -/
lemma continuous_rdist_restrict_probabilityMeasure₁_left [Finite G]
    [TopologicalSpace G] [DiscreteTopology G] [BorelSpace G]
    (X : Ω → G) (P : Measure Ω := by volume_tac) [IsProbabilityMeasure P] (X_mble : Measurable X) :
    Continuous
      (fun (μ : ProbabilityMeasure G) ↦ d[id ; μ.toMeasure # X ; P]) := by
  convert continuous_rdist_restrict_probabilityMeasure₁' X P X_mble using 2
  rw [rdist_symm]

variable [FiniteRange X] [FiniteRange Y]

/-- `|H[X] - H[Y]| ≤ 2 d[X ; Y]`. -/
lemma diff_ent_le_rdist [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hY : Measurable Y) :
    |H[X ; μ] - H[Y ; μ']| ≤ 2 * d[X ; μ # Y ; μ'] := by
  sorry

/-- `H[X - Y] - H[X] ≤ 2d[X ; Y]`. -/
lemma diff_ent_le_rdist' [IsProbabilityMeasure μ] {Y : Ω → G}
    (hX : Measurable X) (hY : Measurable Y) (h : IndepFun X Y μ) [FiniteRange Y] :
    H[X - Y ; μ] - H[X ; μ] ≤ 2 * d[X ; μ # Y ; μ] := by
  sorry

/-- `H[X - Y] - H[Y] ≤ 2d[X ; Y]`. -/
lemma diff_ent_le_rdist'' [IsProbabilityMeasure μ] {Y : Ω → G}
    (hX : Measurable X) (hY : Measurable Y) (h : IndepFun X Y μ) [FiniteRange Y] :
    H[X - Y ; μ] - H[Y ; μ] ≤ 2 * d[X ; μ # Y ; μ] := by
  sorry

/-- `d[X ; Y] ≥ 0`. -/
lemma rdist_nonneg [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hY : Measurable Y) : 0 ≤ d[X ; μ # Y ; μ'] := by
  sorry

/-- If $G$ is an additive group and $X$ is a $G$-valued random variable and
$H\leq G$ is a finite subgroup then, with $\pi:G\to G/H$ the natural homomorphism we have
(where $U_H$ is uniform on $H$) $\mathbb{H}(\pi(X))\leq 2d[X;U_H].$ -/
lemma ent_of_proj_le {UH : Ω' → G} [FiniteRange UH]
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hU : Measurable UH) {H : AddSubgroup G} (hH : Set.Finite (H : Set G))
    -- TODO: infer from [FiniteRange UH]?
    (hunif : IsUniform H UH μ') :
    H[(QuotientAddGroup.mk' H) ∘ X; μ] ≤ 2 * d[X; μ # UH ; μ'] := by
  sorry

/-- The **improved entropic Ruzsa triangle inequality**. -/
lemma ent_of_diff_le (X : Ω → G) (Y : Ω → G) (Z : Ω → G)
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (h : IndepFun (⟨X, Y⟩) Z μ)
    [IsProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    H[X - Y; μ] ≤ H[X - Z; μ] + H[Z - Y; μ] - H[Z; μ] := by
  sorry

/-- The **entropic Ruzsa triangle inequality** -/
lemma rdist_triangle {X : Ω → G} {Y : Ω' → G} {Z : Ω'' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [hμ : IsProbabilityMeasure μ] [hμ' : IsProbabilityMeasure μ']
    [hμ'' : IsProbabilityMeasure μ''] [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    d[X ; μ # Z ; μ''] ≤ d[X ; μ # Y ; μ'] + d[Y ; μ' # Z ; μ''] := by
  sorry

end rdist

variable [MeasurableSpace S] [MeasurableSpace T] [Countable G] [MeasurableSingletonClass G]

/-- The conditional Ruzsa distance `d[X|Z ; Y|W]`. -/
noncomputable
def condRuzsaDist (X : Ω → G) (Z : Ω → S) (Y : Ω' → G) (W : Ω' → T)
    (μ : Measure Ω := by volume_tac) [IsFiniteMeasure μ]
    (μ' : Measure Ω' := by volume_tac) [IsFiniteMeasure μ'] : ℝ :=
  dk[condDistrib X Z μ ; μ.map Z # condDistrib Y W μ' ; μ'.map W]

@[inherit_doc condRuzsaDist]
notation3:max "d[" X " | " Z " ; " μ " # " Y " | " W " ; " μ'"]" => condRuzsaDist X Z Y W μ μ'

@[inherit_doc condRuzsaDist]
notation3:max "d[" X " | " Z " # " Y " | " W "]" => condRuzsaDist X Z Y W volume volume

@[simp] lemma condRuszaDist_zero_right (X : Ω → G) (Z : Ω → S) (Y : Ω' → G) (W : Ω' → T)
    (μ : Measure Ω) [IsFiniteMeasure μ] :
    d[X | Z ; μ # Y | W ; 0] = 0 := by
  sorry

@[simp] lemma condRuszaDist_zero_left (X : Ω → G) (Z : Ω → S) (Y : Ω' → G) (W : Ω' → T)
    (μ' : Measure Ω') [IsFiniteMeasure μ'] :
    d[X | Z ; 0 # Y | W ; μ'] = 0 := by
  sorry

variable [MeasurableSingletonClass S] [MeasurableSingletonClass T]

variable [Countable S]

lemma condRuzsaDist_nonneg [Countable T] {X : Ω → G} (hX : Measurable X) [FiniteRange X]
    {Z : Ω → S} (hZ : Measurable Z) [FiniteRange Z]
    {Y : Ω' → G} (hY : Measurable Y) [FiniteRange Y]
    {W : Ω' → T} (hW : Measurable W) [FiniteRange W]
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] :
    0 ≤ d[X | Z ; μ # Y | W ; μ'] := by
  sorry

/-- The conditional Ruzsa distance `d[X ; Y|W]`. -/
noncomputable
def condRuzsaDist' (X : Ω → G) (Y : Ω' → G) (W : Ω' → T)
    (μ : Measure Ω := by volume_tac) (μ' : Measure Ω' := by volume_tac) [IsFiniteMeasure μ'] : ℝ :=
  dk[Kernel.const Unit (μ.map X) ; Measure.dirac () # condDistrib Y W μ' ; μ'.map W]

@[inherit_doc condRuzsaDist']
notation3:max "d[" X " ; " μ " # " Y " | " W " ; " μ' "]" => condRuzsaDist' X Y W μ μ'
@[inherit_doc condRuzsaDist']
notation3:max "d[" X " # " Y " | " W "]" => condRuzsaDist' X Y W volume volume

open scoped ENNReal

section

variable [Countable T]

/-- Formula for conditional Ruzsa distance for independent sets of variables. -/
lemma condRuzsaDist'_of_indep {X : Ω → G} {Y : Ω → G} {W : Ω → T}
    (hX : Measurable X) (hY : Measurable Y) (hW : Measurable W)
    (μ : Measure Ω) [IsProbabilityMeasure μ]
    (h : IndepFun X (⟨Y, W⟩) μ) [FiniteRange W] :
    d[X ; μ # Y | W ; μ] = H[X - Y | W ; μ] - H[X ; μ]/2 - H[Y | W ; μ]/2 := by
  sorry

end

omit [Countable S] in

variable (μ μ') in

set_option linter.flexible false in

/-- The **Kaimanovich-Vershik inequality**. `H[X + Y + Z] - H[X + Y] ≤ H[Y + Z] - H[Y]`. -/
lemma kaimanovich_vershik {X Y Z : Ω → G} (h : iIndepFun ![X, Y, Z] μ)
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    H[X + Y + Z ; μ] - H[X + Y ; μ] ≤ H[Y + Z ; μ] - H[Y ; μ] := by
  sorry

/-- A version of the **Kaimanovich-Vershik inequality** with some variables negated. -/
lemma kaimanovich_vershik' {X Y Z : Ω → G} (h : iIndepFun ![X, Y, Z] μ)
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    H[X - (Y + Z) ; μ] - H[X - Y ; μ] ≤ H[Y + Z ; μ] - H[Y ; μ] := by
  sorry

section BalogSzemerediGowers

/-- The **entropic Balog-Szemerédi-Gowers inequality**. Let `A, B` be `G`-valued random variables on
`Ω`, and set `Z := A+B`. Then
`∑ z, P[Z=z] d[(A | Z = z) ; (B | Z = z)] ≤ 3 I[A :B] + 2 H[Z] - H[A] - H[B].`
TODO: remove the hypothesis of `Fintype G` from here and from `condIndep_copies'` -/
lemma ent_bsg [IsProbabilityMeasure μ] {A B : Ω → G} (hA : Measurable A) (hB : Measurable B)
    [Finite G] :
    (μ.map (A + B))[fun z ↦ d[A ; μ[|(A + B) ⁻¹' {z}] # B ; μ[|(A + B) ⁻¹' {z}]]]
      ≤ 3 * I[A : B; μ] + 2 * H[A + B ; μ] - H[A ; μ] - H[B ; μ] := by
  sorry

end BalogSzemerediGowers

variable (μ μ') in
/-- Suppose that $(X, Z)$ and $(Y, W)$ are random variables, where $X, Y$ take values in an abelian
group. Then $$d[X | Z ; Y | W] \leq d[X ; Y] + \tfrac{1}{2} I[X : Z] + \tfrac{1}{2} I[Y : W]$$ -/
lemma condRuzsaDist_le [Countable T] {X : Ω → G} {Z : Ω → S} {Y : Ω' → G} {W : Ω' → T}
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hZ : Measurable Z) (hY : Measurable Y) (hW : Measurable W)
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] [FiniteRange W] :
      d[X | Z ; μ # Y|W ; μ'] ≤ d[X ; μ # Y ; μ'] + I[X : Z ; μ]/2 + I[Y : W ; μ']/2 := by
  sorry

variable (μ μ') in
lemma condRuzsaDist_le' [Countable T] {X : Ω → G} {Y : Ω' → G} {W : Ω' → T}
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hY : Measurable Y) (hW : Measurable W)
    [FiniteRange X] [FiniteRange Y] [FiniteRange W] :
    d[X ; μ # Y|W ; μ'] ≤ d[X ; μ # Y ; μ'] + I[Y : W ; μ']/2 := by
  sorry

variable (μ μ') in
lemma condRuzsaDist_le'_prod [Countable T] {X : Ω → G} {Y : Ω' → G} {W Z : Ω' → T}
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    (hX : Measurable X) (hY : Measurable Y) (hW : Measurable W) (hZ : Measurable Z)
    [FiniteRange X] [FiniteRange Y] [FiniteRange W] [FiniteRange Z] :
    d[X ; μ # Y|⟨W, Z⟩ ; μ'] ≤ d[X ; μ # Y|Z ; μ'] + I[Y : W | Z ; μ']/2 := by
  sorry

variable (μ) in
lemma comparison_of_ruzsa_distances [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    d[X ; μ # Y+ Z ; μ'] - d[X ; μ # Y ; μ'] ≤ (H[Y + Z; μ'] - H[Y; μ']) / 2 ∧
    (Module (ZMod 2) G →
      H[Y + Z; μ'] - H[Y; μ'] = d[Y; μ' # Z; μ'] + H[Z; μ'] / 2 - H[Y; μ'] / 2) := by
  sorry

variable (μ) in
/-- Let `X, Y, Z` be random variables taking values in some abelian group, and with `Y, Z`
independent. Then we have
`d[X ; Y + Z] - d[X ; Y] ≤ 1/2 (H[Y+ Z] - H[Y])`
$$= \tfrac{1}{2} d[Y ; Z] + \tfrac{1}{4} H[Z] - \tfrac{1}{4} H[Y]$$
and
$$d[X ; Y|Y+ Z] - d[X ; Y] \leq \tfrac{1}{2} \bigl(H[Y+ Z] - H[Z]\bigr)$$
$$= \tfrac{1}{2} d[Y ; Z] + \tfrac{1}{4} H[Y] - \tfrac{1}{4} H[Z]$$
-/
lemma condRuzsaDist_diff_le [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    d[X ; μ # Y+ Z ; μ'] - d[X ; μ # Y ; μ'] ≤ (H[Y + Z; μ'] - H[Y; μ']) / 2 := by
  sorry

variable (μ) [Module (ZMod 2) G] in
lemma entropy_sub_entropy_eq_condRuzsaDist_add [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    H[Y + Z; μ'] - H[Y; μ'] = d[Y; μ' # Z; μ'] + H[Z; μ'] / 2 - H[Y; μ'] / 2 := by
  sorry

variable (μ) [Module (ZMod 2) G] in
lemma condRuzsaDist_diff_le' [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    d[X ; μ # Y + Z; μ'] - d[X ; μ # Y; μ'] ≤
    d[Y; μ' # Z; μ'] / 2 + H[Z; μ'] / 4 - H[Y; μ'] / 4 := by
  sorry

variable (μ) in
lemma condRuzsaDist_diff_le'' [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    d[X ; μ # Y|Y+ Z ; μ'] - d[X ; μ # Y ; μ'] ≤ (H[Y+ Z ; μ'] - H[Z ; μ'])/2 := by
  sorry

variable (μ) [Module (ZMod 2) G] in
lemma condRuzsaDist_diff_le''' [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y : Ω' → G} {Z : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (h : IndepFun Y Z μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] :
    d[X ; μ # Y|Y+ Z ; μ'] - d[X ; μ # Y ; μ'] ≤
    d[Y ; μ' # Z ; μ']/2 + H[Y ; μ']/4 - H[Z ; μ']/4 := by
  sorry

variable (μ) in
lemma condRuzsaDist_diff_ofsum_le [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']
    {X : Ω → G} {Y Z Z' : Ω' → G}
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) (hZ' : Measurable Z')
    (h : iIndepFun ![Y, Z, Z'] μ')
    [FiniteRange X] [FiniteRange Z] [FiniteRange Y] [FiniteRange Z'] :
    d[X ; μ # Y + Z | Y + Z + Z'; μ'] - d[X ; μ # Y; μ'] ≤
    (H[Y + Z + Z'; μ'] + H[Y + Z; μ'] - H[Y ; μ'] - H[Z' ; μ'])/2 := by
  sorry
