(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

(** * Uint63 numbers defines indeed a cyclic structure : Z/(2^63)Z *)

(**
Author: Arnaud Spiwack (+ Pierre Letouzey)
*)
From Stdlib Require Import CyclicAxioms.
From Stdlib Require Export ZArith.
From Stdlib Require Export Uint63.
Import Zpow_facts.
Import Utf8.
Import Lia.

#[local] Open Scope uint63_scope.
(** {2 Operators } **)

Definition Pdigits := Eval compute in P_of_succ_nat (size - 1).

Fixpoint positive_to_int_rec (n:nat) (p:positive) :=
  match n, p with
  | O, _ => (Npos p, 0)
  | S n, xH => (0%N, 1)
  | S n, xO p =>
    let (N,i) := positive_to_int_rec n p in
    (N, i << 1)
  | S n, xI p =>
    let (N,i) := positive_to_int_rec n p in
    (N, (i << 1) + 1)
  end.

Definition positive_to_int := positive_to_int_rec size.

Definition mulc_WW x y :=
  let (h, l) := mulc x y in
  if is_zero h then
    if is_zero l then W0
    else WW h l
  else WW h l.
Notation "n '*c' m" := (mulc_WW n m) (at level 40, no associativity) : uint63_scope.

Definition pos_mod p x :=
  if p <=? digits then
    let p := digits - p in
    (x << p) >> p
  else x.

Notation pos_mod_int := pos_mod.

Import ZnZ.

#[global]
Instance int_ops : ZnZ.Ops int :=
{|
 digits      := Pdigits; (* number of digits *)
 zdigits     := Uint63Axioms.digits; (* number of digits *)
 to_Z        := Uint63Axioms.to_Z; (* conversion to Z *)
 of_pos      := positive_to_int; (* positive -> N*int63 :  p => N,i
                                      where p = N*2^31+phi i *)
 head0       := Uint63.head0;  (* number of head 0 *)
 tail0       := Uint63.tail0;  (* number of tail 0 *)
 zero        := 0;
 one         := 1;
 minus_one   := Uint63Axioms.max_int;
 compare     := Uint63.compare;
 eq0         := Uint63Axioms.is_zero;
 opp_c       := Uint63.oppc;
 opp         := Uint63.opp;
 opp_carry   := Uint63.oppcarry;
 succ_c      := Uint63.succc;
 add_c       := Uint63.addc;
 add_carry_c := Uint63.addcarryc;
 succ        := Uint63.succ;
 add         := Uint63.add;
 add_carry   := Uint63Axioms.addcarry;
 pred_c      := Uint63.predc;
 sub_c       := Uint63.subc;
 sub_carry_c := Uint63.subcarryc;
 pred        := Uint63.pred;
 sub         := Uint63.sub;
 sub_carry   := Uint63.subcarry;
 mul_c       := mulc_WW;
 mul         := Uint63.mul;
 square_c    := fun x => mulc_WW x x;
 div21       := diveucl_21;
 div_gt      := diveucl; (* this is supposed to be the special case of
                         division a/b where a > b *)
 div         := diveucl;
 modulo_gt   := Uint63.mod;
 modulo      := Uint63.mod;
 gcd_gt      := Uint63.gcd;
 gcd         := Uint63.gcd;
 add_mul_div := Uint63.addmuldiv;
 pos_mod     := pos_mod_int;
 is_even     := Uint63Axioms.is_even;
 sqrt2       := Uint63.sqrt2;
 sqrt        := Uint63.sqrt;
 ZnZ.lor     := Uint63.lor;
 ZnZ.land    := Uint63.land;
 ZnZ.lxor    := Uint63.lxor
|}.

#[local] Open Scope Z_scope.

Lemma is_zero_spec_aux : forall x : int, is_zero x = true -> φ x = 0%Z.
Proof.
 intros x;rewrite is_zero_spec;intros H;rewrite H;trivial.
Qed.

Lemma positive_to_int_spec :
  forall p : positive,
    Zpos p =
      Z_of_N (fst (positive_to_int p)) * wB + to_Z (snd (positive_to_int p)).
Proof.
 assert (H: (wB <= wB) -> forall p : positive,
  Zpos p = Z_of_N (fst (positive_to_int p)) * wB + φ (snd (positive_to_int p)) /\
  φ (snd (positive_to_int p)) < wB).
  2: intros p; case (H (Z.le_refl wB) p); auto.
 unfold positive_to_int, wB at 1 3 4.
 elim size.
 - intros _ p; simpl;
     rewrite to_Z_0, Pmult_1_r; split; auto with zarith; apply refl_equal.
 - intros n; rewrite inj_S; unfold Z.succ; rewrite Zpower_exp, Z.pow_1_r; auto with zarith.
   intros IH Hle p.
   assert (F1: 2 ^ Z_of_nat n <= wB); auto with zarith.
   assert (0 <= 2 ^ Z_of_nat n); auto with zarith.
   case p; simpl.
   + intros p1.
     generalize (IH F1 p1); case positive_to_int_rec; simpl.
     intros n1 i (H1,H2).
     rewrite Zpos_xI, H1.
     replace (φ (i << 1 + 1)) with (φ i * 2 + 1).
     * split; auto with zarith; ring.
     * rewrite add_spec, lsl_spec, Zplus_mod_idemp_l, to_Z_1, Z.pow_1_r, Zmod_small; auto.
       case (to_Z_bounded i); split; auto with zarith.
   + intros p1.
     generalize (IH F1 p1); case positive_to_int_rec; simpl.
     intros n1 i (H1,H2).
     rewrite Zpos_xO, H1.
     replace (φ (i << 1)) with (φ i * 2).
     * split; auto with zarith; ring.
     * rewrite lsl_spec, to_Z_1, Z.pow_1_r, Zmod_small; auto.
       case (to_Z_bounded i); split; auto with zarith.
   + rewrite to_Z_1; assert (0 < 2^ Z_of_nat n); auto with zarith.
Qed.

Lemma mulc_WW_spec :
   forall x y, Φ ( x *c y ) = φ x * φ y.
Proof.
 intros x y;unfold mulc_WW.
 generalize (mulc_spec x y);destruct (mulc x y);simpl;intros Heq;rewrite Heq.
 case_eq (is_zero i);intros;trivial.
 apply is_zero_spec in H;rewrite H, to_Z_0.
 case_eq (is_zero i0);intros;trivial.
 apply is_zero_spec in H0;rewrite H0, to_Z_0, Zmult_comm;trivial.
Qed.

Lemma squarec_spec :
  forall x,
    Φ(x *c x) = φ x * φ x.
Proof (fun x => mulc_WW_spec x x).

Lemma diveucl_spec_aux : forall a b, 0 < φ b ->
  let (q,r) := diveucl a b in
  φ a = φ q * φ b + φ r /\
  0 <= φ r < φ b.
Proof.
 intros a b H;assert (W:= diveucl_spec a b).
 assert (φ b>0) by (auto with zarith).
 generalize (Z_div_mod φ a φ b H0).
 destruct (diveucl a b);destruct (Z.div_eucl φ a φ b).
 inversion W;rewrite Zmult_comm;trivial.
Qed.

Lemma shift_unshift_mod_2 : forall n p a, 0 <= p <= n ->
   ((a * 2 ^ (n - p)) mod (2^n) / 2 ^ (n - p)) mod (2^n) =
   a mod 2 ^ p.
 Proof.
   intros n p a H.
   rewrite Zmod_small.
   - rewrite Zmod_eq by auto with zarith.
     unfold Zminus at 1.
     rewrite Zdiv.Z_div_plus_full_l by auto with zarith.
     replace (2 ^ n) with (2 ^ (n - p) * 2 ^ p) by (rewrite <- Zpower_exp; [ f_equal | | ]; lia).
     rewrite <- Zdiv_Zdiv, Z_div_mult by auto with zarith.
     rewrite (Zmult_comm (2^(n-p))), Zmult_assoc.
     rewrite Zopp_mult_distr_l.
     rewrite Z_div_mult by auto with zarith.
     symmetry; apply Zmod_eq; auto with zarith.
   - remember (a * 2 ^ (n - p)) as b.
     destruct (Z_mod_lt b (2^n)); auto with zarith.
     split.
     + apply Z_div_pos; auto with zarith.
     + apply Zdiv_lt_upper_bound; auto with zarith.
       apply Z.lt_le_trans with (2^n); auto with zarith.
       generalize (pow2_pos (n - p)); nia.
 Qed.

Lemma div_le_0 : forall p x, 0 <= x -> 0 <= x / 2 ^ p.
 Proof.
  intros p x Hle;destruct (Z_le_gt_dec 0 p).
  - apply  Zdiv_le_lower_bound;auto with zarith.
  - replace (2^p) with 0.
    + destruct x;compute;intro;discriminate.
    + destruct p;trivial;discriminate.
 Qed.

Lemma div_lt : forall p x y, 0 <= x < y -> x / 2^p < y.
 Proof.
  intros p x y H;destruct (Z_le_gt_dec 0 p).
  - apply Zdiv_lt_upper_bound;auto with zarith.
    apply Z.lt_le_trans with y;auto with zarith.
    rewrite <- (Zmult_1_r y);apply Zmult_le_compat;auto with zarith.
  - replace (2^p) with 0.
    + destruct x;change (0<y);auto with zarith.
    + destruct p;trivial;discriminate.
 Qed.

Lemma P (A B C: Prop) :
  A → (B → C) → (A → B) → C.
Proof. tauto. Qed.

Lemma shift_unshift_mod_3:
  forall n p a : Z,
  0 <= p <= n ->
  (a * 2 ^ (n - p)) mod 2 ^ n / 2 ^ (n - p) = a mod 2 ^ p.
Proof.
 intros;rewrite <- (shift_unshift_mod_2 n p a);[ | auto with zarith].
 symmetry;apply Zmod_small.
 generalize (a * 2 ^ (n - p));intros w.
 generalize (2 ^ (n - p)) (pow2_pos (n - p)); intros x; apply P.
 - lia.
 - intros hx.
   generalize (2 ^ n) (pow2_pos n); intros y; apply P.
   + lia.
   + intros hy.
     elim_div. intros q r. apply P.
     * lia.
     * elim_div. intros z t. refine (P _ _ _ _ _).
       -- lia.
       -- intros [ ? [ ht | ] ]; [ | lia ]; subst w.
          intros [ ? [ hr | ] ]; [ | lia ]; subst t.
          nia.
Qed.

Lemma pos_mod_spec w p : φ(pos_mod p w) = φ(w) mod (2 ^ φ(p)).
Proof.
  simpl. unfold pos_mod_int.
  assert (W:=to_Z_bounded p);assert (W':=to_Z_bounded Uint63Axioms.digits);assert (W'' := to_Z_bounded w).
  case lebP; intros hle.
  2: {
    symmetry; apply Zmod_small.
    assert (2 ^ φ Uint63Axioms.digits < 2 ^ φ p); [ apply Zpower_lt_monotone; auto with zarith | ].
    change wB with (2 ^ φ Uint63Axioms.digits) in *; auto with zarith. }
  rewrite <- (shift_unshift_mod_3 φ Uint63Axioms.digits φ p φ w) by auto with zarith.
  replace (φ Uint63Axioms.digits - φ p) with (φ (Uint63Axioms.digits - p)) by (rewrite sub_spec, Zmod_small; auto with zarith).
  rewrite lsr_spec, lsl_spec; reflexivity.
Qed.

(** {2 Specification and proof} **)
#[global] Instance int_specs : ZnZ.Specs int_ops := {
    spec_to_Z   := to_Z_bounded;
    spec_of_pos := positive_to_int_spec;
    spec_zdigits := refl_equal _;
    spec_more_than_1_digit:= refl_equal _;
    spec_0 := to_Z_0;
    spec_1 := to_Z_1;
    spec_m1 := refl_equal _;
    spec_compare := compare_spec;
    spec_eq0 := is_zero_spec_aux;
    spec_opp_c := oppc_spec;
    spec_opp := opp_spec;
    spec_opp_carry := oppcarry_spec;
    spec_succ_c := succc_spec;
    spec_add_c := addc_spec;
    spec_add_carry_c := addcarryc_spec;
    spec_succ := succ_spec;
    spec_add := add_spec;
    spec_add_carry := addcarry_spec;
    spec_pred_c := predc_spec;
    spec_sub_c := subc_spec;
    spec_sub_carry_c := subcarryc_spec;
    spec_pred := pred_spec;
    spec_sub := sub_spec;
    spec_sub_carry := subcarry_spec;
    spec_mul_c := mulc_WW_spec;
    spec_mul := mul_spec;
    spec_square_c := squarec_spec;
    spec_div21 := diveucl_21_spec_aux;
    spec_div_gt := fun a b _ => diveucl_spec_aux a b;
    spec_div := diveucl_spec_aux;
    spec_modulo_gt := fun a b _ _ => mod_spec a b;
    spec_modulo := fun a b _ => mod_spec a b;
    spec_gcd_gt := fun a b _ => gcd_spec a b;
    spec_gcd := gcd_spec;
    spec_head00 := head00_spec;
    spec_head0 := head0_spec;
    spec_tail00 := tail00_spec;
    spec_tail0 := tail0_spec;
    spec_add_mul_div := addmuldiv_spec;
    spec_pos_mod := pos_mod_spec;
    spec_is_even := is_even_spec;
    spec_sqrt2 := sqrt2_spec;
    spec_sqrt := sqrt_spec;
    spec_land := land_spec';
    spec_lor := lor_spec';
    spec_lxor := lxor_spec' }.



Module Uint63Cyclic <: CyclicType.
  Definition t := int.
  Definition ops := int_ops.
  Definition specs := int_specs.
End Uint63Cyclic.
