(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

From Stdlib Require Import PeanoNat BinInt.
From Stdlib Require Export Wf_nat.
From Stdlib Require Import Lia.
#[local] Open Scope Z_scope.

(** Well-founded relations on Z. *)

(** We define the following family of relations on [Z x Z]:

    [x (Zwf c) y]   iff   [x < y & c <= y]
 *)

Definition Zwf (c x y:Z) := c <= y /\ x < y.

(** and we prove that [(Zwf c)] is well founded *)

Section wf_proof.

  Variable c : Z.

  (** The proof of well-foundness is classic: we do the proof by induction
      on a measure in nat, which is here [|x-c|] *)

  Let f (z:Z) := Z.abs_nat (z - c).

  Lemma Zwf_well_founded : well_founded (Zwf c).
    red; intros.
    assert (forall (n:nat) (a:Z), (f a < n)%nat \/ a < c -> Acc (Zwf c) a). {
    clear a; simple induction n; intros.
    - (** n= 0 *)
      case H; intros.
      + lia.
      + apply Acc_intro; unfold Zwf; intros.
        lia.
    - (** inductive case *)
      case H0; clear H0; intro; auto.
      apply Acc_intro; intros.
      apply H.
      unfold Zwf in H1.
      case (Z.le_gt_cases c y); intro. 2: lia.
      left.
      apply Nat.lt_le_trans with (f a); auto with arith.
      unfold f.
      lia.
    }
    apply (H (S (f a))); auto.
  Qed.

End wf_proof.

#[global]
Hint Resolve Zwf_well_founded: datatypes.


(** We also define the other family of relations:

    [x (Zwf_up c) y]   iff   [y < x <= c]
 *)

Definition Zwf_up (c x y:Z) := y < x <= c.

(** and we prove that [(Zwf_up c)] is well founded *)

Section wf_proof_up.

  Variable c : Z.

  (** The proof of well-foundness is classic: we do the proof by induction
      on a measure in nat, which is here [|c-x|] *)

  Let f (z:Z) := Z.abs_nat (c - z).

  Lemma Zwf_up_well_founded : well_founded (Zwf_up c).
  Proof.
    apply well_founded_lt_compat with (f := f).
    unfold Zwf_up, f.
    lia.
  Qed.

End wf_proof_up.

#[global]
Hint Resolve Zwf_up_well_founded: datatypes.
