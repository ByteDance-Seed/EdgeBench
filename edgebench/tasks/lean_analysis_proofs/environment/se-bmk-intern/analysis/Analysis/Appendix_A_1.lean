import Mathlib.Tactic

/-!
# Analysis I, Appendix A.1: Mathematical Statements

An introduction to mathematical statements.  Showcases some basic tactics and Lean syntax.

-/

/- Example A.1.1. What the textbook calls "statements" are objects of type `Prop` in Lean.  Also,
   in Lean we tend to assign "junk" values to expressions that might normally be considered
   undefined, so discussions regarding undefined terms in the textbook should be adjusted
   accordingly. -/   
#check 2+2=4
#check 2+2=5

/-- Every well-formed statement is either true or false... -/
example (P:Prop) : (P=true) ∨ (P=false) := by
  sorry

/-- .. but not both. -/
example (P:Prop) : ¬ ((P=true) ∧ (P=false)) := by
  sorry

-- Note: `P=true` and `P=false` simplify to `P` and `¬P` respectively.

/-- To prove that a statement is true, it suffices to show that it is not false, -/
example {P:Prop} (h: P ≠ false) : P = true := by
  sorry

/-- while to show that a statement is false, it suffices to show that it is not true. -/
example {P:Prop} (h: P ≠ true) : P = false := by
  sorry

/-- This statement is true, but unlikely to be very useful. -/
example : 2 = 2 := by
  sorry

/-- This statement is also true, but not very efficient. -/
example : 4 ≤ 4 := by
  sorry

/- This is an expression, not a statement. -/
#check 2 + 3*5

/- This is a statement, not an expression. -/
#check 2 + 3*5 = 17

#check Prime (30+5)

#check 30+5 ≤ 42-7

/-- Conjunction -/
example {X Y: Prop} (hX: X) (hY: Y) : X ∧ Y := by
  sorry

example {X Y: Prop} (hXY: X ∧ Y) : X := by
  sorry

example {X Y: Prop} (hXY: X ∧ Y) : Y := by
  sorry

example {X Y: Prop} (hX: ¬ X) : ¬ (X ∧ Y) := by
  sorry

example {X Y: Prop} (hY: ¬ Y) : ¬ (X ∧ Y) := by
  sorry

example : (2+2=4) ∧ (3+3=6) := by
  sorry

/-- Disjunction -/
example {X Y: Prop} (hX: X) : X ∨ Y := by
  sorry

example {X Y: Prop} (hY: Y) : X ∨ Y := by
  sorry

example {X Y: Prop} (hX: ¬ X) (hY: ¬ Y) : ¬ (X ∨ Y) := by
  sorry

example : (2+2=4) ∨ (3+3=5) := by
  sorry

example : ¬ ((2+2=5) ∨ (3+3=5)) := by
  sorry

example : (2+2=4) ∨ (3+3=6) := by
  sorry

example : (2+2=4) ∧ (3+3=6) := by
  sorry

example : (2+2=4) ∨ (2353 + 5931 = 7284) := by
  sorry

#check Xor'

/-- Negation -/
example {X:Prop} : (¬ X = true) ↔ (X = false) := by
  sorry

example {X:Prop} : (¬ X = false) ↔ (X = true) := by
  sorry

example : ¬ (2+2=5) := by
  sorry

example : 2+2 ≠ 5 := by
  sorry

example (Jane_black_hair Jane_blue_eyes:Prop) :
  (¬ (Jane_black_hair ∧ Jane_blue_eyes)) ↔ (¬ Jane_black_hair ∨  ¬ Jane_blue_eyes) := by
  sorry

example (x:ℤ) : ¬ (Even x ∧ x ≥ 0) ↔ (Odd x ∨ x < 0) := by
  sorry

example (x:ℤ) : ¬ (x ≥ 2 ∧ x ≤ 6) ↔ (x < 2 ∨ x > 6) := by
  sorry

example (John_brown_hair John_black_hair:Prop) :
  (¬ (John_brown_hair ∨ John_black_hair)) ↔ (¬ John_brown_hair ∧  ¬ John_black_hair) := by
  sorry

example (x:ℝ) : ¬ (x ≥ 1 ∧ x ≤ -1) ↔ (x < 1 ∨ x > -1) := by
  sorry

example (x:ℤ) : ¬ (Even x ∨ Odd x) ↔ (¬ Even x ∧ ¬ Odd x) := by
  sorry

example (X:Prop) : ¬ (¬ X) ↔ X := by
  sorry

/-- If and only if (iff) -/
example {X Y: Prop} (hXY: X ↔ Y) (hX: X) : Y := by
  sorry

example {X Y: Prop} (hXY: X ↔ Y) (hY: Y) : X := by
  sorry

example {X Y: Prop} (hXY: X ↔ Y) (hX: X) : Y := by
  sorry

example {X Y: Prop} (hXY: X ↔ Y) (hY: Y) : X := by
  sorry

example {X Y: Prop} (hXY: X ↔ Y) : X=Y := by
  sorry

example (x:ℝ) : x = 3 ↔ 2 * x = 6 := by
  sorry

example : ¬ (∀ x:ℝ, x = 3 ↔ x^2 = 9) := by
  sorry

example {X Y: Prop} (hXY: X ↔ Y) (hX: ¬ X) : ¬ Y := by
  sorry

example : (2+2=5) ↔ (4+4=10) := by
  sorry

example {X Y Z:Prop} (hXY: X ↔ Y) (hXZ: X ↔ Z) : [X,Y,Z].TFAE := by
  sorry

/-- Note for the {name (full := List.TFAE.out)}`out` method that one indexes starting from 0, in
contrast to the {tactic}`tfae_have` tactic. -/
example {X Y Z:Prop} (h: [X,Y,Z].TFAE) : X ↔ Y := by
  sorry

/-- Exercise A.1.1.  Fill in the first {syntax term}`sorry` with something reasonable. -/
example {X Y:Prop} : ¬ ((X ∨ Y) ∧ ¬ (X ∧ Y)) ↔ sorry := by
  sorry

/-- Exercise A.1.2.  Fill in the first {syntax term}`sorry` with something reasonable. -/
example {X Y:Prop} : ¬ (X ↔ Y) ↔ sorry := by
  sorry

/-- Exercise A.1.3. -/
def Exercise_A_1_3 : Decidable (∀ (X Y: Prop), (X → Y) → (¬X → ¬ Y) → (X ↔ Y)) := by
  --the first line of this construction should be either `apply isTrue` or `apply isFalse`,
  --depending on whether you believe the given statement to be true or false. 
  sorry

/-- Exercise A.1.4. -/
def Exercise_A_1_4 : Decidable (∀ (X Y: Prop), (X → Y) → (¬Y → ¬ X) → (X ↔ Y)) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

/-- Exercise A.1.5. -/
def Exercise_A_1_5 : Decidable (∀ (X Y Z: Prop), (X ↔ Y) → (Y ↔ Z) → [X,Y,Z].TFAE) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

/-- Exercise A.1.6. -/
def Exercise_A_1_6 : Decidable (∀ (X Y Z: Prop), (X → Y) → (Y → Z) → (Z → X) → [X,Y,Z].TFAE) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry
