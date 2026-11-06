module

public import Mathlib.Algebra.Module.ZMod
public import PFR.TauFunctional
public import PFR.HundredPercent
public import PFR.Endgame

/-!
# Entropic version of polynomial Freiman-Ruzsa conjecture

Here we prove the entropic version of the polynomial Freiman-Ruzsa conjecture.

## Main results

* `entropic_PFR_conjecture`: For two $G$-valued random variables $X^0_1, X^0_2$, there is some
  subgroup $H \leq G$ such that $d[X^0_1;U_H] + d[X^0_2;U_H] \le 11 d[X^0_1;X^0_2]$.

-/

public section

open MeasureTheory ProbabilityTheory
universe uG

variable {Ω₀₁ Ω₀₂ : Type*} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]

variable {Ω Ω' : Type*} [mΩ : MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]
  [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]

variable {G : Type uG} [AddCommGroup G] [Module (ZMod 2) G] [Finite G] [MeasurableSpace G]
  [MeasurableSingletonClass G]
variable (p : refPackage Ω₀₁ Ω₀₂ G) {X₁ : Ω → G} {X₂ : Ω → G} (hX₁ : Measurable X₁)
  (hX₂ : Measurable X₂)

include hX₁ hX₂ in
/-- If $d[X_1;X_2] > 0$ then there are $G$-valued random variables $X'_1, X'_2$ such that
$\tau[X'_1;X'_2] < \tau[X_1;X_2]$. Phrased in the contrapositive form for convenience of proof. -/
theorem tau_strictly_decreases (h_min : tau_minimizes p X₁ X₂) (hpη : p.η = 1 / 9) :
    d[X₁ # X₂] = 0 := by
  sorry

/-- `entropic_PFR_conjecture`: For two $G$-valued random variables $X^0_1, X^0_2$, there is some
    subgroup $H \leq G$ such that $d[X^0_1;U_H] + d[X^0_2;U_H] \le 11 d[X^0_1;X^0_2]$. -/
theorem entropic_PFR_conjecture (hpη : p.η = 1 / 9) :
    ∃ H : Submodule (ZMod 2) G, ∃ Ω : Type uG, ∃ mΩ : MeasureSpace Ω, ∃ U : Ω → G,
    IsProbabilityMeasure (ℙ : Measure Ω) ∧ Measurable U ∧
    IsUniform H U ∧ d[p.X₀₁ # U] + d[p.X₀₂ # U] ≤ 11 * d[p.X₀₁ # p.X₀₂] := by
  sorry

theorem entropic_PFR_conjecture' (hpη : p.η = 1 / 9) :
    ∃ H : Submodule (ZMod 2) G, ∃ Ω : Type uG, ∃ mΩ : MeasureSpace Ω, ∃ U : Ω → G,
    IsUniform H U ∧ d[p.X₀₁ # U] ≤ 6 * d[p.X₀₁ # p.X₀₂] ∧
      d[p.X₀₂ # U] ≤ 6 * d[p.X₀₁ # p.X₀₂] := by
  sorry
