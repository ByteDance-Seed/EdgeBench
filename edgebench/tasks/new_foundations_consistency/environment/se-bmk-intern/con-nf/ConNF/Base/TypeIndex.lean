import ConNF.Base.Params

/-!
# Type indices

We are going to use the inhabitants of `Λ` to enumerate the type levels in the final model we will
construct. However, in order to run the model construction, we need to first build an auxiliary
layer of the model below all of the ones that will appear in the final model. This extra level is
sometimes called "type `-1`".

The easiest way for us to introduce such an extra index is to formally adjoin a new symbol to `Λ`,
called `⊥`, which will play the role of `-1`. This new type, with `⊥` adjoined, is called the type
of *type indices*. When a distinction between `Λ` and the type indices is important, we call the
former the type of *proper type indices*.

It is important to take note of the difference between a type-in-Lean and a type-in-the-model;
hopefully it should be clear from context which is meant.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

/-- Either the base type or a proper type index (an inhabitant of `Λ`).
The base type index is written `⊥`. -/
@[reducible]
def TypeIndex :=
  WithBot Λ

/-- Allows us to use `termination_by` clauses with `TypeIndex`. -/
instance : WellFoundedRelation TypeIndex where
  rel := (· < ·)
  wf := IsWellFounded.wf

/-- Initial segments of `Λ` (excluding the endpoint) have cardinalities less than the cofinality of
`μ`. This means that maps from such initial segments into `μ` cannot be cofinal. -/
theorem Λ_card_Iio_lt (α : Λ) : #{β | β < α} < (#μ).ord.cof := by
  sorry

/-- Initial segments of `Λ` (including the endpoint) have cardinalities less than the
cofinality of `μ`. -/
theorem Λ_card_Iic_lt (α : Λ) : #{β | β ≤ α} < (#μ).ord.cof := by
  sorry

end ConNF
