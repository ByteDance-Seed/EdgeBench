import Mathlib.Tactic

/-!
# Analysis I, Appendix A.5: Nested quantifiers

Some examples of nested quantifiers in Lean

-/

example : ∀ x > (0:ℝ), ∃ y > 0, y^2 = x := by
  sorry

namespace SwanExample

variable (Swans:Type)
variable (isBlack : Swans → Prop)

example : (¬ ∀ s:Swans, isBlack s) = (∃ s:Swans, ¬ isBlack s) := by
  sorry

example : (¬ ∃ s:Swans, isBlack s) = (∀ s:Swans, ¬ isBlack s) := by
  sorry

end SwanExample

example : (¬ ∀ x, (0 < x ∧ x < Real.pi/2) → Real.cos x ≥ 0) = (∃ x, (0 < x ∧ x < Real.pi/2) ∧ Real.cos x < 0) := by
  sorry

example : (¬ ∃ x:ℝ, x^2 + x + 1 = 0) = (∀ x:ℝ, x^2 + x + 1 ≠ 0) := by
  sorry

theorem square_expand : ∀ (x:ℝ), (x + 1)^2 = x^2 + 2 * x + 1 := by
  sorry

example : (Real.pi+1)^2 = Real.pi^2 + 2 * Real.pi + 1 := by
  sorry  -- one can also use `exact square_expand _`

example : ∀ (y:ℝ), (Real.cos y + 1)^2 = Real.cos y^2 + 2 * Real.cos y + 1 := by
  sorry

theorem solve_quadratic : ∃ (x:ℝ), x^2 + 2 * x - 8 = 0 := by
  sorry

/- The following proof will not typecheck.

example : Real.pi^2 + 2 * Real.pi - 8 = 0 := by
  apply solve_quadratic

-/

namespace Remark_A_5_1

variable (Man : Type)
variable (Mortal : Man → Prop)

example
  (premise : ∀ m : Man, Mortal m)
  (Socrates : Man) :
  Mortal Socrates := by
  sorry  -- `exact premise Socrates` would also work

end Remark_A_5_1

example :
  (∀ a:ℝ, ∀ b:ℝ, (a+b)^2 = a^2 + 2*a*b + b^2)
  = (∀ b:ℝ, ∀ a:ℝ, (a+b)^2 = a^2 + 2*a*b + b^2)
  := by
  sorry

example :
  (∃ a:ℝ, ∃ b:ℝ, a^2 + b^2 = 0)
  = (∃ b:ℝ, ∃ a:ℝ, a^2 + b^2 = 0)
  := by
  sorry

example : ∀ n:ℤ, ∃ m:ℤ, m > n := by
  sorry

example : ¬ ∃ m:ℤ, ∀ n:ℤ, m > n := by
  sorry

/-- Exercise A.5.1 -/
def Exercise_A_5_1a : Decidable (∀ x > (0:ℝ), ∀ y > (0:ℝ), y^2 = x ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

def Exercise_A_5_1b : Decidable (∃ x > (0:ℝ), ∀ y > (0:ℝ), y^2 = x ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

def Exercise_A_5_1c : Decidable (∃ x > (0:ℝ), ∃ y > (0:ℝ), y^2 = x ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

def Exercise_A_5_1d : Decidable (∀ y > (0:ℝ), ∃ x > (0:ℝ), y^2 = x ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

def Exercise_A_5_1e : Decidable (∃ y > (0:ℝ), ∀ x > (0:ℝ), y^2 = x ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry
