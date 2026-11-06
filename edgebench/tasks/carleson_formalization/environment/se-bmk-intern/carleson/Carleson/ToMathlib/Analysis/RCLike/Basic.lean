module

public import Mathlib.Analysis.RCLike.Basic

--Upstreaming status: ready

public section

theorem RCLike.norm_I {K : Type*} [RCLike K] :
    ‖(RCLike.I : K)‖ = if RCLike.I ≠ (0 : K) then 1 else 0 := by
  sorry
