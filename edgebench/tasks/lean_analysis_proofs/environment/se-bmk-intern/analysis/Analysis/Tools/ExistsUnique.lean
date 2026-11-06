import Mathlib.Tactic

/-!
# API for ExistsUnique

Here we review some of the API provided for `ExistsUnique` in Mathlib, and provide some additional tools.  (Some of these might be suitable for upstreaming to Mathlib.)

-/

#check existsUnique_of_exists_of_unique
#check ExistsUnique.exists
#check ExistsUnique.unique
#check ExistsUnique.intro

/-- This implements the axiom of unique choice. -/
noncomputable def ExistsUnique.choose {α: Sort*} {p: α → Prop} (h : ∃! x, p x) : α := h.exists.choose

theorem ExistsUnique.choose_spec {α: Sort*} {p: α → Prop} (h : ∃! x, p x) :
  p h.choose := by
  sorry

theorem ExistsUnique.choose_eq {α: Sort*} {p: α → Prop} (h : ∃! x, p x) {x : α} (hx : p x) :
  h.choose = x := by
  sorry

theorem ExistsUnique.choose_eq_choose {α: Sort*} {p: α → Prop} (h : ∃! x, p x) : Exists.choose h = h.choose := by
  sorry

/-- An alternate form of the axiom of unique choice.   -/
noncomputable def Subsingleton.choose {α: Sort*} [Subsingleton α] [hn: Nonempty α] : α := hn.some

theorem Subsingleton.choose_spec {α: Sort*} [hs: Subsingleton α] [Nonempty α] (x:α) : x = hs.choose := by
  sorry

/-- The equivalence between `ExistsUnique` and `Subsingleton`/`Nonempty` does not require choice. -/
theorem ExistsUnique.iff_subsingleton_nonempty  {α: Sort*} {p: α → Prop} :
  (∃! x, p x) ↔ (Subsingleton {x // p x} ∧ Nonempty {x // p x}) := by
  sorry

#print axioms ExistsUnique.iff_subsingleton_nonempty 
