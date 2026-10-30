From Coq Require Import List.
Import ListNotations.

Require Import ChildOf.

Lemma WF : Acc (fun child parent : list nat => child_step parent child) [0; 1; 0; 0; 3].
Proof.
Admitted.
