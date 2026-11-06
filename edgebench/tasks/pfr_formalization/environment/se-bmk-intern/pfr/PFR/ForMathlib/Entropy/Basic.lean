module

public import PFR.ForMathlib.ConditionalIndependence
public import PFR.ForMathlib.Entropy.Kernel.MutualInfo
public import PFR.ForMathlib.Uniform
public import PFR.Mathlib.Probability.ConditionalProbability

/-!
# Entropy and conditional entropy

## Main definitions

* `entropy`: entropy of a random variable, defined as `measureEntropy (volume.map X)`
* `condEntropy`: conditional entropy of a random variable `X` w.r.t. another one `Y`
* `mutualInfo`: mutual information of two random variables

## Main statements

* `chain_rule`: $H[⟨X, Y⟩] = H[Y] + H[X | Y]$
* `entropy_cond_le_entropy`: $H[X | Y] ≤ H[X]$. (Chain rule another way.)
* `entropy_triple_add_entropy_le` (Submodularity of entropy.) :
  $H[X, Y, Z] + H[Z] ≤ H[X, Z] + H[Y, Z]$.

## Notations

* `H[X] = entropy X`
* `H[X | Y ← y] = Hm[(ℙ[|Y ← y]).map X]`
* `H[X | Y] = condEntropy X Y`, such that `H[X | Y] = (volume.map Y)[fun y ↦ H[X | Y ← y]]`
* `I[X : Y] = mutualInfo X Y`

All notations have variants where we can specify the measure (which is otherwise
supposed to be `volume`). For example `H[X ; μ]` and `I[X : Y ; μ]` instead of `H[X]` and
`I[X : Y]` respectively.

-/

@[expose] public section

