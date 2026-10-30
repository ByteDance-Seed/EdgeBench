import Mathlib.SetTheory.Ordinal.Arithmetic

class LtWellOrder (α : Type _) extends LinearOrder α, IsWellOrder α (· < ·)

variable {α β : Type _}

instance [LinearOrder α] [IsWellOrder α (· < ·)] : LtWellOrder α := ⟨⟩

open Ordinal
