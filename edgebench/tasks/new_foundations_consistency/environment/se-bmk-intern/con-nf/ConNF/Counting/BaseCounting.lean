import ConNF.Counting.BaseCoding
import ConNF.Counting.CountSupportOrbit

/-!
# Counting coding functions at base type and level zero

In this file, we show that there are less than `μ` coding functions at levels `⊥` and `0`.

## Main declarations

* `ConNF.card_bot_codingFunction_lt`, `ConNF.card_codingFunction_lt_of_isMin`: There are less than
  `μ` coding functions at levels `⊥` and `0`.
-/

noncomputable section
universe u

open Cardinal Ordinal WithBot

namespace ConNF

variable [Params.{u}] [Level] [CoherentData]

theorem card_bot_codingFunction_lt :
    #(CodingFunction ⊥) < #μ := by
  sorry

theorem card_codingFunction_lt_of_isMin {β : Λ} [LeLevel β] (hβ : IsMin β) :
    #(CodingFunction β) < #μ := by
  sorry

end ConNF
