/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu, František Silváši
-/
module

public meta import Lean.Elab.Tactic.Basic
public meta import Lean.Meta.Tactic.Assert

/-!
# Eagerly add instances

Many definitions in game theory are hereditary. For instance, all options of a `Numeric` game are
`Numeric`, all options of an `Impartial` game are `Impartial`, etc.

The definition `addInstances` provides a tactic which will eagerly apply all passed functions to all
of the hypotheses, creating new ones in the process. The intended usage of this is to, for instance,
apply `Numeric.of_mem_moves` to all hypotheses, and thus build all possible `Numeric` instances.
-/

open Lean Meta Elab Tactic

meta def instances (constants : Array Name) (goal : MVarId) : MetaM (Option MVarId) :=
  goal.withContext do
    let mut goal := goal
    for h in ← getLCtx do
      if h.isImplementationDetail then continue
      ⟨_, goal⟩ ← goal.assertHypotheses =<< constants.filterMapM fun c => do
        let hc ← try mkAppM c #[h.toExpr] catch _ => return none
        return some {
          userName := ← mkFreshUserName `inst
          type := ← inferType hc
          value := hc
        }
    return goal

/-- A tactic that eagerly adds instances by applying the functions in `constants` to every
hypothesis. -/
public meta def addInstances (constants : Array Name) : TacticM Unit :=
  liftMetaTactic1 (instances constants)
