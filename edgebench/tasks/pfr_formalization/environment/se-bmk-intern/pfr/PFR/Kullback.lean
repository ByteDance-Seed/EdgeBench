module

public import Mathlib.Probability.IdentDistrib
public import PFR.ForMathlib.Entropy.Basic
public import PFR.ForMathlib.FiniteRange.Defs
public import PFR.Mathlib.Analysis.SpecialFunctions.NegMulLog
public import PFR.Mathlib.MeasureTheory.Measure.ProbabilityMeasure

/-!
# Kullback-Leibler divergence

Definition of Kullback-Leibler divergence and basic facts
-/

@[expose] public section

open MeasureTheory ProbabilityTheory Real Filter
open scoped Topology

variable {Ω Ω' Ω'' Ω''' G : Type*}
  [mΩ : MeasurableSpace Ω] {μ : Measure Ω}
  [mΩ' : MeasurableSpace Ω'] {μ' : Measure Ω'}
  [mΩ'' : MeasurableSpace Ω''] {μ'' : Measure Ω''}
  [mΩ''' : MeasurableSpace Ω'''] {μ''' : Measure Ω'''}
  [hG : MeasurableSpace G]

variable {X : Ω → G} {Y : Ω' → G}

/-- If `X, Y` are two `G`-valued random variables, the Kullback--Leibler divergence is defined as
  `KL(X ‖ Y) := ∑ₓ 𝐏(X = x) log (𝐏(X = x) / 𝐏(Y = x))`.

Note that this definition only makes sense when `X` is absolutely continuous wrt to `Y`,
i.e., `∀ x, 𝐏(Y = x) = 0 → 𝐏(X = x) = 0`. Otherwise, the divergence should be infinite, but since
we use real numbers for ease of computations, this is not a possible choice. -/
noncomputable def KLDiv (X : Ω → G) (Y : Ω' → G) (μ : Measure Ω := by volume_tac)
    (μ' : Measure Ω' := by volume_tac) : ℝ :=
  ∑' x, (μ.map X).real {x} * log ((μ.map X).real {x} / ((μ'.map Y).real {x}))

@[inherit_doc KLDiv] notation3:max "KL[" X " ; " μ " # " Y " ; " μ' "]" => KLDiv X Y μ μ'

@[inherit_doc KLDiv] notation3:max "KL[" X " # " Y "]" => KLDiv X Y volume volume

/-- `KL(X ‖ Y) = 0` if and only if `Y` is a copy of `X`. -/
lemma KLDiv_eq_zero_iff_identDistrib [Finite G] [MeasurableSingletonClass G]
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] (hX : Measurable X) (hY : Measurable Y)
    (habs : ∀ x, (μ'.map Y).real {x} = 0 → (μ.map X).real {x} = 0) :
    KL[X ; μ # Y ; μ'] = 0 ↔ IdentDistrib X Y μ μ' := by
  sorry

lemma KLDiv_add_const [AddCommGroup G] [DiscreteMeasurableSpace G]
    {X : Ω → G} {Y : Ω' → G} (hX : Measurable X) (hY : Measurable Y) (s : G) :
    KL[(fun ω ↦ X ω + s) ; μ # (fun ω ↦ Y ω + s) ; μ'] = KL[X ; μ # Y ; μ'] := by
  sorry

open Set

open scoped Pointwise

/-- If $X,Y,Z$ are random variables, with $X,Z$ defined on the same sample space, we define
$$ D_{KL}(X|Z \Vert Y) := \sum_z \mathbf{P}(Z=z) D_{KL}( (X|Z=z) \Vert Y).$$ -/
noncomputable def condKLDiv {S : Type*} (X : Ω → G) (Y : Ω' → G) (Z : Ω → S)
    (μ : Measure Ω := by volume_tac) (μ' : Measure Ω' := by volume_tac) : ℝ :=
  ∑' z, μ.real (Z⁻¹' {z}) * KL[X ; cond μ (Z⁻¹' {z}) # Y ; μ']

@[inherit_doc condKLDiv]
notation3:max "KL[" X " | " Z " ; " μ " # " Y " ; " μ' "]" => condKLDiv X Y Z μ μ'

@[inherit_doc condKLDiv]
notation3:max "KL[" X " | " Z " # " Y "]" => condKLDiv X Y Z volume volume

/-- `KL(X|Z ‖ Y) ≥ 0`. -/
lemma condKLDiv_nonneg {S : Type*} [MeasurableSingletonClass G] [Finite G]
    {X : Ω → G} {Y : Ω' → G} {Z : Ω → S}
    [IsZeroOrProbabilityMeasure μ']
    (hX : Measurable X) (hY : Measurable Y)
    (habs : ∀ x, μ'.map Y {x} = 0 → μ.map X {x} = 0) :
    0 ≤ KL[X | Z; μ # Y ; μ'] := by
  sorry

