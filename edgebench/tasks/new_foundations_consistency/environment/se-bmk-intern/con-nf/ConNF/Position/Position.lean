import ConNF.Base.Params

/-!
# Position functions

In this file, we define what it means for a type to have a *position* function. Various
well-foundedness constraints in our model are enforced by position functions, which are injections
into `μ`. If we can define a relation on a type with a position function such that `r x y` only if
`pos x < pos y`, then `r` must be well-founded; this situation will occur frequently.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}]

/-- A *position* function on a type `X` is an injection from `X` into `μ`. -/
class Position (X : Type _) where
  pos : X ↪ μ

export Position (pos)

/-- If `X` has a position function, then the cardinality of `X` must be at most `#μ`. -/
theorem card_le_of_position {X : Type _} [Position X] :
    #X ≤ #μ := by
  sorry

/-- An induction (or recursion) principle for any type with a position function.
`C` is the *motive* of the recursion. If we can produce `C x` given `C y` for all `y` with position
lower than `x`, we can produce `C x` for all `x`. -/
@[elab_as_elim]
def pos_induction {X : Type _} [Position X] {C : X → Sort _} (x : X)
    (h : ∀ x, (∀ y, pos y < pos x → C y) → C x) : C x :=
  WellFounded.induction (InvImage.wf pos (inferInstanceAs <| IsWellFounded μ (· < ·)).wf) x h

end ConNF
