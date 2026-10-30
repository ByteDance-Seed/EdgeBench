From Coq Require Import List Arith.PeanoNat Relations.Relation_Operators.
Import ListNotations.

Definition nth0 (a : list nat) (i : nat) : nat :=
  nth i a 0.

Definition child_flag (a : list nat) (BR : nat) : bool :=
  let n := length a in
  existsb
    (fun i => Nat.eqb (nth0 a (i - 1)) (nth0 a (BR - 1)))
    (seq (BR + 1) (n - (BR + 1))).

Definition child_block (a : list nat) (BR n i : nat) : list nat :=
  let flag := child_flag a BR in
  (if flag then nth0 a (BR - 1) else nth0 a (n - 1) - 1)
  :: map
       (fun j =>
          let x := nth0 a (j - 1) in
          if Nat.leb BR x then x + (n - BR) * i else x)
       (seq (BR + 1) (n - (BR + 1))).

Definition childOf (a : list nat) (N : nat) : list nat :=
  let n := length a in
  let BR := nth0 a (n - 1) in
  let a0 := removelast a in
  if Nat.eqb BR 0 then
    a0
  else
    a0 ++ concat (map (child_block a BR n) (seq 1 N)).

Definition nonempty_list : Type :=
  { a : list nat | a <> [] }.

Definition childOf_nonempty (a : nonempty_list) (N : nat) : list nat :=
  childOf (proj1_sig a) N.

Definition child_step (parent child : list nat) : Prop :=
  exists (Hparent : parent <> []) (N : nat),
    child = childOf_nonempty (exist _ parent Hparent) N.

Definition start : list nat := [0; 1; 0; 2; 0; 3].

Definition child_tree_from_start (node : list nat) : Prop :=
  clos_refl_trans (list nat) child_step start node.
