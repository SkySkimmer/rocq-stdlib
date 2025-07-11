(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

From Stdlib Require Import Rbase.
From Stdlib Require Import Rfunctions.
From Stdlib Require Import Ranalysis1.
From Stdlib Require Import Lra.
#[local] Open Scope R_scope.

(**********)
Lemma formule :
  forall (x h l1 l2:R) (f1 f2:R -> R),
    h <> 0 ->
    f2 x <> 0 ->
    f2 (x + h) <> 0 ->
    (f1 (x + h) / f2 (x + h) - f1 x / f2 x) / h -
    (l1 * f2 x - l2 * f1 x) / Rsqr (f2 x) =
    / f2 (x + h) * ((f1 (x + h) - f1 x) / h - l1) +
    l1 / (f2 x * f2 (x + h)) * (f2 x - f2 (x + h)) -
    f1 x / (f2 x * f2 (x + h)) * ((f2 (x + h) - f2 x) / h - l2) +
    l2 * f1 x / (Rsqr (f2 x) * f2 (x + h)) * (f2 (x + h) - f2 x).
Proof.
  intros; unfold Rdiv, Rminus, Rsqr.
  repeat rewrite Rmult_plus_distr_r; repeat rewrite Rmult_plus_distr_l;
    repeat rewrite Rinv_mult.
  replace (l1 * f2 x * (/ f2 x * / f2 x)) with (l1 * / f2 x * (f2 x * / f2 x));
  [ idtac | ring ].
  replace (l1 * (/ f2 x * / f2 (x + h)) * f2 x) with
  (l1 * / f2 (x + h) * (f2 x * / f2 x)); [ idtac | ring ].
  replace (l1 * (/ f2 x * / f2 (x + h)) * - f2 (x + h)) with
  (- (l1 * / f2 x * (f2 (x + h) * / f2 (x + h)))); [ idtac | ring ].
  replace (f1 x * (/ f2 x * / f2 (x + h)) * (f2 (x + h) * / h)) with
  (f1 x * / f2 x * / h * (f2 (x + h) * / f2 (x + h)));
  [ idtac | ring ].
  replace (f1 x * (/ f2 x * / f2 (x + h)) * (- f2 x * / h)) with
  (- (f1 x * / f2 (x + h) * / h * (f2 x * / f2 x)));
  [ idtac | ring ].
  replace (l2 * f1 x * (/ f2 x * / f2 x * / f2 (x + h)) * f2 (x + h)) with
  (l2 * f1 x * / f2 x * / f2 x * (f2 (x + h) * / f2 (x + h)));
  [ idtac | ring ].
  replace (l2 * f1 x * (/ f2 x * / f2 x * / f2 (x + h)) * - f2 x) with
  (- (l2 * f1 x * / f2 x * / f2 (x + h) * (f2 x * / f2 x)));
  [ idtac | ring ].
  repeat rewrite Rinv_r; try assumption || ring.
Qed.

(* begin hide *)
Notation Rmin_pos := Rmin_pos (only parsing). (* compat *)
(* end hide *)

Lemma maj_term1 :
  forall (x h eps l1 alp_f2:R) (eps_f2 alp_f1d:posreal)
    (f1 f2:R -> R),
    0 < eps ->
    f2 x <> 0 ->
    f2 (x + h) <> 0 ->
    (forall h:R,
      h <> 0 ->
      Rabs h < alp_f1d ->
      Rabs ((f1 (x + h) - f1 x) / h - l1) < Rabs (eps * f2 x / 8)) ->
    (forall a:R,
      Rabs a < Rmin eps_f2 alp_f2 -> / Rabs (f2 (x + a)) < 2 / Rabs (f2 x)) ->
    h <> 0 ->
    Rabs h < alp_f1d ->
    Rabs h < Rmin eps_f2 alp_f2 ->
    Rabs (/ f2 (x + h) * ((f1 (x + h) - f1 x) / h - l1)) < eps / 4.
Proof.
  intros.
  assert (H7 := H3 h H6).
  assert (H8 := H2 h H4 H5).
  apply Rle_lt_trans with
    (2 / Rabs (f2 x) * Rabs ((f1 (x + h) - f1 x) / h - l1)).
  - rewrite Rabs_mult.
    apply Rmult_le_compat_r.
    + apply Rabs_pos.
    + rewrite Rabs_inv; left; exact H7.
  - apply Rlt_le_trans with (2 / Rabs (f2 x) * Rabs (eps * f2 x / 8)).
    + apply Rmult_lt_compat_l.
      * unfold Rdiv; apply Rmult_lt_0_compat;
          [ prove_sup0 | apply Rinv_0_lt_compat; apply Rabs_pos_lt; assumption ].
      * exact H8.
    + right; unfold Rdiv.
      repeat rewrite Rabs_mult.
      rewrite Rabs_inv.
      rewrite (Rabs_pos_eq 8) by now apply IZR_le.
      rewrite (Rabs_pos_eq eps).
      * field.
        now apply Rabs_no_R0.
      * now apply Rlt_le.
Qed.

Lemma maj_term2 :
  forall (x h eps l1 alp_f2 alp_f2t2:R) (eps_f2:posreal)
    (f2:R -> R),
    0 < eps ->
    f2 x <> 0 ->
    f2 (x + h) <> 0 ->
    (forall a:R,
      Rabs a < alp_f2t2 ->
      Rabs (f2 (x + a) - f2 x) < Rabs (eps * Rsqr (f2 x) / (8 * l1))) ->
    (forall a:R,
      Rabs a < Rmin eps_f2 alp_f2 -> / Rabs (f2 (x + a)) < 2 / Rabs (f2 x)) ->
    h <> 0 ->
    Rabs h < alp_f2t2 ->
    Rabs h < Rmin eps_f2 alp_f2 ->
    l1 <> 0 -> Rabs (l1 / (f2 x * f2 (x + h)) * (f2 x - f2 (x + h))) < eps / 4.
Proof.
  intros.
  assert (H8 := H3 h H6).
  assert (H9 := H2 h H5).
  apply Rle_lt_trans with
    (Rabs (l1 / (f2 x * f2 (x + h))) * Rabs (eps * Rsqr (f2 x) / (8 * l1))).
  { rewrite Rabs_mult; apply Rmult_le_compat_l.
    { apply Rabs_pos. }
    rewrite <- (Rabs_Ropp (f2 x - f2 (x + h))); rewrite Ropp_minus_distr.
    left; apply H9. }
  apply Rlt_le_trans with
    (Rabs (2 * (l1 / (f2 x * f2 x))) * Rabs (eps * Rsqr (f2 x) / (8 * l1))).
  { apply Rmult_lt_compat_r.
    { apply Rabs_pos_lt.
      unfold Rdiv; unfold Rsqr; repeat apply prod_neq_R0;
        try assumption || discrR.
      { lra. }
      apply Rinv_neq_0_compat; apply prod_neq_R0; try assumption || discrR.
    }
    unfold Rdiv.
    repeat rewrite Rinv_mult.
    repeat rewrite Rabs_mult.
    replace (Rabs 2) with 2 by (symmetry; apply Rabs_right; left; prove_sup0).
    rewrite (Rmult_comm 2).
    replace (Rabs l1 * (Rabs (/ f2 x) * Rabs (/ f2 x)) * 2) with
      (Rabs l1 * (Rabs (/ f2 x) * (Rabs (/ f2 x) * 2))) by ring.
    repeat apply Rmult_lt_compat_l.
    - apply Rabs_pos_lt; assumption.
    - apply Rabs_pos_lt; apply Rinv_neq_0_compat; assumption.
    - repeat rewrite Rabs_inv.
      rewrite <- (Rmult_comm 2).
      unfold Rdiv in H8; exact H8.
  }
  right.
  unfold Rsqr, Rdiv.
  rewrite 2!Rinv_mult.
  repeat rewrite Rabs_mult.
  repeat rewrite Rabs_inv.
  replace (Rabs eps) with eps by (symmetry ; apply Rabs_right; left; assumption).
  replace (Rabs 8) with 8 by (symmetry ; apply Rabs_right; left; prove_sup).
  replace (Rabs 2) with 2 by (symmetry ; apply Rabs_right; left; prove_sup0).
  replace 8 with (4 * 2); [ idtac | ring ].
  rewrite Rinv_mult.
  replace
    (2 * (Rabs l1 * (/ Rabs (f2 x) * / Rabs (f2 x))) *
       (eps * (Rabs (f2 x) * Rabs (f2 x)) * (/ 4 * / 2 * / Rabs l1))) with
    (eps * / 4 * (Rabs l1 * / Rabs l1) * (Rabs (f2 x) * / Rabs (f2 x)) *
       (Rabs (f2 x) * / Rabs (f2 x)) * (2 * / 2)); [ idtac | ring ].
  repeat rewrite Rinv_r; try (apply Rabs_no_R0; assumption) || discrR.
  ring.
Qed.

Lemma maj_term3 :
  forall (x h eps l2 alp_f2:R) (eps_f2 alp_f2d:posreal)
    (f1 f2:R -> R),
    0 < eps ->
    f2 x <> 0 ->
    f2 (x + h) <> 0 ->
    (forall h:R,
      h <> 0 ->
      Rabs h < alp_f2d ->
      Rabs ((f2 (x + h) - f2 x) / h - l2) <
      Rabs (Rsqr (f2 x) * eps / (8 * f1 x))) ->
    (forall a:R,
      Rabs a < Rmin eps_f2 alp_f2 -> / Rabs (f2 (x + a)) < 2 / Rabs (f2 x)) ->
    h <> 0 ->
    Rabs h < alp_f2d ->
    Rabs h < Rmin eps_f2 alp_f2 ->
    f1 x <> 0 ->
    Rabs (f1 x / (f2 x * f2 (x + h)) * ((f2 (x + h) - f2 x) / h - l2)) <
    eps / 4.
Proof.
  intros.
  assert (H8 := H2 h H4 H5).
  assert (H9 := H3 h H6).
  apply Rle_lt_trans with
    (Rabs (f1 x / (f2 x * f2 (x + h))) * Rabs (Rsqr (f2 x) * eps / (8 * f1 x))).
  { rewrite Rabs_mult.
    apply Rmult_le_compat_l.
    { apply Rabs_pos. }
    left; apply H8. }
  apply Rlt_le_trans with
    (Rabs (2 * (f1 x / (f2 x * f2 x))) * Rabs (Rsqr (f2 x) * eps / (8 * f1 x))).
  - apply Rmult_lt_compat_r.
    { apply Rabs_pos_lt.
      unfold Rdiv; unfold Rsqr; repeat apply prod_neq_R0;
        try assumption.
      { lra. }
      apply Rinv_neq_0_compat; apply prod_neq_R0; discrR || assumption. }
    unfold Rdiv.
    repeat rewrite Rinv_mult.
    repeat rewrite Rabs_mult.
    replace (Rabs 2) with 2 by (symmetry ; apply Rabs_right; left; prove_sup0).
    rewrite (Rmult_comm 2).
    replace (Rabs (f1 x) * (Rabs (/ f2 x) * Rabs (/ f2 x)) * 2) with
      (Rabs (f1 x) * (Rabs (/ f2 x) * (Rabs (/ f2 x) * 2))) by ring.
    repeat apply Rmult_lt_compat_l.
    { apply Rabs_pos_lt; assumption. }
    { apply Rabs_pos_lt; apply Rinv_neq_0_compat; assumption. }
    repeat rewrite Rabs_inv.
    rewrite <- (Rmult_comm 2).
    unfold Rdiv in H9; exact H9.
  - right.
    unfold Rsqr, Rdiv.
    rewrite 2!Rinv_mult.
    repeat rewrite Rabs_mult.
    repeat rewrite Rabs_inv.
    replace (Rabs eps) with eps by (symmetry ; apply Rabs_right; left; assumption).
    replace (Rabs 8) with 8 by (symmetry ; apply Rabs_right; left; prove_sup).
    replace (Rabs 2) with 2 by (symmetry ; apply Rabs_right; left; prove_sup0).
    replace 8 with (4 * 2); [ idtac | ring ].
    rewrite Rinv_mult.
    replace
      (2 * (Rabs (f1 x) * (/ Rabs (f2 x) * / Rabs (f2 x))) *
         (Rabs (f2 x) * Rabs (f2 x) * eps * (/ 4 * / 2 * / Rabs (f1 x)))) with
      (eps * / 4 * (Rabs (f2 x) * / Rabs (f2 x)) * (Rabs (f2 x) * / Rabs (f2 x)) *
         (Rabs (f1 x) * / Rabs (f1 x)) * (2 * / 2)); [ idtac | ring ].
    repeat rewrite Rinv_r; try discrR || (apply Rabs_no_R0; assumption).
    ring.
Qed.

Lemma maj_term4 :
  forall (x h eps l2 alp_f2 alp_f2c:R) (eps_f2:posreal)
    (f1 f2:R -> R),
    0 < eps ->
    f2 x <> 0 ->
    f2 (x + h) <> 0 ->
    (forall a:R,
      Rabs a < alp_f2c ->
      Rabs (f2 (x + a) - f2 x) <
      Rabs (Rsqr (f2 x) * f2 x * eps / (8 * f1 x * l2))) ->
    (forall a:R,
      Rabs a < Rmin eps_f2 alp_f2 -> / Rabs (f2 (x + a)) < 2 / Rabs (f2 x)) ->
    h <> 0 ->
    Rabs h < alp_f2c ->
    Rabs h < Rmin eps_f2 alp_f2 ->
    f1 x <> 0 ->
    l2 <> 0 ->
    Rabs (l2 * f1 x / (Rsqr (f2 x) * f2 (x + h)) * (f2 (x + h) - f2 x)) <
    eps / 4.
Proof.
  intros.
  assert (H9 := H2 h H5).
  assert (H10 := H3 h H6).
  apply Rle_lt_trans with
    (Rabs (l2 * f1 x / (Rsqr (f2 x) * f2 (x + h))) *
       Rabs (Rsqr (f2 x) * f2 x * eps / (8 * f1 x * l2))).
  { rewrite Rabs_mult.
    apply Rmult_le_compat_l.
    - apply Rabs_pos.
    - left; apply H9. }
  apply Rlt_le_trans with
    (Rabs (2 * l2 * (f1 x / (Rsqr (f2 x) * f2 x))) *
       Rabs (Rsqr (f2 x) * f2 x * eps / (8 * f1 x * l2))).
  { apply Rmult_lt_compat_r.
    { apply Rabs_pos_lt.
      unfold Rdiv; unfold Rsqr; repeat apply prod_neq_R0;
        assumption || idtac.
      { lra. }
      apply Rinv_neq_0_compat; apply prod_neq_R0;lra.
    }
    unfold Rdiv.
    repeat rewrite Rinv_mult.
    repeat rewrite Rabs_mult.
    replace (Rabs 2) with 2 by (symmetry ; apply Rabs_right; left; prove_sup0).
    replace
      (2 * Rabs l2 * (Rabs (f1 x) * (Rabs (/ Rsqr (f2 x)) * Rabs (/ f2 x)))) with
      (Rabs l2 * (Rabs (f1 x) * (Rabs (/ Rsqr (f2 x)) * (Rabs (/ f2 x) * 2))));
      [ idtac | ring ].
    replace
      (Rabs l2 * Rabs (f1 x) * (Rabs (/ Rsqr (f2 x)) * Rabs (/ f2 (x + h)))) with
      (Rabs l2 * (Rabs (f1 x) * (Rabs (/ Rsqr (f2 x)) * Rabs (/ f2 (x + h)))));
      [ idtac | ring ].
    repeat apply Rmult_lt_compat_l;try apply Rabs_pos_lt.
    1,2:assumption.
    { apply Rinv_neq_0_compat; unfold Rsqr;
        apply prod_neq_R0; assumption. }
    repeat rewrite Rabs_inv.
    rewrite <- (Rmult_comm 2).
    unfold Rdiv in H10; exact H10.
  }
  right; unfold Rsqr, Rdiv.
  rewrite 4!Rinv_mult.
  repeat rewrite Rabs_mult.
  repeat rewrite Rabs_inv.
  replace (Rabs eps) with eps by (symmetry ; apply Rabs_right; left; assumption).
  replace (Rabs 8) with 8 by (symmetry ; apply Rabs_right; left; prove_sup).
  replace (Rabs 2) with 2 by (symmetry ; apply Rabs_right; left; prove_sup0).
  replace 8 with (4 * 2); [ idtac | ring ].
  rewrite Rinv_mult.
  replace
  (2 * Rabs l2 *
    (Rabs (f1 x) * (/ Rabs (f2 x) * / Rabs (f2 x) * / Rabs (f2 x))) *
    (Rabs (f2 x) * Rabs (f2 x) * Rabs (f2 x) * eps *
      (/ 4 * / 2 * / Rabs (f1 x) * / Rabs l2))) with
  (eps * / 4 * (Rabs l2 * / Rabs l2) * (Rabs (f1 x) * / Rabs (f1 x)) *
    (Rabs (f2 x) * / Rabs (f2 x)) * (Rabs (f2 x) * / Rabs (f2 x)) *
    (Rabs (f2 x) * / Rabs (f2 x)) * (2 * / 2)); [ idtac | ring ].
  repeat rewrite Rinv_r; try discrR || (apply Rabs_no_R0; assumption).
  ring.
Qed.

Lemma D_x_no_cond : forall x a:R, a <> 0 -> D_x no_cond x (x + a).
Proof.
  intros.
  unfold D_x, no_cond.
  split.
  - trivial.
  - apply Rminus_not_eq.
    unfold Rminus.
    rewrite Ropp_plus_distr.
    rewrite <- Rplus_assoc.
    rewrite Rplus_opp_r.
    rewrite Rplus_0_l.
    apply Ropp_neq_0_compat; assumption.
Qed.

Lemma Rabs_4 :
  forall a b c d:R, Rabs (a + b + c + d) <= Rabs a + Rabs b + Rabs c + Rabs d.
Proof.
  intros.
  apply Rle_trans with (Rabs (a + b) + Rabs (c + d)).
  - replace (a + b + c + d) with (a + b + (c + d)); [ apply Rabs_triang | ring ].
  - apply Rle_trans with (Rabs a + Rabs b + Rabs (c + d)).
    + apply Rplus_le_compat_r.
      apply Rabs_triang.
    + repeat rewrite Rplus_assoc; repeat apply Rplus_le_compat_l.
      apply Rabs_triang.
Qed.

Lemma Rlt_4 :
  forall a b c d e f g h:R,
    a < b -> c < d -> e < f -> g < h -> a + c + e + g < b + d + f + h.
Proof.
  intros. repeat apply Rplus_lt_compat;assumption.
Qed.

(* begin hide *)
Notation Rmin_2 := Rmin_glb_lt (only parsing).
(* end hide *)

Lemma quadruple : forall x:R, 4 * x = x + x + x + x.
Proof.
  intro; ring.
Qed.

Lemma quadruple_var : forall x:R, x = x / 4 + x / 4 + x / 4 + x / 4.
Proof.
  intros;field.
Qed.

(**********)
Lemma continuous_neq_0 :
  forall (f:R -> R) (x0:R),
    continuity_pt f x0 ->
    f x0 <> 0 ->
    exists eps : posreal, (forall h:R, Rabs h < eps -> f (x0 + h) <> 0).
Proof.
  intros; unfold continuity_pt in H; unfold continue_in in H;
    unfold limit1_in in H; unfold limit_in in H; elim (H (Rabs (f x0 / 2))).
  2:{ change (0 < Rabs (f x0 / 2)).
      apply Rabs_pos_lt; unfold Rdiv; apply prod_neq_R0;lra. }
  intros; elim H1; intros.
  exists (mkposreal x H2).
  intros; assert (H5 := H3 (x0 + h)).
  cut
    (dist R_met (x0 + h) x0 < x ->
      dist R_met (f (x0 + h)) (f x0) < Rabs (f x0 / 2)).
  2:{ assert (H6 := Req_dec x0 (x0 + h)); elim H6; intro.
      - intro; rewrite <- H7. unfold R_met, dist; unfold Rdist;
          unfold Rminus; rewrite Rplus_opp_r; rewrite Rabs_R0;
          apply Rabs_pos_lt.
        unfold Rdiv; apply prod_neq_R0;
          [ assumption | apply Rinv_neq_0_compat; discrR ].
      - intro; apply H5.
        split.
        + unfold D_x, no_cond.
          split; trivial || assumption.
        + assumption.
  }
  unfold dist; simpl; unfold Rdist;
    replace (x0 + h - x0) with h by ring.
  intros; assert (H7 := H6 H4).
  red; intro.
  rewrite H8 in H7; unfold Rminus in H7; rewrite Rplus_0_l in H7;
    rewrite Rabs_Ropp in H7; unfold Rdiv in H7; rewrite Rabs_mult in H7;
    pattern (Rabs (f x0)) at 1 in H7; rewrite <- Rmult_1_r in H7.
  assert (0 < Rabs (f x0)) by (apply (Rabs_pos_lt _ H0)).
  assert (H10 := Rmult_lt_reg_l _ _ _ H9 H7).
  assert (Rabs (/ 2) = / 2) by (apply Rabs_pos_eq;lra).
  assert (Hyp : 0 < 2) by prove_sup0.
  rewrite H11 in H10; assert (H12 := Rmult_lt_compat_l 2 _ _ Hyp H10);
    rewrite Rmult_1_r in H12; rewrite Rinv_r in H12;
    [ idtac | discrR ].
  now apply lt_IZR in H12.
Qed.
