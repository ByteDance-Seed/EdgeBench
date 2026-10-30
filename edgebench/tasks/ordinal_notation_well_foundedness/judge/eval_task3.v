From Coq Require Import List.
Import ListNotations.

Require Import ChildOf.

Definition WF_def := Acc (fun child parent : list nat => child_step parent child) [0; 1; 0; 0; 3; 3].

Require task3.

Lemma WF' : WF_def.
Proof.
  apply task3.WF.
Qed.

Print Assumptions WF'.
