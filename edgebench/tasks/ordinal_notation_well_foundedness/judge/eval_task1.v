From Coq Require Import List.
Import ListNotations.

Require Import ChildOf.

Definition WF_def := Acc (fun child parent : list nat => child_step parent child) [0; 1].

Require task1.

Lemma WF' : WF_def.
Proof.
  apply task1.WF.
Qed.

Print Assumptions WF'.
