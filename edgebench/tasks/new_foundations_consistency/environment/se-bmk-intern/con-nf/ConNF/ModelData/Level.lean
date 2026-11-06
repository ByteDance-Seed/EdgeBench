import ConNF.Base.TypeIndex

/-!
# Levels

In this file, we provide a typeclass `Level` that stores the current type level of the construction.

## Main declarations

* `ConNF.Level`: The current level.
* `ConNF.LtLevel`: A type index less than the current level.
* `ConNF.LeLevel`: A type index less than or equal to the current level.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}]

class Level where
  /-- The current level of the construction. -/
  α : Λ

export Level (α)

variable [Level]

class LtLevel (β : TypeIndex) : Prop where
  elim : β < α

class LeLevel (β : TypeIndex) : Prop where
  elim : β ≤ α

instance {β : TypeIndex} [LtLevel β] : LeLevel β where
  elim := LtLevel.elim.le

instance : LeLevel α where
  elim := le_rfl

instance : LtLevel ⊥ where
  elim := WithBot.bot_lt_coe α

end ConNF
