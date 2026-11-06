import ConNF.Base.TypeIndex

/-!
# Litters

In this file, we define litters, which are the parts of an indexed partition of the base type of our
model. Each litter is indexed by an element of `μ`, as well as some parameters `β` and `γ` used for
defining the `fuzz` map later.
-/

universe u

open Cardinal WithBot

namespace ConNF

variable [Params.{u}]

/-- The type indexing the partition of the base type of our model.
The field `ν : μ` is an index that enforces that there are `μ` litters.
The fields `β` and `γ` are used in the definition of the `fuzz` map, which is an injection
into the type of litters. -/
structure Litter where
  ν : μ
  β : TypeIndex
  γ : Λ
  β_ne_γ : β ≠ γ

/-- The type of litters is nonempty. -/
instance : Nonempty Litter :=
  ⟨⟨Classical.arbitrary μ, ⊥, Classical.arbitrary Λ, bot_ne_coe⟩⟩

/-- Strips away the name of the type of litters, converting it into a combination of types
well-known to mathlib. -/
def litterEquiv : Litter ≃ { a : μ × TypeIndex × Λ // a.2.1 ≠ a.2.2 }
    where
  toFun L := ⟨⟨L.ν, L.β, L.γ⟩, L.β_ne_γ⟩
  invFun L := ⟨L.val.1, L.val.2.1, L.val.2.2, L.prop⟩
  left_inv _ := rfl
  right_inv _ := rfl

/-- There are precisely `μ` litters. -/
@[simp]
theorem card_litter : #Litter = #μ := by
  sorry

/-!
## Notation typeclasses

We will use Lean's typeclasses to implement some custom notation, namely the superscripts
`ᴸ`, `ᴬ`, `ᴺ`, `ᵁ`, which will be used for converting between various common types
(such as litters). The meanings of the notations are type-dependent.
-/

/-- Typeclass for the `ᴸ` notation. Used for converting to litters, or extracting the
"litter part" of an object. -/
class SuperL (X : Type _) (Y : outParam <| Type _) where
  superL : X → Y

/-- Typeclass for the `ᴬ` notation. Used for converting to atoms, or extracting the
"atom part" of an object. -/
class SuperA (X : Type _) (Y : outParam <| Type _) where
  superA : X → Y

/-- Typeclass for the `ᴺ` notation. Used for converting to near-litters, or extracting the
"near-litter part" of an object. -/
class SuperN (X : Type _) (Y : outParam <| Type _) where
  superN : X → Y

/-- Typeclass for the `ᵁ` notation. Used for forgetful operations. -/
class SuperU (X : Type _) (Y : outParam <| Type _) where
  superU : X → Y

postfix:max "ᴸ" => SuperL.superL
postfix:max "ᴬ" => SuperA.superA
postfix:max "ᴺ" => SuperN.superN
postfix:max "ᵁ" => SuperU.superU

end ConNF