open Function MeasureTheory Measure Real
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory
variable {Ω S T U T' : Type*} [mΩ : MeasurableSpace Ω] [MeasurableSpace S] [MeasurableSpace U]
  {X : Ω → S} {Y : Ω → T} {Z : Ω → U} {μ : Measure Ω}

section entropy

/-- Entropy of a random variable with values in a finite measurable space. -/
noncomputable
def entropy (X : Ω → S) (μ : Measure Ω := by volume_tac) := Hm[μ.map X]

@[inherit_doc entropy] notation3:max "H[" X "; " μ "]" => entropy X μ
@[inherit_doc entropy] notation3:max "H[" X "]" => entropy X volume
@[inherit_doc entropy] notation3:max "H[" X " | " Y " ← " y "; " μ "]" => entropy X (μ[|Y ← y])
@[inherit_doc entropy] notation3:max "H[" X " | " Y " ← " y "]" => entropy X (ℙ[|Y ← y])

/-- Two variables that have the same distribution, have the same entropy. -/
lemma IdentDistrib.entropy_congr {Ω' : Type*} [MeasurableSpace Ω'] {μ' : Measure Ω'} {X' : Ω' → S}
    (h : IdentDistrib X X' μ μ') : H[X ; μ] = H[X' ; μ'] := by
  sorry

lemma entropy_eq_sum' (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ] :
    entropy X μ = ∑' x, negMulLog ((μ.map X).real {x}) := by
  sorry

lemma entropy_eq_sum_finiteRange' [MeasurableSingletonClass S] (hX : Measurable X) {μ : Measure Ω}
    [IsZeroOrProbabilityMeasure μ] [FiniteRange X] :
    entropy X μ = ∑ x ∈ FiniteRange.toFinset X, negMulLog ((μ.map X).real {x}) := by
  sorry

/-- If `X`, `Y` are `S`-valued and `T`-valued random variables, and `Y = f(X)` for
some injection `f : S \to T`, then `H[Y] = H[X]`.
One can also use `entropy_of_comp_eq_of_comp` as an alternative if verifying injectivity is fiddly.
For the upper bound only, see `entropy_comp_le`. -/
lemma entropy_comp_of_injective [MeasurableSpace T] [Countable S] [MeasurableSingletonClass S]
    [MeasurableSingletonClass T]
    (μ : Measure Ω) (hX : Measurable X) (f : S → T) (hf : Function.Injective f) :
    H[f ∘ X ; μ] = H[X ; μ] := by
  sorry

open Set

open Function

/-- If `X` is `S`-valued random variable, then `H[X] = log |S|` if and only if `X` is uniformly
distributed. -/
lemma entropy_eq_log_card {X : Ω → S} [Fintype S] [MeasurableSingletonClass S]
    (hX : Measurable X) (μ : Measure Ω) [hμ : NeZero μ]
    [IsFiniteMeasure μ] :
    entropy X μ = log (Fintype.card S) ↔ ∀ s, μ.map X {s} = μ Set.univ / Fintype.card S := by
  sorry

variable [Countable S] [MeasurableSingletonClass S]
  [MeasurableSpace T] [MeasurableSingletonClass T]
  [Countable U] [MeasurableSingletonClass U]

variable [Countable T]

/-- `H[X, Y] = H[Y, X]`. -/
lemma entropy_comm (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨X, Y⟩; μ] = H[⟨Y, X⟩ ; μ] := by
  sorry

end entropy

section condEntropy

variable [MeasurableSpace T]

variable {X : Ω → S} {Y : Ω → T}

/-- Conditional entropy of a random variable w.r.t. another.
This is the expectation under the law of `Y` of the entropy of the law of `X` conditioned on the
event `Y = y`. -/
noncomputable
def condEntropy (X : Ω → S) (Y : Ω → T) (μ : Measure Ω := by volume_tac) : ℝ :=
  (μ.map Y)[fun y ↦ H[X | Y ← y ; μ]]

@[inherit_doc condEntropy] notation3:max "H[" X " | " Y " ; " μ "]" => condEntropy X Y μ
@[inherit_doc condEntropy] notation3:max "H[" X " | " Y "]" => condEntropy X Y volume

section

variable [MeasurableSingletonClass T]

lemma condEntropy_eq_zero (hY : Measurable Y) (μ : Measure Ω) [IsFiniteMeasure μ] (t : T)
    (ht : (μ.map Y).real {t} = 0) : H[X | Y ← t ; μ] = 0 := by
  sorry

/-- Conditional entropy of a random variable is equal to the entropy of its conditional kernel. -/
lemma condEntropy_eq_kernel_entropy [Nonempty S] [Countable S] [MeasurableSingletonClass S]
    (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) [IsFiniteMeasure μ] [FiniteRange Y] :
    H[X | Y ; μ] = Hk[condDistrib X Y μ, μ.map Y] := by
  sorry

variable [Countable T] [Nonempty T] [Nonempty S] [MeasurableSingletonClass S] [Countable S]
  [Countable U] [MeasurableSingletonClass U]

end

/-- Conditional entropy is at most the logarithm of the cardinality of the range. -/
lemma condEntropy_le_log_card [MeasurableSingletonClass S] [Fintype S]
    (X : Ω → S) (Y : Ω → T) (hY : Measurable Y) (μ : Measure Ω) [IsProbabilityMeasure μ] :
    H[X | Y ; μ] ≤ log (Fintype.card S) := by
  sorry

variable [MeasurableSingletonClass T]

variable [MeasurableSingletonClass S]

omit [MeasurableSingletonClass S] in

/-- Same as previous lemma, but with a sum over a product space rather than a double sum. -/
lemma condEntropy_eq_sum_prod (hX : Measurable X) {Y : Ω → T}
    (hY : Measurable Y)
    (μ : Measure Ω) [IsProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] :
    H[X | Y ; μ] = ∑ p ∈ (FiniteRange.toFinset X) ×ˢ (FiniteRange.toFinset Y),
      (μ.map Y).real {p.2} * negMulLog (((μ[|Y ⁻¹' {p.2}]).map X).real {p.1}) := by
  sorry

variable [Countable S]

/-- If `X : Ω → S`, `Y : Ω → T` are random variables, and `f : T × S → U` is
  injective for each fixed `t ∈ T`, then `H[f(Y, X) | Y] = H[X | Y]`.
  Thus for instance `H[X-Y|Y] = H[X|Y]`. -/
lemma condEntropy_of_injective
    [MeasurableSingletonClass U] (μ : Measure Ω) [IsFiniteMeasure μ] (hX : Measurable X)
    (hY : Measurable Y) (f : T → S → U) (hf : ∀ t, Injective (f t)) [FiniteRange Y] :
    H[(fun ω ↦ f (Y ω) (X ω)) | Y ; μ] = H[X | Y ; μ] := by
  sorry

end condEntropy

section pair

variable [MeasurableSpace T]
variable [Countable S] [MeasurableSingletonClass S]
  [Countable T] [MeasurableSingletonClass T]

variable [Countable U] [MeasurableSingletonClass U]

/-- Data-processing inequality for the entropy: `H[f(X)] ≤ H[X]`.
To upgrade this to equality, see `entropy_of_comp_eq_of_comp` or `entropy_comp_of_injective`. -/
lemma entropy_comp_le (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ]
    (hX : Measurable X) (f : S → U) [FiniteRange X] :
    H[f ∘ X ; μ] ≤ H[X ; μ] := by
  sorry

end pair

section mutualInfo

variable [MeasurableSpace T]

/-- The mutual information `I[X : Y]` of two random variables
is defined to be `H[X] + H[Y] - H[X ; Y]`. -/
noncomputable
def mutualInfo (X : Ω → S) (Y : Ω → T) (μ : Measure Ω := by volume_tac) : ℝ :=
  H[X ; μ] + H[Y ; μ] - H[⟨X, Y⟩ ; μ]

@[inherit_doc mutualInfo] notation3:max "I[" X " : " Y " ; " μ "]" => mutualInfo X Y μ
@[inherit_doc mutualInfo] notation3:max "I[" X " : " Y "]" => mutualInfo X Y volume

lemma mutualInfo_def (X : Ω → S) (Y : Ω → T) (μ : Measure Ω) :
  I[X : Y ; μ] = H[X ; μ] + H[Y ; μ] - H[⟨X, Y⟩ ; μ] := by
  sorry

/-- The conditional mutual information `I[X : Y| Z]` is the mutual information of `X| Z=z` and
`Y| Z=z`, integrated over `z`. -/
noncomputable
def condMutualInfo (X : Ω → S) (Y : Ω → T) (Z : Ω → U) (μ : Measure Ω := by volume_tac) :
    ℝ := (μ.map Z)[fun z ↦ H[X | Z ← z ; μ] + H[Y | Z ← z ; μ] - H[⟨X, Y⟩ | Z ← z ; μ]]

lemma condMutualInfo_def (X : Ω → S) (Y : Ω → T) (Z : Ω → U) (μ : Measure Ω) :
    condMutualInfo X Y Z μ = (μ.map Z)[fun z ↦
      H[X | Z ← z ; μ] + H[Y | Z ← z ; μ] - H[⟨X, Y⟩ | Z ← z ; μ]] := by
  sorry

@[inherit_doc condMutualInfo]
notation3:max "I[" X " : " Y "|" Z ";" μ "]" => condMutualInfo X Y Z μ
@[inherit_doc condMutualInfo]
notation3:max "I[" X " : " Y "|" Z "]" => condMutualInfo X Y Z volume

lemma condMutualInfo_eq_integral_mutualInfo :
    I[X : Y | Z ; μ] = (μ.map Z)[fun z ↦ I[X : Y ; μ[| Z ⁻¹' {z}]]] := by
  sorry

section

variable [MeasurableSingletonClass S] [MeasurableSingletonClass T]

/-- Subadditivity of entropy. -/
lemma entropy_pair_le_add (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) [FiniteRange X]
    [FiniteRange Y] : H[⟨X, Y⟩ ; μ] ≤ H[X ; μ] + H[Y ; μ] := by
  sorry

/-- `I[X : Y] = 0` iff `X, Y` are independent. -/
lemma mutualInfo_eq_zero (hX : Measurable X) (hY : Measurable Y) {μ : Measure Ω}
    [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] :
    I[X : Y ; μ] = 0 ↔ IndepFun X Y μ := by
  sorry

protected alias ⟨_, IndepFun.mutualInfo_eq_zero⟩ := mutualInfo_eq_zero

/-- `H[X, Y] = H[X] + H[Y]` if and only if `X, Y` are independent. -/
lemma entropy_pair_eq_add (hX : Measurable X) (hY : Measurable Y) {μ : Measure Ω}
    [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] :
    H[⟨X, Y⟩ ; μ] = H[X ; μ] + H[Y ; μ] ↔ IndepFun X Y μ := by
  sorry

/-- If `X, Y` are independent, then `H[X, Y] = H[X] + H[Y]`. -/
protected alias ⟨_, IndepFun.entropy_pair_eq_add⟩ := entropy_pair_eq_add

variable [Countable S] [Countable T]

/-- `I[X : Y] = I[Y : X]`. -/
lemma mutualInfo_comm (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    I[X : Y ; μ] = I[Y : X ; μ] := by
  sorry

/-- `H[X] - I[X : Y] = H[X | Y]`. -/
lemma entropy_sub_mutualInfo_eq_condEntropy (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω)
    [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] :
    H[X ; μ] - I[X : Y ; μ] = H[X | Y ; μ] := by
  sorry

/-- `H[Y] - I[X : Y] = H[Y | X]`. -/
lemma entropy_sub_mutualInfo_eq_condEntropy' (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω)
    [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] :
    H[Y ; μ] - I[X : Y ; μ] = H[Y | X ; μ] := by
  sorry

lemma IndepFun.condEntropy_eq_entropy {μ : Measure Ω} (h : IndepFun X Y μ)
    (hX : Measurable X) (hY : Measurable Y) [IsZeroOrProbabilityMeasure μ]
    [FiniteRange X] [FiniteRange Y] :
    H[X | Y ; μ] = H[X ; μ] := by
  sorry

variable [Countable U] [MeasurableSingletonClass U] [Nonempty S] [Nonempty T]

/-- The conditional mutual information agrees with the information of the conditional kernel.
-/
lemma condMutualInfo_eq_kernel_mutualInfo
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ] [FiniteRange Z] :
    I[X : Y | Z ; μ] = Ik[condDistrib (⟨X, Y⟩) Z μ, μ.map Z] := by
  sorry

end

section

variable [MeasurableSingletonClass S] [MeasurableSingletonClass T]

variable [Countable S] [Countable T]

/-- `I[X : Y | Z] = I[Y : X | Z]`. -/
lemma condMutualInfo_comm
    (hX : Measurable X) (hY : Measurable Y) (Z : Ω → U) (μ : Measure Ω) :
    I[X : Y | Z ; μ] = I[Y : X | Z ; μ] := by
  sorry

variable [MeasurableSingletonClass U]

/-- `I[X : Y| Z] = H[X| Z] - H[X|Y, Z]`. -/
lemma condMutualInfo_eq' [Countable U]
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    I[X : Y | Z ; μ] = H[X | Z ; μ] - H[X | ⟨Y, Z⟩ ; μ] := by
  sorry

lemma condMutualInfo_of_inj [Countable U]
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] [FiniteRange Z]
    {V : Type*} [MeasurableSpace V] [MeasurableSingletonClass V] [Countable V]
    {f : U → V} (hf : Function.Injective f) :
    I[X : Y | f ∘ Z; μ] = I[X : Y | Z; μ] := by
  sorry

lemma condMutualInfo_of_inj' {S T U S' T' U' Ω : Type*} [mΩ : MeasurableSpace Ω]
    [MeasurableSpace S] [MeasurableSingletonClass S] [Countable S]
    [MeasurableSpace T] [MeasurableSingletonClass T] [Countable T]
    [MeasurableSpace U] [MeasurableSingletonClass U] [Countable U]
    [MeasurableSpace S'] [MeasurableSingletonClass S'] [Countable S']
    [MeasurableSpace T'] [MeasurableSingletonClass T'] [Countable T']
    [MeasurableSpace U'] [MeasurableSingletonClass U'] [Countable U']
    {X : Ω → S} {Y : Ω → T} {Z : Ω → U} (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ] [FiniteRange X] [FiniteRange Y] [FiniteRange Z]
    {f : S → S'} (hf : Function.Injective f)
    {g : T → T'} (hg : Function.Injective g)
    {h : U → U'} (hh : Function.Injective h)
    : I[f ∘ X : g ∘ Y | h ∘ Z; μ] = I[X : Y | Z; μ] := by
  sorry

end

section IsProbabilityMeasure

variable [MeasurableSingletonClass S] [MeasurableSingletonClass T]

variable [Countable U] [MeasurableSingletonClass U]

variable (μ)
variable [Countable S] [Countable T]

/-- If `X, Y` are conditionally independent over `Z`, then `H[X, Y, Z] = H[X, Z] + H[Y, Z] - H[Z]`.
-/
lemma ent_of_cond_indep (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
     (h : CondIndepFun X Y Z μ) [IsZeroOrProbabilityMeasure μ]
     [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
     H[⟨X, ⟨Y, Z⟩⟩ ; μ] = H[⟨X, Z⟩; μ] + H[⟨Y, Z⟩; μ] - H[Z; μ] := by
  sorry

variable [IsZeroOrProbabilityMeasure μ]

/-- `H[X | Y] ≤ H[X]`. -/
lemma condEntropy_le_entropy (hX : Measurable X) (hY : Measurable Y) [FiniteRange X]
    [FiniteRange Y] : H[X | Y ; μ] ≤ H[X ; μ] := by
  sorry

/-- `H[X | Y, Z] ≤ H[X | Z]`. -/
lemma entropy_submodular (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    H[X | ⟨Y, Z⟩ ; μ] ≤ H[X | Z ; μ] := by
  sorry

/-- Data-processing inequality for the conditional entropy: `H[Y|f(X)] ≥ H[Y|X]`
To upgrade this to equality, see `condEntropy_of_injective'` -/
lemma condEntropy_comp_ge
    [FiniteRange X] [FiniteRange Y] (μ : Measure Ω) [IsZeroOrProbabilityMeasure μ]
    (hX : Measurable X) (hY : Measurable Y) (f : S → U) : H[Y | f ∘ X ; μ] ≥ H[Y | X; μ] := by
  sorry

/-- The submodularity inequality: `H[X, Y, Z] + H[Z] ≤ H[X, Z] + H[Y, Z]`. -/
lemma entropy_triple_add_entropy_le (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    H[⟨X, ⟨Y, Z⟩⟩ ; μ] + H[Z ; μ] ≤ H[⟨X, Z⟩ ; μ] + H[⟨Y, Z⟩ ; μ] := by
  sorry

end IsProbabilityMeasure
end mutualInfo
end ProbabilityTheory

section dataProcessing

open Function MeasureTheory Measure Real
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory

universe uΩ uS uT uU uV uW

variable {Ω : Type uΩ} {S : Type uS} {T : Type uT} {U : Type uU} {V : Type uV} {W : Type uW}
  [mΩ : MeasurableSpace Ω] [MeasurableSpace S] [MeasurableSpace T] [MeasurableSpace U]
  [MeasurableSpace V] [MeasurableSpace W]
  [Countable S] [Countable T] [Countable V] [Countable W]
  [MeasurableSingletonClass S] [MeasurableSingletonClass T] [MeasurableSingletonClass U]
  [MeasurableSingletonClass V] [MeasurableSingletonClass W]
  {X : Ω → S} {Y : Ω → T} {Z : Ω → U}
  {μ : Measure Ω}

/--
Let `X, Y`be random variables. For any function `f, g` on the range of `X`, we have
`I[f(X) : Y] ≤ I[X : Y]`.
-/
lemma mutual_comp_le [Countable U] (μ : Measure Ω) [IsProbabilityMeasure μ] (hX : Measurable X)
    (hY : Measurable Y) (f : S → U) [FiniteRange X] [FiniteRange Y] :
    I[f ∘ X : Y ; μ] ≤ I[X : Y ; μ] := by
  sorry

/-- Let `X, Y` be random variables. For any functions `f, g` on the ranges of `X, Y` respectively,
we have `I[f ∘ X : g ∘ Y ; μ] ≤ I[X : Y ; μ]`. -/
lemma mutual_comp_comp_le [Countable U] (μ : Measure Ω) [IsProbabilityMeasure μ] (hX : Measurable X)
    (hY : Measurable Y) (f : S → U) (g : T → V) (hg : Measurable g)
    [FiniteRange X] [FiniteRange Y] :
    I[f ∘ X : g ∘ Y ; μ] ≤ I[X : Y ; μ] := by
  sorry

/-- Let `X, Y, Z`. For any functions `f, g` on the ranges of `X, Y` respectively,
we have `I[f ∘ X : g ∘ Y | Z ; μ] ≤ I[X : Y | Z ; μ]`. -/
lemma condMutual_comp_comp_le (μ : Measure Ω) [IsProbabilityMeasure μ] (hX : Measurable X)
    (hY : Measurable Y) (hZ : Measurable Z) (f : S → V) (g : T → W) (hg : Measurable g)
    [FiniteRange X] [FiniteRange Y] [FiniteRange Z] :
    I[f ∘ X : g ∘ Y | Z ; μ] ≤ I[X : Y | Z ; μ] := by
  sorry

end ProbabilityTheory
end dataProcessing

section MeasureSpace_example

open ProbabilityTheory

variable {Ω S T : Type*} [MeasureSpace Ω] [IsZeroOrProbabilityMeasure (ℙ : Measure Ω)]
  [Fintype S] [Nonempty S] [MeasurableSpace S] [MeasurableSingletonClass S]
  [Fintype T] [Nonempty T] [MeasurableSpace T] [MeasurableSingletonClass T]
  {X : Ω → S} {Y : Ω → T}

/-- An example to illustrate how `MeasureSpace` can be used to suppress the ambient measure. -/
example (hX : Measurable X) (hY : Measurable Y) :
  H[⟨X, Y⟩] = H[Y] + H[X | Y] := by
  sorry

end MeasureSpace_example
