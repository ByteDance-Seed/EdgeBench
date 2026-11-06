module

public import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals

--Upstreaming status: ready

public section

open Real Set Filter MeasureTheory intervalIntegral

theorem not_integrableOn_Ioi_rpow' {a s : ℝ} (ha : 0 ≤ a) (hs : -1 ≤ s) :
    ¬IntegrableOn (fun (x : ℝ) ↦ x ^ s) (Ioi a) volume := by
  sorry
