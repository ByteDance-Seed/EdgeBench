import ConNF.Position.Position

/-!
# Injective functions from denied sets

In this file, we construct a mechanism for creating injective functions satisfying particular
constraints.

## Main declarations

* `ConNF.funOfDeny`: An injective function satisfying particular requirements.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

def initialEquiv {X : Type _} : X ≃ (#X).ord.toType := by
  apply Nonempty.some
  rw [← Cardinal.eq]
  rw [mk_toType, card_ord]

/-- Endow a type `X` with a well-order of smallest possible order type. -/
def initialWellOrder (X : Type _) : LtWellOrder X :=
  Equiv.ltWellOrder initialEquiv

def chooseOfCardLt {X : Type _} {s : Set X} (h : #s < #X) : X :=
  (compl_nonempty_of_mk_lt h).choose

variable [Params.{u}]

theorem gtOfDeny_aux {X : Type _} (h₁ : #X ≤ #μ) (deny : X → Set μ)
    (h₂ : ∀ x, #(deny x) < (#μ).ord.cof)
    (x : X) (ih : letI := initialWellOrder X; (y : X) → y < x → μ) :
    #(({ν | ∃ y h, ν = ih y h}) ∪ {ν | ∃ ξ ∈ deny x, ν ≤ ξ} : Set μ) < #μ := by
  sorry

def gtOfDeny {X : Type _} (h₁ : #X ≤ #μ) (deny : X → Set μ) (h₂ : ∀ x, #(deny x) < (#μ).ord.cof)
    (x : X) (ih : letI := initialWellOrder X; (y : X) → y < x → μ) : μ :=
  chooseOfCardLt (gtOfDeny_aux h₁ deny h₂ x ih)

def funOfDeny {X : Type _} (h₁ : #X ≤ #μ) (deny : X → Set μ) (h₂ : ∀ x, #(deny x) < (#μ).ord.cof) :
    X → μ :=
  letI := initialWellOrder X
  (inferInstanceAs (IsWellFounded X (· < ·))).wf.fix (C := λ _ ↦ μ)
    (λ x ih ↦ gtOfDeny h₁ deny h₂ x ih)

theorem funOfDeny_injective {X : Type _} (h₁ : #X ≤ #μ) (deny : X → Set μ)
    (h₂ : ∀ x, #(deny x) < (#μ).ord.cof) :
    Function.Injective (funOfDeny h₁ deny h₂) := by
  sorry

end ConNF
