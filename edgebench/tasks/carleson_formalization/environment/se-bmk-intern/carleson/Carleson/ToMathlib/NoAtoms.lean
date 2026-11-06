/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro
-/
module

public import Mathlib.MeasureTheory.Measure.Typeclasses.NoAtoms
public import Mathlib.Data.PFun

--Upstreaming status: The new definition for `NoAtoms` will be developed in a separate project.

/-!
# Measures having no atoms
-/

@[expose] public section

namespace MeasureTheory

open Set Measure Filter TopologicalSpace

variable {α : Type*} {m0 : MeasurableSpace α}

/-- Measure `μ` *has no atoms* if for any measurable set `s` with positive `μ`-measure,
there exists a measurable `t ⊆ s` such that `0 < μ t < μ s`. While this implies `μ {x} = 0`,
the converse is not true. -/
class NoAtoms' (μ : Measure α) : Prop where
  exists_subset_lt : ∀ s, 0 < μ s → ∃ t ⊆ s, 0 < μ t ∧ μ t < μ s

export MeasureTheory.NoAtoms' (exists_subset_lt)

variable {μ : Measure α} [na : NoAtoms' μ]

namespace NoAtoms'

theorem exists_nullmeasurable_between_measure_eq {s t : Set α} (hs : NullMeasurableSet s μ)
  (ht : NullMeasurableSet t μ) (h : s ⊆ t) {x : ENNReal} (lb : μ s ≤ x) (ub : x ≤ μ t) :
    ∃ u, NullMeasurableSet u μ ∧ s ⊆ u ∧ u ⊆ t ∧ μ u = x := by
  sorry

--TODO: Lyapunovs convexity theorem

end NoAtoms'

end MeasureTheory
