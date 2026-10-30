From Coq Require Import List.
Import ListNotations.

Require Import ChildOf.

Definition WF_def := Acc (fun child parent : list nat => child_step parent child) [0; 1; 0; 0; 4].

Require task4.

Lemma WF' : WF_def.
Proof.
  apply task4.WF.
Qed.

Print Assumptions WF'.
