import Mathlib.Tactic

/-!
# Analysis I, Appendix A.2: Implication

An introduction to implications.  Showcases some basic tactics and Lean syntax.

-/

example {X Y: Prop} (hX: X) : (X → Y) ↔ Y := by
  sorry

example {X Y: Prop} (hX: ¬X) : X → Y := by
  sorry

example {X Y: Prop} (hXY: X → Y) (hX: X) : Y := by
  sorry

example {X Y: Prop} (hXY: X → Y) (hX: X) : Y := by
  sorry

example {X Y: Prop} (hXY: X → Y) (hY: ¬ Y) : ¬ X := by
  sorry

theorem example_A_2_1 (x:ℤ) : x = 2 → x^2 = 4 := by
  sorry

example : (2:ℤ) = 2 → (2:ℤ)^2 = 4 := by
  sorry

example : (3:ℤ) = 2 → (3:ℤ)^2 = 4 := by
  sorry

example : (-2:ℤ) = 2 → (-2:ℤ)^2 = 4 := by
  sorry

#check _root_.not_imp

example : ¬ ((2+2=4) → (4+4)=2) := by
  sorry

example {X Y: Prop} : (X → Y) ↔ (Y ≥ X) := by
  sorry

example {X Y: Prop} : (X → Y) ↔ ((¬X) ≥ ¬Y) := by
  sorry

example {John_left_at_five John_here_now:Prop}
  (h1: John_left_at_five → John_here_now)
  (h2: ¬ John_here_now) :
  ¬ John_left_at_five := by
  sorry

example {Washington_capital_US:Prop} (h: Washington_capital_US) : (1+1=2) → Washington_capital_US := by
  sorry

example {NYC_capital_US:Prop} : (2+2=3) → NYC_capital_US := by
  sorry

/-- Proposition A.2.2 -/
example : ((2+2:ℤ)=5) → (4=(10-4:ℤ)) := by
  sorry

/-- Theorem A.2.4 -/
theorem theorem_A_2_4 (n:ℤ) : Even (n * (n+1)) := by
  sorry

/-- Corollary A.2.5 -/
example :
  let n:ℤ := (253+142)*123-(423+198)^342+538-213
  Even (n * (n+1)) := by
  sorry

example : ∀ x:ℝ, x = 2 → x^2 = 4 := by
  sorry

example : ¬ ∀ x:ℝ, x^2 = 4 → x = 2 := by
  sorry

example {X Y : Prop} : (X ↔ Y) = ((X → Y) ∧ (Y → X)) := by
  sorry

example (x:ℝ) : x = 2 ↔ 2*x = 4 := by
  sorry

example {X Y :Prop} : (X ↔ Y) = (X = Y) := by
  sorry

example : (3 = 2) → (6 = 4) := by
  sorry

example : ∃ (X Y:Prop), (X → Y) ≠ (Y → X) := by
  sorry

theorem imp_contrapositive (x:ℝ) : (x^2 ≠ 4) → (x ≠ 2) := by
  sorry

/-- Proposition A.2.6 -/
example {x:ℝ} (h:x>0) (hsin: Real.sin x = 1) : x ≥ Real.pi / 2 := by
  sorry
