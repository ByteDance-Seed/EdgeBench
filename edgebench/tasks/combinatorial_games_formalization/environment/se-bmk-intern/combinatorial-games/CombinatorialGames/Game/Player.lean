/-
Copyright (c) 2025 Yuyang Zhao. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yuyang Zhao
-/
module

public import Mathlib.Algebra.Ring.Defs
public import Mathlib.Data.Fintype.Defs
public import Mathlib.Logic.Small.Defs

import Mathlib.Tactic.DeriveFintype

/-!
# Type of players

This file implements the two-element type of players (`Left`, `Right`), alongside other basic
notational machinery to be used within game theory.
-/

@[expose] public section

universe u

/-! ### Players -/

/-- Either the Left or Right player. -/
@[aesop safe cases, grind cases]
inductive Player where
  /-- The Left player. -/
  | left  : Player
  /-- The Right player. -/
  | right : Player
deriving DecidableEq, Fintype, Inhabited

namespace Player

/-- Specify a function `Player → α` from its two outputs. -/
@[simp]
abbrev cases {α : Sort*} (l r : α) : Player → α
  | left => l
  | right => r

lemma apply_cases {α β : Sort*} (f : α → β) (l r : α) (p : Player) :
    f (cases l r p) = cases (f l) (f r) p := by
  sorry

@[simp]
theorem cases_inj {α : Sort*} {l₁ r₁ l₂ r₂ : α} :
    cases l₁ r₁ = cases l₂ r₂ ↔ l₁ = l₂ ∧ r₁ = r₂ := by
  sorry

theorem const_of_left_eq_right {α : Sort*} {f : Player → α} (hf : f left = f right) :
    ∀ p q, f p = f q
  := by
  sorry

theorem const_of_left_eq_right' {f : Player → Prop} (hf : f left ↔ f right) (p q) : f p ↔ f q := by
  sorry

@[simp]
protected lemma «forall» {p : Player → Prop} :
    (∀ x, p x) ↔ p left ∧ p right := by
  sorry

@[simp]
protected lemma «exists» {p : Player → Prop} :
    (∃ x, p x) ↔ p left ∨ p right := by
  sorry

instance : Neg Player where
  neg := cases right left

@[simp, grind =] lemma neg_left : -left = right := by
  sorry
@[simp, grind =] lemma neg_right : -right = left := by
  sorry
@[simp] theorem eq_neg : ∀ {p q : Player}, p = -q ↔ p ≠ q := by
  sorry
@[simp] theorem neg_eq : ∀ {p q : Player}, -p = q ↔ p ≠ q := by
  sorry
theorem ne_neg : ∀ {p q : Player}, p ≠ -q ↔ p = q := by
  sorry
theorem neg_ne : ∀ {p q : Player}, -p ≠ q ↔ p = q := by
  sorry
theorem neg_ne_self : ∀ (p : Player), -p ≠ p := by
  sorry
theorem self_ne_neg : ∀ (p : Player), p ≠ -p := by
  sorry

instance : InvolutiveNeg Player where
  neg_neg := by decide

/--
The multiplication of `Player`s is used to state the lemmas about the multiplication of
combinatorial games, such as `IGame.mulOption_mem_moves_mul`.
-/
instance : Mul Player where mul
  | left, p => p
  | right, p => -p

@[simp, grind =] lemma left_mul (p : Player) : left * p = p := by
  sorry
@[simp, grind =] lemma right_mul (p : Player) : right * p = -p := by
  sorry
@[simp, grind =] lemma mul_left : ∀ p, p * left = p := by
  sorry
@[simp, grind =] lemma mul_right : ∀ p, p * right = -p := by
  sorry
@[simp, grind =] lemma mul_self : ∀ p, p * p = left := by
  sorry

instance : HasDistribNeg Player where
  neg_mul := by decide
  mul_neg := by decide

instance : CommGroup Player where
  one := left
  inv := id
  mul_assoc := by decide
  mul_comm := by decide
  one_mul := by decide
  mul_one := by decide
  inv_mul_cancel := by decide

@[simp, grind =] lemma one_eq_left : 1 = left := by
  sorry
@[simp, grind =] lemma inv_eq_self (p : Player) : p⁻¹ = p := by
  sorry

end Player

open Player

/-! ### OfSets -/

/--
Type class for the `ofSets` operation.
Used to implement the `!{st}` and `!{s | t}` syntax.
-/
class OfSets (α : Type (u + 1)) (Valid : outParam ((Player → Set α) → Prop)) where
  /-- Construct a combinatorial game from its left and right sets. -/
  ofSets (st : Player → Set α) (h : Valid st) [Small.{u} (st left)] [Small.{u} (st right)] : α
export OfSets (ofSets)

@[inherit_doc OfSets.ofSets]
macro "!{" st:term "}'" h:term:max : term => `(OfSets.ofSets $st $h)

@[inherit_doc OfSets.ofSets]
macro "!{" s:term " | " t:term "}'" h:term:max : term => `(!{Player.cases $s $t}'$h)

/-- A tactic which attempts to automatically solve goals which appear on `OfSets`. -/
macro "of_sets_tactic" : tactic =>
  `(tactic| first
    | done
    | trivial
    | assumption
    | aesop
    | fail "failed to prove sets are valid, try to use `!{st}'h` notation instead, \
where `h` is a proof that sets are valid"
   )

@[inherit_doc OfSets.ofSets]
macro:max "!{" st:term "}" : term => `(!{$st}'(by of_sets_tactic))

@[inherit_doc OfSets.ofSets]
macro:max "!{" s:term " | " t:term "}" : term => `(!{$s | $t}'(by of_sets_tactic))

recommended_spelling "ofSets" for "!{st}'h" in [ofSets, «term!{_}'_»]
recommended_spelling "ofSets" for "!{s | t}'h" in [ofSets, «term!{_|_}'_»]
recommended_spelling "ofSets" for "!{st}" in [ofSets, «term!{_}»]
recommended_spelling "ofSets" for "!{s | t}" in [ofSets, «term!{_|_}»]

open Lean PrettyPrinter Delaborator SubExpr in
/-- Delaborates `ofSets (Player.cases s t)` to `!{s | t}` and `ofSets st` to `!{st}`. -/
@[app_delab OfSets.ofSets]
meta def delabOfSets : Delab := do
  let e ← getExpr
  guard <| e.isAppOfArity' ``OfSets.ofSets 7
  withNaryArg 3 do
    let e ← getExpr
    if e.isAppOfArity' ``Player.cases 3 then
      let s ← withNaryArg 1 delab
      let t ← withNaryArg 2 delab
      `(!{$s | $t})
    else
      let st ← delab
      `(!{$st})

theorem ofSets_eq_ofSets_cases {α} {Valid : (Player → Set α) → Prop} [OfSets α Valid]
    (st : Player → Set α) (h : Valid st) [Small (st left)] [Small (st right)] :
    !{st} = !{st left | st right}'(by convert h; aesop) := by
  sorry

end
