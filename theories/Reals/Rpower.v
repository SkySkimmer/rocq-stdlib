(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

(*i Due to L.Thery i*)

(************************************************************)
(* Definitions of log and Rpower : R->R->R; main properties *)
(************************************************************)

From Stdlib Require Import Rbase.
From Stdlib Require Import Rfunctions.
From Stdlib Require Import SeqSeries.
From Stdlib Require Import Rtrigo1.
From Stdlib Require Import Ranalysis1.
From Stdlib Require Import Exp_prop.
From Stdlib Require Import Rsqrt_def.
From Stdlib Require Import R_sqrt.
From Stdlib Require Import Sqrt_reg.
From Stdlib Require Import MVT.
From Stdlib Require Import Ranalysis4.
From Stdlib Require Import Lra.
From Stdlib Require Import Arith.Factorial.
#[local] Open Scope R_scope.

Definition P_Rmin_stt (P:R -> Prop) x y := Rmin_case x y P.
#[deprecated(since="8.16", note="Use Rmin_case instead.")]
Notation P_Rmin := P_Rmin_stt.

Lemma exp_le_3 : exp 1 <= 3.
Proof.
  assert (exp_1 : exp 1 <> 0). {
    assert (H0 := exp_pos 1); red; intro; rewrite H in H0;
    elim (Rlt_irrefl _ H0).
  }
  apply Rmult_le_reg_l with (/ exp 1).
  { apply Rinv_0_lt_compat; apply exp_pos. }
  rewrite Rinv_l.
  2:assumption.
  apply Rmult_le_reg_l with (/ 3).
  { lra. }
  rewrite Rmult_1_r; rewrite <- (Rmult_comm 3); rewrite <- Rmult_assoc;
    rewrite Rinv_l.
  2:lra.
  rewrite Rmult_1_l; replace (/ exp 1) with (exp (-1)).
  2:{ apply Rmult_eq_reg_l with (exp 1).
      2:assumption.
      rewrite <- exp_plus; rewrite Rplus_opp_r; rewrite exp_0;
      rewrite Rinv_r;trivial. }
  unfold exp; case (exist_exp (-1)) as (?,e); simpl in |- *;
    unfold exp_in in e;
      assert (H := alternated_series_ineq (fun i:nat => / INR (fact i)) x 1).
  cut
    (sum_f_R0 (tg_alt (fun i:nat => / INR (fact i))) (S (2 * 1)) <= x <=
      sum_f_R0 (tg_alt (fun i:nat => / INR (fact i))) (2 * 1)).
  { intro; elim H0; clear H0; intros H0 _; simpl in H0; unfold tg_alt in H0;
      simpl in H0.
    replace (/ 3) with
      (1 * / 1 + -1 * 1 * / 1 + -1 * (-1 * 1) * / 2 +
       -1 * (-1 * (-1 * 1)) * / (2 + 1 + 1 + 1 + 1)) by field.
    apply H0. }
  apply H.
  - unfold Un_decreasing; intros;
      apply Rmult_le_reg_l with (INR (fact n)).
    { apply INR_fact_lt_0. }
    apply Rmult_le_reg_l with (INR (fact (S n))).
    { apply INR_fact_lt_0. }
    rewrite Rinv_r.
    2:{ apply INR_fact_neq_0. }
    rewrite Rmult_1_r; rewrite Rmult_comm; rewrite Rmult_assoc;
      rewrite Rinv_l.
    2:{ apply INR_fact_neq_0. }
    rewrite Rmult_1_r; apply le_INR; apply fact_le; apply Nat.le_succ_diag_r.
  - assert (H0 := cv_speed_pow_fact 1); unfold Un_cv; unfold Un_cv in H0;
      intros; elim (H0 _ H1); intros; exists x0; intros;
      unfold Rdist in H2; unfold Rdist;
      replace (/ INR (fact n)) with (1 ^ n / INR (fact n));auto.
    unfold Rdiv; rewrite pow1; rewrite Rmult_1_l; reflexivity.
  - unfold infinite_sum in e; unfold Un_cv, tg_alt; intros; elim (e _ H0);
      intros; exists x0; intros;
      replace (sum_f_R0 (fun i:nat => (-1) ^ i * / INR (fact i)) n) with
      (sum_f_R0 (fun i:nat => / INR (fact i) * (-1) ^ i) n);auto.
    apply sum_eq; intros; apply Rmult_comm.
Qed.

(******************************************************************)
(** *                     Properties of  Exp                      *)
(******************************************************************)

Lemma exp_neq_0 : forall x:R, exp x <> 0.
Proof.
  intro x.
  exact (not_eq_sym (Rlt_not_eq 0 (exp x) (exp_pos x))).
Qed.

Theorem exp_increasing : forall x y:R, x < y -> exp x < exp y.
Proof.
  intros x y H.
  assert (H0 : derivable exp).
  - apply derivable_exp.
  - assert (H1 := positive_derivative _ H0).
    unfold strict_increasing in H1.
    apply H1.
    + intro.
      replace (derive_pt exp x0 (H0 x0)) with (exp x0).
      * apply exp_pos.
      * symmetry ; apply derive_pt_eq_0.
        apply (derivable_pt_lim_exp x0).
    + apply H.
Qed.

Theorem exp_lt_inv : forall x y:R, exp x < exp y -> x < y.
Proof.
  intros x y H; case (Rtotal_order x y); [ intros H1 | intros [H1| H1] ].
  - assumption.
  - rewrite H1 in H; elim (Rlt_irrefl _ H).
  - assert (H2 := exp_increasing _ _ H1).
    elim (Rlt_irrefl _ (Rlt_trans _ _ _ H H2)).
Qed.

Lemma exp_ineq1 : forall x : R, x <> 0 -> 1 + x < exp x.
Proof.
  assert (Hd : forall c : R,
             derivable_pt_lim (fun x : R => exp x - (x + 1)) c (exp c - 1)). {
    intros.
    apply derivable_pt_lim_minus; [apply derivable_pt_lim_exp | ].
    replace (1) with (1 + 0) at 1 by lra.
    apply derivable_pt_lim_plus;
    [apply derivable_pt_lim_id | apply derivable_pt_lim_const].
  }
  intros x xdz; destruct (Rtotal_order x 0)  as [xlz|[xez|xgz]].
  - destruct (MVT_cor2 _ _ x 0 xlz (fun c _ => Hd c)) as [c [HH1 HH2]].
    rewrite exp_0 in HH1.
    assert (H1 : 0 < x * exp c - x); [| lra].
    assert (H2 : x * exp 0  < x * exp c); [| rewrite exp_0 in H2; lra].
    apply Rmult_lt_gt_compat_neg_l; auto.
    now apply exp_increasing.
  - now case xdz.
  - destruct (MVT_cor2 _ _ 0 x xgz (fun c _ => Hd c)) as [c [HH1 HH2]].
    rewrite exp_0 in HH1.
    assert (H1 : 0 < x * exp c - x); [| lra].
    assert (H2 : x * exp 0  < x * exp c); [| rewrite exp_0 in H2; lra].
    apply Rmult_lt_compat_l; auto.
    now apply exp_increasing.
Qed.

Lemma exp_ineq1_le (x : R) : 1 + x <= exp x.
Proof.
  destruct (Req_dec x 0) as [xeq|?].
  - rewrite xeq, exp_0; lra.
  - left.
    now apply exp_ineq1.
Qed.

Lemma ln_exists1 : forall y:R, 1 <= y -> { z:R | y = exp z }.
Proof.
  intros; set (f := fun x:R => exp x - y).
  assert (H0 : 0 < y) by (apply Rlt_le_trans with 1; auto with real).
  cut (f 0 <= 0); [intro H1|].
  - cut (continuity f); [intro H2|].
    + cut (0 <= f y); [intro H3|].
      * cut (f 0 * f y <= 0); [intro H4|].
        -- pose proof (IVT_cor f 0 y H2 (Rlt_le _ _ H0) H4) as (t,(_,H7));
             exists t; unfold f in H7; symmetry; apply Rminus_diag_uniq; exact H7.
        -- pattern 0 at 2; rewrite <- (Rmult_0_r (f y));
             rewrite (Rmult_comm (f 0)); apply Rmult_le_compat_l;
             assumption.
      * unfold f; apply Rplus_le_reg_l with y; left;
          apply Rlt_trans with (1 + y).
        -- rewrite <- (Rplus_comm y); apply Rplus_lt_compat_l; apply Rlt_0_1.
        -- replace (y + (exp y - y)) with (exp y); [ apply (exp_ineq1 y); lra | ring ].
    + unfold f; change (continuity (exp - fct_cte y));
        apply continuity_minus;
        [ apply derivable_continuous; apply derivable_exp
        | apply derivable_continuous; apply derivable_const ].
  - unfold f; rewrite exp_0; apply Rplus_le_reg_l with y;
      rewrite Rplus_0_r; replace (y + (1 - y)) with 1; [ apply H | ring ].
Qed.

(**********)
Lemma ln_exists : forall y:R, 0 < y -> { z:R | y = exp z }.
Proof.
  intros; destruct (Rle_dec 1 y) as [Hle|Hnle].
  - apply (ln_exists1 _ Hle).
  - assert (H0 : 1 <= / y).
    + apply Rmult_le_reg_l with y.
      * apply H.
      * rewrite Rinv_r.
        -- rewrite Rmult_1_r; left; apply (Rnot_le_lt _ _ Hnle).
        -- red; intro; rewrite H0 in H; elim (Rlt_irrefl _ H).
    + destruct (ln_exists1 _ H0) as (x,p); exists (- x);
        apply Rmult_eq_reg_l with (exp x / y).
      * unfold Rdiv; rewrite Rmult_assoc; rewrite Rinv_l.
        -- rewrite Rmult_1_r; rewrite <- (Rmult_comm (/ y)); rewrite Rmult_assoc;
             rewrite <- exp_plus; rewrite Rplus_opp_r; rewrite exp_0;
             rewrite Rmult_1_r; symmetry ; apply p.
        -- red; intro H3; rewrite H3 in H; elim (Rlt_irrefl _ H).
      * unfold Rdiv; apply prod_neq_R0.
        -- assert (H3 := exp_pos x); red; intro H4; rewrite H4 in H3;
             elim (Rlt_irrefl _ H3).
        -- apply Rinv_neq_0_compat; red; intro H3; rewrite H3 in H;
             elim (Rlt_irrefl _ H).
Qed.

(* Definition of log R+* -> R *)
Definition Rln (y:posreal) : R :=
  let (a,_) := ln_exists (pos y) (cond_pos y) in a.

(* Extension on R *)
Definition ln (x:R) : R :=
  match Rlt_dec 0 x with
    | left a => Rln (mkposreal x a)
    | right a => 0
  end.

Definition Rlog x y := (ln y)/(ln x).

Lemma exp_ln : forall x:R, 0 < x -> exp (ln x) = x.
Proof.
  intros; unfold ln; decide (Rlt_dec 0 x) with H.
  unfold Rln;
    case (ln_exists (mkposreal x H) (cond_pos (mkposreal x H))) as (?,Hex).
  symmetry; apply Hex.
Qed.

Theorem exp_inv : forall x y:R, exp x = exp y -> x = y.
Proof.
  intros x y H; case (Rtotal_order x y); [ intros H1 | intros [H1| H1] ]; auto;
    assert (H2 := exp_increasing _ _ H1); rewrite H in H2;
      elim (Rlt_irrefl _ H2).
Qed.

Theorem exp_Ropp : forall x:R, exp (- x) = / exp x.
Proof.
  intros x; assert (H : exp x <> 0).
  - assert (H := exp_pos x); red; intro; rewrite H0 in H;
      elim (Rlt_irrefl _ H).
  - apply Rmult_eq_reg_l with (r := exp x).
    + rewrite <- exp_plus; rewrite Rplus_opp_r; rewrite exp_0.
      symmetry; apply Rinv_r.
      apply H.
    + apply H.
Qed.

(******************************************************************)
(** *                     Properties of  Ln                       *)
(******************************************************************)

Theorem ln_increasing : forall x y:R, 0 < x -> x < y -> ln x < ln y.
Proof.
  intros x y H H0; apply exp_lt_inv.
  repeat rewrite exp_ln.
  - apply H0.
  - apply Rlt_trans with x; assumption.
  - apply H.
Qed.

Theorem ln_exp : forall x:R, ln (exp x) = x.
Proof.
  intros x; apply exp_inv.
  apply exp_ln.
  apply exp_pos.
Qed.

Theorem ln_1 : ln 1 = 0.
Proof.
  rewrite <- exp_0; rewrite ln_exp; reflexivity.
Qed.

Theorem ln_lt_inv : forall x y:R, 0 < x -> 0 < y -> ln x < ln y -> x < y.
Proof.
  intros x y H H0 H1; rewrite <- (exp_ln x); try rewrite <- (exp_ln y).
  - apply exp_increasing; apply H1.
  - assumption.
  - assumption.
Qed.

Theorem ln_inv : forall x y:R, 0 < x -> 0 < y -> ln x = ln y -> x = y.
Proof.
  intros x y H H0 H'0; case (Rtotal_order x y); [ intros H1 | intros [H1| H1] ];
    auto.
  - assert (H2 := ln_increasing _ _ H H1); rewrite H'0 in H2;
      elim (Rlt_irrefl _ H2).
  - assert (H2 := ln_increasing _ _ H0 H1); rewrite H'0 in H2;
      elim (Rlt_irrefl _ H2).
Qed.

Lemma ln_neq_0 : forall x:R, x <> 1 -> 0 < x -> ln x <> 0.
Proof.
  intros x Hneq_x_1 Hlt_0_x.
  rewrite <- ln_1.
  intro H.
  assert (x = 1) as H0.
  + exact (ln_inv x 1 Hlt_0_x (ltac:(lra) : 0 < 1) H).
  + contradiction.
Qed.

Theorem ln_mult : forall x y:R, 0 < x -> 0 < y -> ln (x * y) = ln x + ln y.
Proof.
  intros x y H H0; apply exp_inv.
  rewrite exp_plus.
  repeat rewrite exp_ln.
  - reflexivity.
  - assumption.
  - assumption.
  - apply Rmult_lt_0_compat; assumption.
Qed.

Lemma ln_pow : forall (x : R), 0 < x -> forall (n : nat), ln (x^n) = (INR n)*(ln x).
Proof.
  intros x Hx.
  induction n as [|m Hm].
  + simpl.
    rewrite ln_1.
    exact (eq_sym (Rmult_0_l (ln x))).
  + unfold pow.
    fold pow.
    rewrite (ln_mult x (x^m) Hx (pow_lt x m Hx)).
    rewrite Hm.
    rewrite <- (Rmult_1_l (ln x)) at 1.
    rewrite <- (Rmult_plus_distr_r 1 (INR m) (ln x)).
    rewrite (Rplus_comm 1 (INR m)).
    destruct m as [|m]; simpl.
    - lra.
    - reflexivity.
Qed.

Theorem ln_Rinv : forall x:R, 0 < x -> ln (/ x) = - ln x.
Proof.
  intros x H; apply exp_inv; repeat rewrite exp_ln || rewrite exp_Ropp.
  - reflexivity.
  - assumption.
  - apply Rinv_0_lt_compat; assumption.
Qed.

Theorem ln_continue :
  forall y:R, 0 < y -> continue_in ln (fun x:R => 0 < x) y.
Proof.
  intros y H.
  unfold continue_in, limit1_in, limit_in; intros eps Heps.
  assert (H1:1 < exp eps). {
    rewrite <- exp_0.
    apply exp_increasing; apply Heps.
  }
  assert (H2:exp (- eps) < 1). {
    apply Rmult_lt_reg_l with (exp eps).
    - apply exp_pos.
    - rewrite <- exp_plus; rewrite Rmult_1_r; rewrite Rplus_opp_r; rewrite exp_0;
      apply H1.
  }
  exists (Rmin (y * (exp eps - 1)) (y * (1 - exp (- eps)))); split.
  { red; apply Rmin_case; nra. }
  unfold dist, R_met, Rdist; simpl.
  intros x [[H3 H4] H5].
  assert (Hxyy:y * (x * / y) = x). {
    field. lra.
  }
  replace (ln x - ln y) with (ln (x * / y)).
  2:{ rewrite ln_mult;try apply Rinv_0_lt_compat; try assumption.
      rewrite ln_Rinv;try assumption.
      ring. }
  pose proof (Rinv_0_lt_compat y) as Hinvy.
  case (Rtotal_order x y); [ intros Hxy | intros [Hxy| Hxy] ].
  - rewrite Rabs_left.
    2:{ rewrite <- ln_1.
        apply ln_increasing;nra. }
    apply Ropp_lt_cancel; rewrite Ropp_involutive.
    apply exp_lt_inv.
    rewrite exp_ln.
    2:nra.
    apply Rmult_lt_reg_l with (r := y).
    { apply H. }
    rewrite Hxyy.
    apply Ropp_lt_cancel.
    apply Rplus_lt_reg_l with (r := y).
    replace (y + - (y * exp (- eps))) with (y * (1 - exp (- eps)));
      [ idtac | ring ].
    replace (y + - x) with (Rabs (x - y)).
    2:{ rewrite Rabs_left; [ ring | idtac ].
        lra. }
    apply Rlt_le_trans with (1 := H5); apply Rmin_r.
  - rewrite Hxy; rewrite Rinv_r.
    2:lra.
    rewrite ln_1; rewrite Rabs_R0; apply Heps.
  - rewrite Rabs_right.
    2:{ rewrite <- ln_1.
        apply Rgt_ge; red; apply ln_increasing;nra. }
    apply exp_lt_inv.
    rewrite exp_ln.
    2:nra.
    apply Rmult_lt_reg_l with (r := y).
    { apply H. }
    rewrite Hxyy.
    apply Rplus_lt_reg_l with (r := - y).
    replace (- y + y * exp eps) with (y * (exp eps - 1)); [ idtac | ring ].
    replace (- y + x) with (Rabs (x - y)).
    2:{ rewrite Rabs_right; [ ring | idtac ]. lra. }
    apply Rlt_le_trans with (1 := H5); apply Rmin_l.
Qed.

(******************************************************************)
(** *                     Definition of  Rpower                   *)
(******************************************************************)

Definition Rpower (x y:R) := exp (y * ln x).

(******************************************************************)
(** *                     Properties of  Rpower                   *)
(******************************************************************)

(** Note: [Rpower] is prolongated to [1] on negative real numbers and
    it thus does not extend integer power. The next two lemmas, which
    hold for integer power, accidentally hold on negative real numbers
    as a side effect of the default value taken on negative real
    numbers. Contrastingly, the lemmas that do not hold for the
    integer power of a negative number are stated for [Rpower] on the
    positive numbers only (even if they accidentally hold due to the
    default value of [Rpower] on the negative side, as it is the case
    for [Rpower_O]). *)

Theorem Rpower_plus : forall x y z:R, Rpower z (x + y) = Rpower z x * Rpower z y.
Proof.
  intros x y z; unfold Rpower.
  rewrite Rmult_plus_distr_r; rewrite exp_plus; auto.
Qed.

Theorem Rpower_mult : forall x y z:R, Rpower (Rpower x y) z = Rpower x (y * z).
Proof.
  intros x y z; unfold Rpower.
  rewrite ln_exp.
  replace (z * (y * ln x)) with (y * z * ln x).
  - reflexivity.
  - ring.
Qed.

Theorem Rpower_O : forall x:R, 0 < x -> Rpower x 0 = 1.
Proof.
  intros x _; unfold Rpower.
  rewrite Rmult_0_l; apply exp_0.
Qed.

Theorem Rpower_1 : forall x:R, 0 < x -> Rpower x 1 = x.
Proof.
  intros x H; unfold Rpower.
  rewrite Rmult_1_l; apply exp_ln; apply H.
Qed.

Theorem Rpower_pow : forall (n:nat) (x:R), 0 < x -> Rpower x (INR n) = x ^ n.
Proof.
  intros n; elim n; simpl; auto; fold INR.
  - intros x H; apply Rpower_O; auto.
  - intros n1; case n1.
    + intros H x H0; simpl; rewrite Rmult_1_r; apply Rpower_1; auto.
    + intros n0 H x H0; rewrite Rpower_plus; rewrite H; try rewrite Rpower_1;
        try apply Rmult_comm || assumption.
Qed.

Lemma Rpower_nonzero : forall (x : R) (n : nat), 0 < x -> Rpower x (INR n) <> 0.
Proof.
  intros x n H.
  rewrite (Rpower_pow n x H).
  exact (pow_nonzero x n (not_eq_sym (Rlt_not_eq 0 x H))).
Qed.

Theorem Rpower_lt :
  forall x y z:R, 1 < x -> y < z -> Rpower x y < Rpower x z.
Proof.
  intros x y z H H1.
  unfold Rpower.
  apply exp_increasing.
  apply Rmult_lt_compat_r.
  - rewrite <- ln_1; apply ln_increasing.
    + apply Rlt_0_1.
    + apply H.
  - apply H1.
Qed.

Lemma Rpower_Rlog : forall x y:R, x <> 1 -> 0 < x -> 0 < y -> Rpower x (Rlog x y) = y.
Proof.
  intros x y H_neq_x_1 H_lt_0_x H_lt_0_y.
  unfold Rpower.
  unfold Rlog.
  unfold Rdiv.
  rewrite (Rmult_assoc (ln y) (/ln x) (ln x)).
  rewrite (Rinv_l (ln x) (ln_neq_0 x H_neq_x_1 H_lt_0_x)).
  rewrite (Rmult_1_r (ln y)).
  exact (exp_ln y H_lt_0_y).
Qed.

Theorem Rpower_sqrt : forall x:R, 0 < x -> Rpower x (/ 2) = sqrt x.
Proof.
  intros x H.
  apply ln_inv.
  - unfold Rpower; apply exp_pos.
  - apply sqrt_lt_R0; apply H.
  - apply Rmult_eq_reg_l with (INR 2).
    + apply exp_inv.
      fold Rpower.
      cut (Rpower (Rpower x (/ INR 2)) (INR 2) = Rpower (sqrt x) (INR 2)).
      * unfold Rpower; auto.
      * rewrite Rpower_mult.
        rewrite Rinv_l.
        -- change 1 with (INR 1).
           repeat rewrite Rpower_pow; simpl.
           ++ pattern x at 1; rewrite <- (sqrt_sqrt x (Rlt_le _ _ H)).
              ring.
           ++ apply sqrt_lt_R0; apply H.
           ++ apply H.
        -- apply not_O_INR; discriminate.
    + apply not_O_INR; discriminate.
Qed.

Theorem Rpower_Ropp : forall x y:R, Rpower x (- y) = / (Rpower x y).
Proof.
  unfold Rpower.
  intros x y; rewrite Ropp_mult_distr_l_reverse.
  apply exp_Ropp.
Qed.

Lemma powerRZ_Rpower x z : (0 < x)%R -> powerRZ x z = Rpower x (IZR z).
Proof.
  intros Hx.
  destruct (intP z).
  - now rewrite Rpower_O.
  - rewrite <- pow_powerRZ, <- Rpower_pow by assumption.
    now rewrite INR_IZR_INZ.
  - rewrite opp_IZR, Rpower_Ropp.
    rewrite powerRZ_neg'.
    now rewrite <- pow_powerRZ, <- INR_IZR_INZ, Rpower_pow.
Qed.

Theorem Rle_Rpower :
  forall e n m:R, 1 <= e -> n <= m -> Rpower e n <= Rpower e m.
Proof.
  intros e n m [H | H]; intros H1.
  - case H1.
    + intros H2; left; apply Rpower_lt; assumption.
    + intros H2; rewrite H2; right; reflexivity.
  - now rewrite <- H; unfold Rpower; rewrite ln_1, !Rmult_0_r; apply Rle_refl.
Qed.

Lemma ln_Rpower : forall x y:R, ln (Rpower x y) = y * ln x.
Proof.
  intros x y.
  unfold Rpower.
  rewrite (ln_exp (y * ln x)).
  reflexivity.
Qed.

Lemma Rlog_pow : forall (x : R) (n : nat), x <> 1 -> 0 < x -> Rlog x (x^n) = INR n.
Proof.
  intros x n H_neq_x_1 H_lt_0_x.
  rewrite <- (Rpower_pow n x H_lt_0_x).
  unfold Rpower.
  unfold Rlog.
  rewrite (ln_exp (INR n * ln x)).
  unfold Rdiv.
  rewrite (Rmult_assoc (INR n) (ln x) (/ln x)).
  rewrite (Rinv_r (ln x) (ln_neq_0 x H_neq_x_1 H_lt_0_x)).
  exact (Rmult_1_r (INR n)).
Qed.

Theorem ln_lt_2 : / 2 < ln 2.
Proof.
  apply Rmult_lt_reg_l with (r := 2).
  - prove_sup0.
  - rewrite Rinv_r.
    + apply exp_lt_inv.
      apply Rle_lt_trans with (1 := exp_le_3).
      change (3 < Rpower 2 (1 + 1)).
      repeat rewrite Rpower_plus; repeat rewrite Rpower_1.
      * now apply (IZR_lt 3 4).
      * prove_sup0.
    + discrR.
Qed.

(*****************************************)
(** * Differentiability of Ln and Rpower *)
(*****************************************)

Theorem limit1_ext :
  forall (f g:R -> R) (D:R -> Prop) (l x:R),
    (forall x:R, D x -> f x = g x) -> limit1_in f D l x -> limit1_in g D l x.
Proof.
  intros f g D l x H; unfold limit1_in, limit_in.
  intros H0 eps H1; case (H0 eps); auto.
  intros x0 [H2 H3]; exists x0; split; auto.
  intros x1 [H4 H5]; rewrite <- H; auto.
Qed.

Theorem limit1_imp :
  forall (f:R -> R) (D D1:R -> Prop) (l x:R),
    (forall x:R, D1 x -> D x) -> limit1_in f D l x -> limit1_in f D1 l x.
Proof.
  intros f D D1 l x H; unfold limit1_in, limit_in.
  intros H0 eps H1; case (H0 eps H1); auto.
  intros alpha [H2 H3]; exists alpha; split; auto.
  intros d [H4 H5]; apply H3; split; auto.
Qed.

Theorem Rinv_Rdiv_depr : forall x y:R, x <> 0 -> y <> 0 -> / (x / y) = y / x.
Proof.
  intros x y _ _.
  apply Rinv_div.
Qed.

#[deprecated(since="8.16",note="Use Rinv_div.")]
Notation Rinv_Rdiv := Rinv_Rdiv_depr.

Theorem Dln : forall y:R, 0 < y -> D_in ln Rinv (fun x:R => 0 < x) y.
Proof.
  intros y Hy; unfold D_in.
  apply limit1_ext with
    (f := fun x:R => / ((exp (ln x) - exp (ln y)) / (ln x - ln y))).
  { intros x [HD1 HD2]; repeat rewrite exp_ln.
    2,3:assumption.
    unfold Rdiv; rewrite Rinv_mult.
    rewrite Rinv_inv.
    apply Rmult_comm. }
  apply limit_inv with
    (f := fun x:R => (exp (ln x) - exp (ln y)) / (ln x - ln y)).
  2:lra.
  apply limit1_imp with
    (f := fun x:R => (fun x:R => (exp x - exp (ln y)) / (x - ln y)) (ln x))
    (D := Dgf (D_x (fun x:R => 0 < x) y) (D_x (fun x:R => True) (ln y)) ln).
  { intros x [H1 H2]; split.
    - split; auto.
    - split; auto.
      red; intros H3; case H2; apply ln_inv; auto. }
  apply limit_comp with
    (l := ln y) (g := fun x:R => (exp x - exp (ln y)) / (x - ln y)) (f := ln).
  { apply ln_continue; auto. }
  assert (H0 := derivable_pt_lim_exp (ln y)); unfold derivable_pt_lim in H0;
    unfold limit1_in; unfold limit_in;
      simpl; unfold Rdist; intros; elim (H0 _ H);
        intros; exists (pos x); split.
  { apply (cond_pos x). }
  intros; pattern y at 3; rewrite <- exp_ln.
  2:assumption.
  pattern x0 at 1; replace x0 with (ln y + (x0 - ln y));
    [ idtac | ring ].
  apply H1.
  { elim H2; intros H3 _; unfold D_x in H3; elim H3; clear H3; intros _ H3;
    apply Rminus_eq_contra; apply (not_eq_sym (A:=R));
    apply H3. }
  elim H2; clear H2; intros _ H2; apply H2.
Qed.

Lemma derivable_pt_lim_ln : forall x:R, 0 < x -> derivable_pt_lim ln x (/ x).
Proof.
  intros; assert (H0 := Dln x H); unfold D_in in H0; unfold limit1_in in H0;
    unfold limit_in in H0; simpl in H0; unfold Rdist in H0;
      unfold derivable_pt_lim; intros; elim (H0 _ H1);
        intros; elim H2; clear H2; intros; set (alp := Rmin x0 (x / 2));
          assert (H4 : 0 < alp).
  { unfold alp; unfold Rmin; case (Rle_dec x0 (x / 2)); intro;unfold Rdiv;lra. }
  exists (mkposreal _ H4); intros; pattern h at 2;
    replace h with (x + h - x); [ idtac | ring ].
  apply H3; split.
  2:{ replace (x + h - x) with h by ring.
      apply Rlt_le_trans with alp;
        [ apply H6 | unfold alp; apply Rmin_l ]. }
  unfold D_x; split.
  2:lra.
  pose proof (Rmin_r _ _ : alp <= _) as H7.
  unfold Rdiv in H7.
  unfold Rabs in H6. simpl in H6.
  destruct (Rcase_abs h) as [Hlt|Hgt];lra.
Qed.

Theorem D_in_imp :
  forall (f g:R -> R) (D D1:R -> Prop) (x:R),
    (forall x:R, D1 x -> D x) -> D_in f g D x -> D_in f g D1 x.
Proof.
  intros f g D D1 x H; unfold D_in.
  intros H0; apply limit1_imp with (D := D_x D x); auto.
  intros x1 [H1 H2]; split; auto.
Qed.

Theorem D_in_ext :
  forall (f g h:R -> R) (D:R -> Prop) (x:R),
    f x = g x -> D_in h f D x -> D_in h g D x.
Proof.
  intros f g h D x H; unfold D_in.
  rewrite H; auto.
Qed.

Theorem Dpower :
  forall y z:R,
    0 < y ->
    D_in (fun x:R => Rpower x z) (fun x:R => z * Rpower x (z - 1)) (
      fun x:R => 0 < x) y.
Proof.
  intros y z H;
    apply D_in_imp with (D := Dgf (fun x:R => 0 < x) (fun x:R => True) ln).
  { intros x H0; repeat split.
    assumption. }
  apply D_in_ext with (f := fun x:R => / x * (z * exp (z * ln x))).
  { unfold Rminus; rewrite Rpower_plus; rewrite Rpower_Ropp;
    rewrite (Rpower_1 _ H); unfold Rpower; ring. }
  apply Dcomp with
    (f := ln)
    (g := fun x:R => exp (z * x))
    (df := Rinv)
    (dg := fun x:R => z * exp (z * x)).
  { apply (Dln _ H). }
  apply D_in_imp with
    (D := Dgf (fun x:R => True) (fun x:R => True) (fun x:R => z * x)).
  { intros x H1; repeat split; auto. }
  apply
    (Dcomp (fun _:R => True) (fun _:R => True) (fun x => z) exp
      (fun x:R => z * x) exp); simpl.
  - apply D_in_ext with (f := fun x:R => z * 1).
    { apply Rmult_1_r. }
    apply (Dmult_const (fun x => True) (fun x => x) (fun x => 1)); apply Dx.
  - assert (H0 := derivable_pt_lim_D_in exp exp (z * ln y)); elim H0; clear H0;
    intros _ H0; apply H0; apply derivable_pt_lim_exp.
Qed.

Theorem derivable_pt_lim_power :
  forall x y:R,
    0 < x -> derivable_pt_lim (fun x => Rpower x y) x (y * Rpower x (y - 1)).
Proof.
  intros x y H.
  unfold Rminus; rewrite Rpower_plus.
  rewrite Rpower_Ropp.
  rewrite Rpower_1; auto.
  rewrite <- Rmult_assoc.
  unfold Rpower.
  apply derivable_pt_lim_comp with (f1 := ln) (f2 := fun x => exp (y * x)).
  - apply derivable_pt_lim_ln; assumption.
  - rewrite (Rmult_comm y).
    apply derivable_pt_lim_comp with (f1 := fun x => y * x) (f2 := exp).
    + pattern y at 2; replace y with (0 * ln x + y * 1).
      * apply derivable_pt_lim_mult with (f1 := fun x:R => y) (f2 := fun x:R => x).
        -- apply derivable_pt_lim_const with (a := y).
        -- apply derivable_pt_lim_id.
      * ring.
    + apply derivable_pt_lim_exp.
Qed.

(* added later. *)

Lemma Rpower_mult_distr :
  forall x y z, 0 < x -> 0 < y ->
   Rpower x z * Rpower y z = Rpower (x * y) z.
intros x y z x0 y0; unfold Rpower.
rewrite <- exp_plus, ln_mult, Rmult_plus_distr_l; auto.
Qed.

Lemma Rlt_Rpower_l a b c: 0 < c -> 0 < a < b -> Rpower a c < Rpower b c.
Proof.
intros c0 [a0 ab]; apply exp_increasing.
now apply Rmult_lt_compat_l; auto; apply ln_increasing; lra.
Qed.

Lemma Rle_Rpower_l a b c: 0 <= c -> 0 < a <= b -> Rpower a c <= Rpower b c.
Proof.
intros [c0 | c0];
 [ | intros; rewrite <- c0, !Rpower_O; [apply Rle_refl | |] ].
- intros [a0 [ab|ab]].
  + now apply Rlt_le, Rlt_Rpower_l;[ | split]; lra.
  + rewrite ab; apply Rle_refl.
- apply Rlt_le_trans with a; tauto.
- tauto.
Qed.

(* arcsinh function *)

Definition arcsinh x := ln (x + sqrt (x ^ 2 + 1)).

Lemma arcsinh_sinh : forall x, arcsinh (sinh x) = x.
intros x; unfold sinh, arcsinh.
assert (Rminus_eq_0 : forall r, r - r = 0) by (intros; ring).
rewrite <- exp_0, <- (Rminus_eq_0 x); unfold Rminus.
rewrite exp_plus.
match goal with |- context[sqrt ?a] =>
  replace a with (((exp x + exp(-x))/2)^2) by field
end.
rewrite sqrt_pow2;
 [|apply Rlt_le, Rmult_lt_0_compat;[apply Rplus_lt_0_compat; apply exp_pos |
                            apply Rinv_0_lt_compat, Rlt_0_2]].
match goal with |- context[ln ?a] => replace a with (exp x) by field end.
rewrite ln_exp; reflexivity.
Qed.

Lemma sinh_arcsinh x : sinh (arcsinh x) = x.
unfold sinh, arcsinh.
assert (cmp : 0 < x + sqrt (x ^ 2 + 1)). {
 destruct (Rle_dec x 0).
 - replace (x ^ 2) with ((-x) ^ 2) by ring.
   assert (sqrt ((- x) ^ 2) < sqrt ((-x)^2+1)). {
     apply sqrt_lt_1_alt.
     split;[apply pow_le | ]; lra.
   }
   pattern x at 1; replace x with (- (sqrt ((- x) ^ 2))).
   + assert (t:= sqrt_pos ((-x)^2)); lra.
   + simpl; rewrite Rmult_1_r, sqrt_square, Ropp_involutive;[reflexivity | lra].
 - apply Rplus_lt_le_0_compat;[apply Rnot_le_gt; assumption | apply sqrt_pos].
}
rewrite exp_ln;[ | assumption].
rewrite exp_Ropp, exp_ln;[ | assumption].
assert (Rmult_minus_distr_r :
         forall x y z, (x - y) * z = x * z - y * z) by (intros; ring).
apply Rminus_diag_uniq; unfold Rdiv; rewrite Rmult_minus_distr_r.
assert (t: forall x y z, x - z = y -> x - y - z = 0);[ | apply t; clear t].
- intros a b c H; rewrite <- H; ring.
- apply Rmult_eq_reg_l with (2 * (x + sqrt (x ^ 2 + 1)));[ |
                                                           apply Rgt_not_eq, Rmult_lt_0_compat;[apply Rlt_0_2 | assumption]].
  field_simplify;[rewrite pow2_sqrt;[field | ] | apply Rgt_not_eq; lra].
  apply Rplus_le_le_0_compat;[simpl; rewrite Rmult_1_r; apply (Rle_0_sqr x)|apply Rlt_le, Rlt_0_1].
Qed.

Lemma derivable_pt_lim_arcsinh :
  forall x, derivable_pt_lim arcsinh x (/sqrt (x ^ 2 + 1)).
intros x; unfold arcsinh.
assert (0 < x + sqrt (x ^ 2 + 1)). {
 destruct (Rle_dec x 0);
  [ | assert (0 < x) by (apply Rnot_le_gt; assumption);
    apply Rplus_lt_le_0_compat; auto; apply sqrt_pos].
 replace (x ^ 2) with ((-x) ^ 2) by ring.
 assert (sqrt ((- x) ^ 2) < sqrt ((-x)^2+1)). {
  apply sqrt_lt_1_alt.
  split;[apply pow_le|]; lra.
 }
 pattern x at 1; replace x with (- (sqrt ((- x) ^ 2))).
 - assert (t:= sqrt_pos ((-x)^2)); lra.
 - simpl; rewrite Rmult_1_r, sqrt_square, Ropp_involutive; auto; lra.
}
assert (0 < x ^ 2 + 1). {
  apply Rplus_le_lt_0_compat;[simpl; rewrite Rmult_1_r; apply Rle_0_sqr|lra].
}
replace (/sqrt (x ^ 2 + 1)) with
 (/(x + sqrt (x ^ 2 + 1)) *
    (1 + (/(2 * sqrt (x ^ 2 + 1)) * (INR 2 * x ^ 1 + 0)))).
2:{ replace (INR 2 * x ^ 1 + 0) with (2 * x) by (simpl; ring).
    replace (1 + / (2 * sqrt (x ^ 2 + 1)) * (2 * x)) with
      (((sqrt (x ^ 2 + 1) + x))/sqrt (x ^ 2 + 1));
      [ | field; apply Rgt_not_eq, sqrt_lt_R0; assumption].
    apply Rmult_eq_reg_l with (x + sqrt (x ^ 2 + 1));
      [ | apply Rgt_not_eq; assumption].
    field.
    split;apply Rgt_not_eq; auto; apply sqrt_lt_R0; assumption. }
apply (derivable_pt_lim_comp (fun x => x + sqrt (x ^ 2 + 1)) ln).
+ apply (derivable_pt_lim_plus).
  * apply derivable_pt_lim_id.
  * apply (derivable_pt_lim_comp (fun x => x ^ 2 + 1) sqrt x).
    -- apply derivable_pt_lim_plus.
       ++ apply derivable_pt_lim_pow.
       ++ apply derivable_pt_lim_const.
    -- apply derivable_pt_lim_sqrt; assumption.
+ apply derivable_pt_lim_ln; assumption.
Qed.

Lemma arcsinh_lt : forall x y, x < y -> arcsinh x < arcsinh y.
intros x y xy.
case (Rle_dec (arcsinh y) (arcsinh x));[ | apply Rnot_le_lt ].
intros abs; case (Rlt_not_le _ _ xy).
rewrite <- (sinh_arcsinh y), <- (sinh_arcsinh x).
destruct abs as [lt | q];[| rewrite q; lra].
apply Rlt_le, sinh_lt; assumption.
Qed.

Lemma arcsinh_le : forall x y, x <= y -> arcsinh x <= arcsinh y.
intros x y [xy | xqy].
- apply Rlt_le, arcsinh_lt; assumption.
- rewrite xqy; apply Rle_refl.
Qed.

Lemma arcsinh_0 : arcsinh 0 = 0.
 unfold arcsinh; rewrite pow_ne_zero, !Rplus_0_l, sqrt_1, ln_1;
  [reflexivity | discriminate].
Qed.
