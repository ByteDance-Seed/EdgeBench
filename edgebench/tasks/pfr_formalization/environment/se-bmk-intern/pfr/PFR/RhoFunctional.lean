module

public import PFR.ForMathlib.ThreeVariables
public import PFR.Kullback
public import PFR.Main

/-!
# The rho functional

Definition of the rho functional and basic facts
-/

@[expose] public section

open MeasureTheory ProbabilityTheory Real Set Function Measure Filter
open scoped Pointwise ENNReal Topology
universe uG

section

variable {G : Type uG} [AddCommGroup G] [Finite G] [hGm : MeasurableSpace G]
  [DiscreteMeasurableSpace G] {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
  {X Y Z : Ω → G} {A : Finset G}

/-- The set of possible values of $D_{KL}(X \Vert U_A + T)$, where $U_A$ is uniform on $A$ and
$T$ ranges over $G$-valued random variables independent of $U_A$. We also require an absolute
continuity condition so that the KL divergence makes sense in `ℝ`.

To avoid universe issues, we express this using measures on `G`, but the equivalence with the
above point of view follows from `rhoMinus_le` below. -/
noncomputable def rhoMinusSet
    (X : Ω → G) (A : Finset G) (μ : Measure Ω) : Set ℝ :=
  {x : ℝ | ∃ (μ' : Measure G), IsProbabilityMeasure μ' ∧
    (∀ y, (μ'.prod (uniformOn A)).map (Prod.fst + Prod.snd) {y} = 0 → μ.map X {y} = 0) ∧
    x = KL[X ; μ # Prod.fst + Prod.snd ; μ'.prod (uniformOn A)]}

/-- For any $G$-valued random variable $X$, we define $\rho^-(X)$ to be the infimum of
$D_{KL}(X \Vert U_A + T)$, where $U_A$ is uniform on $A$ and $T$ ranges over $G$-valued random
variables independent of $U_A$. -/
noncomputable def rhoMinus (X : Ω → G) (A : Finset G) (μ : Measure Ω) : ℝ :=
  sInf (rhoMinusSet X A μ)

@[inherit_doc rhoMinus] notation3:max "ρ⁻[" X " ; " μ " # " A "]" => rhoMinus X A μ

@[inherit_doc rhoMinus] notation3:max "ρ⁻[" X " # " A "]" => rhoMinus X A volume

/-- For any $G$-valued random variable $X$, we define
$\rho^+(X) := \rho^-(X) + \bbH(X) - \bbH(U_A)$. -/
noncomputable def rhoPlus (X : Ω → G) (A : Finset G) (μ : Measure Ω) : ℝ :=
  ρ⁻[X ; μ # A] + H[ X ; μ ] - log (Nat.card A)

@[inherit_doc rhoPlus] notation3:max "ρ⁺[" X " ; " μ " # " A "]" => rhoPlus X A μ

@[inherit_doc rhoPlus] notation3:max "ρ⁺[" X " # " A "]" => rhoPlus X A volume

omit [MeasurableSpace G] [DiscreteMeasurableSpace G] in

omit [MeasurableSpace G] [DiscreteMeasurableSpace G] in

omit [MeasurableSpace G] [DiscreteMeasurableSpace G] in

/-- We define $\rho(X) := (\rho^+(X) + \rho^-(X))/2$. -/
noncomputable def rho (X : Ω → G) (A : Finset G) (μ : Measure Ω) : ℝ :=
  (ρ⁻[X ; μ # A] + ρ⁺[X ; μ # A]) / 2

@[inherit_doc rho] notation3:max "ρ[" X " ; " μ " # " A "]" => rho X A μ

@[inherit_doc rho] notation3:max "ρ[" X " # " A "]" => rho X A volume

/-- If $X,Y$ are independent, one has
$$ \rho^+(X+Y) \leq \rho^+(X) + \bbH[X+Y] - \bbH[X]$$ -/
lemma rhoPlus_of_sum [IsZeroOrProbabilityMeasure μ]
    (hX : Measurable X) (hY : Measurable Y) (hA : A.Nonempty) (h_indep : IndepFun X Y μ) :
    ρ⁺[X + Y ; μ # A] ≤ ρ⁺[X ; μ # A] + H[X + Y ; μ] - H[X ; μ] := by
  sorry

lemma rho_of_translate [IsZeroOrProbabilityMeasure μ]
    (hX : Measurable X) (hA : A.Nonempty) (s : G) :
    ρ[(fun ω ↦ X ω + s) ; μ # A] = ρ[X ; μ # A] := by
  sorry

-- This may not be the optimal spelling for condRho, feel free to improve
/-- We define $\rho(X|Y) := \sum_y {\bf P}(Y=y) \rho(X|Y=y)$. -/
noncomputable def condRho {S : Type*}
    (X : Ω → G) (Y : Ω → S) (A : Finset G) (μ : Measure Ω) : ℝ :=
  ∑' s, μ.real (Y ⁻¹' {s}) * ρ[X ; μ[|Y ← s] # A]

/-- Average of rhoMinus along the fibers. -/
noncomputable def condRhoMinus {S : Type*}
    (X : Ω → G) (Y : Ω → S) (A : Finset G) (μ : Measure Ω) : ℝ :=
  ∑' s, μ.real (Y ⁻¹' {s}) * ρ⁻[X ; μ[|Y ← s] # A]

/-- Average of rhoPlus along the fibers. -/
noncomputable def condRhoPlus {S : Type*}
    (X : Ω → G) (Y : Ω → S) (A : Finset G) (μ : Measure Ω) : ℝ :=
  ∑' s, μ.real (Y ⁻¹' {s}) * ρ⁺[X ; μ[|Y ← s] # A]

@[inherit_doc condRho]
notation3:max "ρ[" X " | " Z " ; " μ " # " A "]" => condRho X Z A μ

@[inherit_doc condRho]
notation3:max "ρ[" X " | " Z " # " A "]" => condRho X Z A volume

@[inherit_doc condRhoMinus]
notation3:max "ρ⁻[" X " | " Z " ; " μ " # " A "]" => condRhoMinus X Z A μ

@[inherit_doc condRhoPlus]
notation3:max "ρ⁺[" X " | " Z " ; " μ " # " A "]" => condRhoPlus X Z A μ

/-- For any $s\in G$, $\rho(X+s|Y)=\rho(X|Y)$. -/
lemma condRho_of_translate {S : Type*}
    {Y : Ω → S} (hX : Measurable X) (hA : A.Nonempty) (s : G) :
    ρ[fun ω ↦ X ω + s | Y ; μ # A] = ρ[X | Y ; μ # A] := by
  sorry

omit [Finite G] [DiscreteMeasurableSpace G] in
variable (X) in

omit [Finite G] [DiscreteMeasurableSpace G] in

omit [Finite G] [DiscreteMeasurableSpace G] in

variable [Module (ZMod 2) G]

/-- If $X,Y$ are independent, then
  $$ \rho(X | X+Y) \leq \frac{1}{2}(\rho(X)+\rho(Y) + d[X;Y]).$$ -/
lemma condRho_of_sum_le [IsProbabilityMeasure μ]
    (hX : Measurable X) (hY : Measurable Y) (hA : A.Nonempty) (h_indep : IndepFun X Y μ) :
    ρ[X | X + Y ; μ # A] ≤ (ρ[X ; μ # A] + ρ[Y ; μ # A] + d[ X ; μ # Y ; μ ]) / 2 := by
  sorry

end

section phiMinimizer

variable {G : Type uG} [AddCommGroup G] [Finite G] [hGm : MeasurableSpace G]
[DiscreteMeasurableSpace G] {Ω : Type*} [MeasureSpace Ω]
{X Y Z : Ω → G} {A : Finset G}

/-- Given $G$-valued random variables $X,Y$, define
$$ \phi[X;Y] := d[X;Y] + \eta(\rho(X) + \rho(Y))$$. -/
noncomputable def phi {Ω : Type*} [MeasurableSpace Ω]
    (X Y : Ω → G) (η : ℝ) (A : Finset G) (μ : Measure Ω) : ℝ :=
  d[ X ; μ # Y ; μ] + η * (ρ[X ; μ # A] + ρ[Y ; μ # A])

/-- Given $G$-valued random variables $X,Y$, define
$$ \phi[X;Y] := d[X;Y] + \eta(\rho(X) + \rho(Y))$$
and define a \emph{$\phi$-minimizer} to be a pair of random variables $X,Y$ which
minimizes $\phi[X;Y]$. -/
def phiMinimizes {Ω : Type*} [MeasurableSpace Ω] (X Y : Ω → G) (η : ℝ) (A : Finset G)
    (μ : Measure Ω) : Prop :=
  ∀ (Ω' : Type uG) (_ : MeasureSpace Ω') (X' Y' : Ω' → G),
    IsProbabilityMeasure (ℙ : Measure Ω') → Measurable X' → Measurable Y' →
    phi X Y η A μ ≤ phi X' Y' η A ℙ

variable {η : ℝ} (hη : 0 < η)

-- Let $(X_1, X_2)$ be a $\phi$-minimizer, and $\tilde X_1, \tilde X_2$ be independent copies
-- of $X_1,X_2$ respectively.
variable {X₁ X₂ X₁' X₂' : Ω → G} (h_min : phiMinimizes X₁ X₂ η A ℙ)
  (h₁ : IdentDistrib X₁ X₁')
  (h₂ : IdentDistrib X₂ X₂')
  (h_indep : iIndepFun ![X₁, X₂, X₁', X₂'])
  (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₁' : Measurable X₁') (hX₂' : Measurable X₂')

local notation3 "I₁" => I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂']
local notation3 "I₂" => I[X₁ + X₂ : X₁ + X₁' | X₁ + X₂ + X₁' + X₂']
/-- `k := d[X₁ # X₂]`, the Ruzsa distance `rdist` between X₁ and X₂. -/
local notation3 "k" => d[X₁ # X₂]

variable [IsProbabilityMeasure (ℙ : Measure Ω)]

variable [Module (ZMod 2) G]

/- *****************************************
First estimate
********************************************* -/

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min hη in
/-- $I_1\le 2\eta d[X_1;X_2]$ -/
lemma I_one_le (hA : A.Nonempty) : I₁ ≤ 2 * η * d[ X₁ # X₂ ] := by
  sorry

/- *****************************************
Second estimate
********************************************* -/

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep in
lemma I_two_aux :
    d[X₁ # X₁] + d[X₂ # X₂] = d[X₁ + X₂' # X₂ + X₁'] + d[X₁ | X₁ + X₂' # X₂ | X₂ + X₁'] + I₂ := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep in
/-- $d[X_1;X_1]+d[X_2;X_2]= 2d[X_1;X_2]+(I_2-I_1)$. -/
lemma rdist_add_rdist_eq :
    d[ X₁ # X₁ ] + d[ X₂ # X₂ ] = 2 * k + (I₂ - I₁) := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep in
lemma I_two_aux' :
    2 * k = d[X₁ + X₁' # X₂ + X₂'] + d[X₁ | X₁ + X₁' # X₂ | X₂ + X₂'] + I₂ := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min hη in
/-- $I_2\le 2\eta d[X_1;X_2] + \frac{\eta}{1-\eta}(2\eta d[X_1;X_2]-I_1)$. -/
lemma I_two_le (hA : A.Nonempty) (h'η : η < 1) :
    I₂ ≤ 2 * η * k + (η / (1 - η)) * (2 * η * k - I₁) := by
  sorry

/- ****************************************
End Game
******************************************* -/

include h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- If $G$-valued random variables $T_1,T_2,T_3$ satisfy $T_1+T_2+T_3=0$, then
$$d[X_1;X_2]\le 3\bbI[T_1:T_2\mid T_3] + (2\bbH[T_3]-\bbH[T_1]-\bbH[T_2])
  + \eta(\rho(T_1|T_3)+\rho(T_2|T_3)-\rho(X_1)-\rho(X_2)).$$ -/
lemma dist_le_of_sum_zero {Ω' : Type*} [MeasurableSpace Ω'] {μ : Measure Ω'}
    [IsProbabilityMeasure μ] {T₁ T₂ T₃ : Ω' → G}
    (hsum : T₁ + T₂ + T₃ = 0) (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃) :
    k ≤ 3 * I[T₁ : T₂ ; μ] + (2 * H[T₃ ; μ] - H[T₁ ; μ] - H[T₂ ; μ])
      + η * (ρ[T₁ | T₃ ; μ # A] + ρ[T₂ | T₃ ; μ #  A] - ρ[X₁ # A] - ρ[X₂ # A]) := by
  sorry

include h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- If $G$-valued random variables $T_1,T_2,T_3$ satisfy $T_1+T_2+T_3=0$, then
$$d[X_1;X_2]\le 3\bbI[T_1:T_2\mid T_3] + (2\bbH[T_3]-\bbH[T_1]-\bbH[T_2])+ \eta(\rho(T_1|T_3)
  +\rho(T_2|T_3)-\rho(X_1)-\rho(X_2)).$$ -/
lemma dist_le_of_sum_zero_cond {Ω' : Type*} [MeasureSpace Ω']
    [IsProbabilityMeasure (ℙ : Measure Ω')] {T₁ T₂ T₃ S : Ω' → G}
    (hsum : T₁ + T₂ + T₃ = 0) (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃)
    (hS : Measurable S) :
    k ≤ 3 * I[T₁ : T₂ | S] + (2 * H[T₃ | S] - H[T₁ | S] - H[T₂ | S])
      + η * (ρ[T₁ | ⟨T₃, S⟩ # A] + ρ[T₂ | ⟨T₃, S⟩ #  A] - ρ[X₁ # A] - ρ[X₂ # A]) := by
  sorry

include h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- If $G$-valued random variables $T_1,T_2,T_3$ satisfy $T_1+T_2+T_3=0$, then
  $$d[X_1;X_2] \leq \sum_{1 \leq i < j \leq 3} \bbI[T_i:T_j]
  + \frac{\eta}{3} \sum_{1 \leq i < j \leq 3} (\rho(T_i|T_j) + \rho(T_j|T_i) -\rho(X_1)-\rho(X_2))$$
-/
lemma dist_le_of_sum_zero' {Ω' : Type*} [MeasureSpace Ω']
    [IsProbabilityMeasure (ℙ : Measure Ω')] {T₁ T₂ T₃ : Ω' → G} (hsum : T₁ + T₂ + T₃ = 0)
    (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃) :
    k ≤ I[T₁ : T₂] + I[T₁ : T₃] + I[T₂ : T₃]
      + (η / 3) * ((ρ[T₁ | T₂ # A] + ρ[T₂ | T₁ # A] - ρ[X₁ # A] - ρ[X₂ # A])
                 + (ρ[T₁ | T₃ # A] + ρ[T₃ | T₁ # A] - ρ[X₁ # A] - ρ[X₂ # A])
                 + (ρ[T₂ | T₃ # A] + ρ[T₃ | T₂ # A] - ρ[X₁ # A] - ρ[X₂ # A])) := by
  sorry

include h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- If $G$-valued random variables $T_1,T_2,T_3$ satisfy $T_1+T_2+T_3=0$, then
  $$d[X_1;X_2] \leq \sum_{1 \leq i < j \leq 3} \bbI[T_i:T_j]
  + \frac{\eta}{3} \sum_{1 \leq i < j \leq 3} (\rho(T_i|T_j) + \rho(T_j|T_i) -\rho(X_1)-\rho(X_2))$$
-/
lemma dist_le_of_sum_zero_cond' {Ω' : Type*} [MeasureSpace Ω']
    [IsProbabilityMeasure (ℙ : Measure Ω')] {T₁ T₂ T₃ : Ω' → G} (S : Ω' → G)
    (hsum : T₁ + T₂ + T₃ = 0)
    (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃) (hS : Measurable S) :
    k ≤ I[T₁ : T₂ | S] + I[T₁ : T₃| S] + I[T₂ : T₃ | S]
      + (η / 3) * ((ρ[T₁ | ⟨T₂, S⟩ # A] + ρ[T₂ | ⟨T₁, S⟩ # A] - ρ[X₁ # A] - ρ[X₂ # A])
                 + (ρ[T₁ | ⟨T₃, S⟩ # A] + ρ[T₃ | ⟨T₁, S⟩ # A] - ρ[X₁ # A] - ρ[X₂ # A])
                 + (ρ[T₂ | ⟨T₃, S⟩ # A] + ρ[T₃ | ⟨T₂, S⟩ # A] - ρ[X₁ # A] - ρ[X₂ # A])) := by
  sorry

lemma new_gen_ineq_aux1 {Y₁ Y₂ Y₃ Y₄ : Ω → G}
    (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (hY₃ : Measurable Y₃) (hY₄ : Measurable Y₄)
    (h_indep : iIndepFun ![Y₁, Y₂, Y₃, Y₄]) (hA : A.Nonempty) :
    ρ[Y₁ + Y₂ | ⟨Y₁ + Y₃, Y₁ + Y₂ + Y₃ + Y₄⟩ # A] ≤
      (ρ[Y₁ # A] + ρ[Y₂ # A] + ρ[Y₃ # A] + ρ[Y₄ # A]) / 4
        + (d[Y₁ # Y₂] + d[Y₃ # Y₄]) / 4 + (d[Y₁ + Y₂ # Y₃ + Y₄]
          + I[Y₁ + Y₂ : Y₁ + Y₃ | Y₁ + Y₂ + Y₃ + Y₄]) / 2 := by
  sorry

lemma new_gen_ineq_aux2 {Y₁ Y₂ Y₃ Y₄ : Ω → G}
    (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (hY₃ : Measurable Y₃) (hY₄ : Measurable Y₄)
    (h_indep : iIndepFun ![Y₁, Y₂, Y₃, Y₄]) (hA : A.Nonempty) :
    ρ[Y₁ + Y₂ | ⟨Y₁ + Y₃, Y₁ + Y₂ + Y₃ + Y₄⟩ # A] ≤
       (ρ[Y₁ # A] + ρ[Y₂ # A] + ρ[Y₃ # A] + ρ[Y₄ # A]) / 4
        + (d[Y₁ # Y₃] + d[Y₂ # Y₄]) / 4 + d[Y₁ | Y₁ + Y₃ # Y₂ | Y₂ + Y₄] / 2 := by
  sorry

lemma new_gen_ineq {Y₁ Y₂ Y₃ Y₄ : Ω → G}
    (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (hY₃ : Measurable Y₃) (hY₄ : Measurable Y₄)
    (h_indep : iIndepFun ![Y₁, Y₂, Y₃, Y₄]) (hA : A.Nonempty) :
    ρ[Y₁ + Y₂ | ⟨Y₁ + Y₃, Y₁ + Y₂ + Y₃ + Y₄⟩ # A] ≤
      (ρ[Y₁ # A] + ρ[Y₂ # A] + ρ[Y₃ # A] + ρ[Y₄ # A]) / 4
        + (d[Y₁ # Y₂] + d[Y₃ # Y₄] + d[Y₁ # Y₃] + d[Y₂ # Y₄]) / 8 + (d[Y₁ + Y₂ # Y₃ + Y₄]
          + I[Y₁ + Y₂ : Y₁ + Y₃ | Y₁ + Y₂ + Y₃ + Y₄] + d[Y₁ | Y₁ + Y₃ # Y₂ | Y₂ + Y₄]) / 4 := by
  sorry

/-- For independent random variables $Y_1,Y_2,Y_3,Y_4$ over $G$, define
$S:=Y_1+Y_2+Y_3+Y_4$, $T_1:=Y_1+Y_2$, $T_2:=Y_1+Y_3$. Then
  $$\rho(T_1|T_2,S)+\rho(T_2|T_1,S) - \frac{1}{2}\sum_{i} \rho(Y_i)
    \le \frac{1}{2}(d[Y_1;Y_2]+d[Y_3;Y_4]+d[Y_1;Y_3]+d[Y_2;Y_4]).$$
-/
lemma condRho_sum_le {Y₁ Y₂ Y₃ Y₄ : Ω → G}
    (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (hY₃ : Measurable Y₃) (hY₄ : Measurable Y₄)
    (h_indep : iIndepFun ![Y₁, Y₂, Y₃, Y₄]) (hA : A.Nonempty) :
    ρ[Y₁ + Y₂ | ⟨Y₁ + Y₃, Y₁ + Y₂ + Y₃ + Y₄⟩ # A] + ρ[Y₁ + Y₃ | ⟨Y₁ + Y₂, Y₁ + Y₂ + Y₃ + Y₄⟩ # A] -
      (ρ[Y₁ # A] + ρ[Y₂ # A] + ρ[Y₃ # A] + ρ[Y₄ # A]) / 2 ≤
        (d[Y₁ # Y₂] + d[Y₃ # Y₄] + d[Y₁ # Y₃] + d[Y₂ # Y₄]) / 2 := by
  sorry

/-- For independent random variables $Y_1,Y_2,Y_3,Y_4$ over $G$, define
$T_1:=Y_1+Y_2, T_2:=Y_1+Y_3, T_3:=Y_2+Y_3$ and $S:=Y_1+Y_2+Y_3+Y_4$. Then
  $$\sum_{1 \leq i < j \leq 3} (\rho(T_i|T_j,S) + \rho(T_j|T_i,S)
    - \frac{1}{2}\sum_{i} \rho(Y_i))\le \sum_{1\leq i < j \leq 4}d[Y_i;Y_j]$$ -/
lemma condRho_sum_le' {Y₁ Y₂ Y₃ Y₄ : Ω → G}
      (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (hY₃ : Measurable Y₃) (hY₄ : Measurable Y₄)
      (h_indep : iIndepFun ![Y₁, Y₂, Y₃, Y₄]) (hA : A.Nonempty) :
    let S := Y₁ + Y₂ + Y₃ + Y₄
    let T₁ := Y₁ + Y₂
    let T₂ := Y₁ + Y₃
    let T₃ := Y₂ + Y₃
    ρ[T₁ | ⟨T₂, S⟩ # A] + ρ[T₂ | ⟨T₁, S⟩ # A] + ρ[T₁ | ⟨T₃, S⟩ # A] + ρ[T₃ | ⟨T₁, S⟩ # A]
      + ρ[T₂ | ⟨T₃, S⟩ # A] + ρ[T₃ | ⟨T₂, S⟩ # A]
      - 3 * (ρ[Y₁ # A] + ρ[Y₂ # A] + ρ[Y₃ # A] + ρ[Y₄ # A]) / 2 ≤
    d[Y₁ # Y₂] + d[Y₁ # Y₃] + d[Y₁ # Y₄] + d[Y₂ # Y₃] + d[Y₂ # Y₄] + d[Y₃ # Y₄] := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min hη in
/-- If $X_1, X_2$ is a $\phi$-minimizer, then $d[X_1;X_2] = 0$. -/
lemma dist_of_min_eq_zero' (hA : A.Nonempty) (hη' : η < 1 / 8) : d[X₁ # X₂] = 0 := by
  sorry

include hX₁ hX₂ h_min hη in
theorem dist_of_min_eq_zero (hA : A.Nonempty) (hη' : η < 1 / 8) : d[X₁ # X₂] = 0 := by
  sorry

open Filter
open scoped Topology

/-- For `η ≤ 1/8`, there exist phi-minimizers `X₁, X₂` at zero Rusza distance. For `η < 1/8`,
all minimizers are fine, by `dist_of_min_eq_zero`. For `η = 1/8`, we use a limit of
minimizers for `η < 1/8`, which exists by compactness. -/
lemma phiMinimizer_exists_rdist_eq_zero (hA : A.Nonempty) :
    ∃ (Ω : Type uG) (_ : MeasureSpace Ω) (X₁ : Ω → G) (X₂ : Ω → G),
      Measurable X₁ ∧ Measurable X₂ ∧ IsProbabilityMeasure (ℙ : Measure Ω)
      ∧ phiMinimizes X₁ X₂ (1/8 : ℝ) A ℙ ∧ d[X₁ # X₂] = 0 := by
  sorry

end phiMinimizer

section PFR

variable {G : Type uG} [AddCommGroup G] [Finite G] [Module (ZMod 2) G]
{Ω : Type uG} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)] {A : Finset G}

/-- For any random variables $Y_1,Y_2$, there exist a subgroup $H$ such that
  $$ 2\rho(U_H) \leq \rho(Y_1) + \rho(Y_2) + 8 d[Y_1;Y_2].$$ -/
theorem rho_PFR_conjecture [MeasurableSpace G] [DiscreteMeasurableSpace G]
    (Y₁ Y₂ : Ω → G) (hY₁ : Measurable Y₁) (hY₂ : Measurable Y₂) (A : Finset G) (hA : A.Nonempty) :
    ∃ (H : Submodule (ZMod 2) G) (Ω' : Type uG) (mΩ' : MeasureSpace Ω') (U : Ω' → G),
    IsProbabilityMeasure (ℙ : Measure Ω') ∧ Measurable U ∧
    IsUniform H U ∧ 2 * ρ[U # A] ≤ ρ[Y₁ # A] + ρ[Y₂ # A] + 8 * d[Y₁ # Y₂] := by
  sorry

/-- If $|A+A| \leq K|A|$, then there exists a subgroup $H$ and $t\in G$ such that
$|A \cap (H+t)| \geq K^{-4} \sqrt{|A||V|}$, and $|H|/|A|\in[K^{-8},K^8]$. -/
lemma better_PFR_conjecture_aux0 {A : Set G} (h₀A : A.Nonempty) {K : ℝ}
    (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (t : G),
      K ^ (-4 : ℤ) * Nat.card A ^ (1 / 2 : ℝ) * (H : Set G).ncard ^ (1 / 2 : ℝ)
        ≤ Nat.card ↑(A ∩ (H + {t})) ∧
      Nat.card A ≤ K ^ 8 * (H : Set G).ncard ∧ (H : Set G).ncard ≤ K ^ 8 * Nat.card A := by
  sorry

/-- Auxiliary statement towards the polynomial Freiman-Ruzsa (PFR) conjecture: if $A$ is a subset of
an elementary abelian 2-group of doubling constant at most $K$, then there exists a subgroup $H$
such that $A$ can be covered by at most $K^5 |A|^{1/2} / |H|^{1/2}$ cosets of $H$, and $H$ has
the same cardinality as $A$ up to a multiplicative factor $K^8$. -/
lemma better_PFR_conjecture_aux {A : Set G} (h₀A : A.Nonempty) {K : ℝ}
    (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c ≤ K ^ 5 * Nat.card A ^ (1 / 2 : ℝ) * ((H : Set G).ncard : ℝ) ^ (-1 / 2 : ℝ)
      ∧ (H : Set G).ncard ≤ K ^ 8 * Nat.card A
      ∧ Nat.card A ≤ K ^ 8 * (H : Set G).ncard ∧ A ⊆ c + H := by
  sorry

/-- If $A \subset {\bf F}_2^n$ is finite non-empty with $|A+A| \leq K|A|$, then there exists a
subgroup $H$ of ${\bf F}_2^n$ with $|H| \leq |A|$ such that $A$ can be covered by at most $2K^9$
translates of $H$. -/
lemma better_PFR_conjecture {A : Set G} (h₀A : A.Nonempty) {K : ℝ}
    (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 9 ∧ (H : Set G).ncard ≤ Nat.card A ∧ A ⊆ c + H := by
  sorry

/-- Corollary of `better_PFR_conjecture` in which the ambient group is not required to be finite
(but) then $H$ and $c$ are finite. -/
theorem better_PFR_conjecture' {G : Type*} [AddCommGroup G] [Module (ZMod 2) G]
    {A : Set G} {K : ℝ} (h₀A : A.Nonempty) (Afin : A.Finite)
    (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G), c.Finite ∧ (H : Set G).Finite ∧
      Nat.card c < 2 * K ^ 9 ∧ (H : Set G).ncard ≤ Nat.card A ∧ A ⊆ c + H := by
  sorry

end PFR
