import ConNF.Counting.BaseCounting
import ConNF.Counting.CountSupportOrbit
import ConNF.Counting.Recode

/-!
# Concluding the counting argument

In this file, we finish the counting argument.

## Main declarations

* `ConNF.card_tSet_le`: There are at most `μ`-many t-sets at each level.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData]

theorem card_codingFunction (β : TypeIndex) [LeLevel β] :
    #(CodingFunction β) < #μ := by
  sorry

theorem card_supportOrbit (β : TypeIndex) [LeLevel β] :
    #(SupportOrbit β) < #μ := by
  sorry

/-- Note that we cannot prove the reverse implication because all of our hypotheses at this stage
are about permutations, not objects. -/
theorem card_tSet_le (β : TypeIndex) [LeLevel β] :
    #(TSet β) ≤ #μ := by
  sorry

theorem card_tangle_le (β : TypeIndex) [LeLevel β] :
    #(Tangle β) ≤ #μ := by
  sorry

end ConNF
