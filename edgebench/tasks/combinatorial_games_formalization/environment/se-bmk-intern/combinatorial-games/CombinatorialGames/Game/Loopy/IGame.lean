/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.IGame
public import CombinatorialGames.Game.Loopy.Basic

/-!
# Well-founded games to loopy games

We define the embedding `IGame ↪ LGame`, and prove that it behaves in the expected ways with
arithmetic.
-/

open Set

public noncomputable section

namespace IGame

private def toLGame' (x : IGame) : LGame :=
  !{range fun y : xᴸ ↦ toLGame' y | range fun y : xᴿ ↦ toLGame' y}
termination_by x
decreasing_by igame_wf

private theorem toLGame'_def (x : IGame) :
    x.toLGame' = !{toLGame' '' xᴸ | toLGame' '' xᴿ} := by
  sorry

private theorem toLGame'_def' (x : IGame) :
    x.toLGame' = !{fun p ↦ toLGame' '' x.moves p} := by
  sorry

private theorem toLGame'_inj {x y : IGame} (h : x.toLGame' = y.toLGame') : x = y := by
  sorry

#adaptation_note /-- noncomputable is now needed -/ in
/-- The inclusion map from well-founded games into loopy games. -/
noncomputable def toLGame : IGame ↪ LGame where
  toFun := toLGame'
  inj' _ _ := toLGame'_inj

instance : Coe IGame LGame := ⟨toLGame⟩

theorem toLGame_def (x : IGame) :
    x.toLGame = !{toLGame '' xᴸ | toLGame '' xᴿ} := by
  sorry

@[simp]
theorem moves_toLGame (p : Player) (x : IGame) : x.toLGame.moves p = toLGame '' x.moves p := by
  sorry

theorem acc_toLGame (x : IGame) : Acc LGame.Subposition x.toLGame := by
  sorry

theorem mem_range_toLGame_iff_acc {x : LGame} : x ∈ range toLGame ↔
    Acc LGame.Subposition x := by
  sorry

@[simp]
theorem stopper_toLGame (x : IGame) : LGame.Stopper x := by
  sorry

@[simp]
theorem toLGame_zero : toLGame 0 = 0 := by
  sorry

@[simp]
theorem toLGame_one : toLGame 1 = 1 := by
  sorry

@[simp]
theorem toLGame_neg (x : IGame) : toLGame (-x) = -toLGame x := by
  sorry

@[simp]
theorem toLGame_add (x y : IGame) : toLGame (x + y) = toLGame x + toLGame y := by
  sorry

@[simp]
theorem toLGame_sub (x y : IGame) : toLGame (x - y) = toLGame x - toLGame y := by
  sorry

@[simp]
theorem toLGame_mul (x y : IGame) : toLGame (x * y) = toLGame x * toLGame y := by
  sorry

@[simp]
theorem toLGame_mulOption (x y a b : IGame) :
    toLGame (mulOption x y a b) = LGame.mulOption x y a b := by
  sorry

end IGame
end
