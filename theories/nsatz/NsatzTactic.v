(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

(*
 Tactic nsatz: proofs of polynomials equalities in an integral domain
(commutative ring without zero divisor).

Examples: see test-suite/success/Nsatz.v

Reification is done using type classes, defined in Ncring_tac.v

*)

From Stdlib Require Import List ListTactics.
From Stdlib Require Import BinPos BinNat BinInt Nnat.
From Stdlib Require Export Bool.
From Stdlib Require Export Integral_domain.

Declare ML Module "rocq-runtime.plugins.nsatz_core".
Declare ML Module "rocq-runtime.plugins.nsatz".

Section nsatz1.

Context {R:Type}`{Rid:Integral_domain R}.

Lemma psos_r1b: forall x y:R, x - y == 0 -> x == y.
intros x y H; setoid_replace x with ((x - y) + y); simpl;
  [setoid_rewrite H | idtac]; simpl.
- cring.
- cring.
Qed.

Lemma psos_r1: forall x y, x == y -> x - y == 0.
intros x y H; simpl; setoid_rewrite H; simpl; cring.
Qed.

Lemma nsatzR_diff: forall x y:R, not (x == y) -> not (x - y == 0).
intros.
intro; apply H.
simpl; setoid_replace x with ((x - y) + y).
- simpl.
  setoid_rewrite H0.
  simpl; cring.
- simpl. simpl; cring.
Qed.

(* adpatation du code de Benjamin aux setoides *)
Export Ring_polynom.
Export InitialRing.

Definition PolZ := Pol Z.
Definition PEZ := PExpr Z.

Definition P0Z : PolZ := P0 (C:=Z) 0%Z.

Definition PolZadd : PolZ -> PolZ -> PolZ :=
  @Padd  Z 0%Z Z.add Z.eqb.

Definition PolZmul : PolZ -> PolZ -> PolZ :=
  @Pmul  Z 0%Z 1%Z Z.add Z.mul Z.eqb.

Definition PolZeq := @Peq Z Z.eqb.

Definition norm :=
  @norm_aux Z 0%Z 1%Z Z.add Z.mul Z.sub Z.opp Z.eqb.

Fixpoint mult_l (la : list PEZ) (lp: list PolZ) : PolZ :=
 match la, lp with
 | a::la, p::lp => PolZadd (PolZmul (norm a) p) (mult_l la lp)
 | _, _ => P0Z
 end.

Fixpoint compute_list (lla: list (list PEZ)) (lp:list PolZ) :=
 match lla with
 | List.nil => lp
 | la::lla => compute_list lla ((mult_l la lp)::lp)
 end.

Definition check (lpe:list PEZ) (qe:PEZ) (certif: list (list PEZ) * list PEZ) :=
 let (lla, lq) := certif in
 let lp := List.map norm lpe in
 PolZeq (norm qe) (mult_l lq (compute_list lla lp)).


(* Correction *)
Definition PhiR : list R -> PolZ -> R :=
  (Pphi ring0 add mul
    (InitialRing.gen_phiZ ring0 ring1 add mul opp)).

Definition PEevalR : list R -> PEZ -> R :=
   PEeval ring0 ring1 add mul sub opp
    (gen_phiZ ring0 ring1 add mul opp)
         N.to_nat pow.

Lemma P0Z_correct : forall l, PhiR l P0Z = 0.
Proof. trivial. Qed.

Lemma Rext: ring_eq_ext add mul opp _==_.
Proof.
constructor; solve_proper.
Qed.

Lemma Rset : Setoid_Theory R _==_.
apply ring_setoid.
Qed.

Definition Rtheory:ring_theory ring0 ring1 add mul sub opp _==_.
apply mk_rt.
- apply ring_add_0_l.
- apply ring_add_comm.
- apply ring_add_assoc.
- apply ring_mul_1_l.
- apply cring_mul_comm.
- apply ring_mul_assoc.
- apply ring_distr_l.
- apply ring_sub_def.
- apply ring_opp_def.
Defined.

Lemma PolZadd_correct : forall P' P l,
  PhiR l (PolZadd P P') == ((PhiR l P) + (PhiR l P')).
Proof.
unfold PolZadd, PhiR. intros. simpl.
 refine (Padd_ok Rset Rext (Rth_ARth Rset Rext Rtheory)
           (gen_phiZ_morph Rset Rext Rtheory) _ _ _).
Qed.

Lemma PolZmul_correct : forall P P' l,
  PhiR l (PolZmul P P') == ((PhiR l P) * (PhiR l P')).
Proof.
unfold PolZmul, PhiR. intros.
 refine (Pmul_ok Rset Rext (Rth_ARth Rset Rext Rtheory)
           (gen_phiZ_morph Rset Rext Rtheory) _ _ _).
Qed.

Lemma R_power_theory
     : Ring_theory.power_theory ring1 mul _==_ N.to_nat pow.
apply Ring_theory.mkpow_th. unfold pow. intros. rewrite Nnat.N2Nat.id.
reflexivity. Qed.

Lemma norm_correct :
  forall (l : list R) (pe : PEZ), PEevalR l pe == PhiR l (norm pe).
Proof.
 intros;apply (norm_aux_spec Rset Rext (Rth_ARth Rset Rext Rtheory)
           (gen_phiZ_morph Rset Rext Rtheory) R_power_theory).
Qed.

Lemma PolZeq_correct : forall P P' l,
  PolZeq P P' = true ->
  PhiR l P == PhiR l P'.
Proof.
 intros;apply
   (Peq_ok Rset Rext (gen_phiZ_morph Rset Rext Rtheory));trivial.
Qed.

Fixpoint Cond0 (A:Type) (Interp:A->R) (l:list A) : Prop :=
  match l with
  | List.nil => True
  | a::l => Interp a == 0 /\ Cond0 A Interp l
  end.

Lemma mult_l_correct : forall l la lp,
  Cond0 PolZ (PhiR l) lp ->
  PhiR l (mult_l la lp) == 0.
Proof.
  induction la;simpl;intros.
  - cring.
  - destruct lp;trivial.
    + simpl. cring.
    + simpl in H;destruct H.
      rewrite  PolZadd_correct.
      simpl. rewrite PolZmul_correct. simpl. rewrite  H.
      rewrite IHla.
      * cring.
      * trivial.
Qed.

Lemma compute_list_correct : forall l lla lp,
  Cond0 PolZ (PhiR l) lp ->
  Cond0 PolZ (PhiR l) (compute_list lla lp).
Proof.
 induction lla;simpl;intros;trivial.
 apply IHlla;simpl;split;trivial.
 apply mult_l_correct;trivial.
Qed.

Lemma check_correct :
  forall l lpe qe certif,
    check lpe qe certif = true ->
    Cond0 PEZ (PEevalR l) lpe ->
    PEevalR l qe == 0.
Proof.
 unfold check;intros l lpe qe (lla, lq) H2 H1.
 apply PolZeq_correct with (l:=l) in H2.
 rewrite norm_correct, H2.
 apply mult_l_correct.
 apply compute_list_correct.
 clear H2 lq lla qe;induction lpe;simpl;trivial.
 simpl in H1;destruct H1.
 rewrite <- norm_correct;auto.
Qed.

(* fin *)

Definition R2:= 1 + 1.

Fixpoint IPR p {struct p}: R :=
  match p with
    xH => ring1
  | xO xH => 1+1
  | xO p1 => R2*(IPR p1)
  | xI xH => 1+(1+1)
  | xI p1 => 1+(R2*(IPR p1))
  end.

Definition IZR1 z :=
  match z with Z0 => 0
             | Zpos p => IPR p
             | Zneg p => -(IPR p)
  end.

Fixpoint interpret3 t fv {struct t}: R :=
  match t with
  | (PEadd t1 t2) =>
       let v1  := interpret3 t1 fv in
       let v2  := interpret3 t2 fv in (v1 + v2)
  | (PEmul t1 t2) =>
       let v1  := interpret3 t1 fv in
       let v2  := interpret3 t2 fv in (v1 * v2)
  | (PEsub t1 t2) =>
       let v1  := interpret3 t1 fv in
       let v2  := interpret3 t2 fv in (v1 - v2)
  | (PEopp t1) =>
       let v1  := interpret3 t1 fv in (-v1)
  | (PEpow t1 t2) =>
       let v1  := interpret3 t1 fv in pow v1 (N.to_nat t2)
  | (PEc t1) => (IZR1 t1)
  | PEO => 0
  | PEI => 1
  | (PEX _ n) => List.nth (pred (Pos.to_nat n)) fv 0
  end.


End nsatz1.

Ltac equalities_to_goal cr :=
  match goal with
  |  H: ((*unification*)_ ?x ?y) |- _ =>
      generalize (@psos_r1 _ _ _ _ _ _ _ _ _ _ cr x y H); clear H
  end.

(* lp est incluse dans fv. La met en tete. *)

Ltac parametres_en_tete fv lp :=
    match fv with
     | (@nil _)          => lp
     | (@cons _ ?x ?fv1) =>
       let res := AddFvTail x lp in
         parametres_en_tete fv1 res
    end.

Ltac append1 a l :=
 match l with
 | (@nil _)     => constr:(cons a l)
 | (cons ?x ?l) => let l' := append1 a l in constr:(cons x l')
 end.

Ltac rev l :=
  match l with
   |(@nil _)      => l
   | (cons ?x ?l) => let l' := rev l in append1 x l'
  end.

Ltac nsatz_call_n info nparam p rr lp kont :=
(*  idtac "Trying power: " rr;*)
  let ll := constr:(PEc info :: PEc nparam :: PEpow p rr :: lp) in
(*  idtac "calcul...";*)
  nsatz_compute ll;
(*  idtac "done";*)
  match goal with
  | |- (?c::PEpow _ ?r::?lq0)::?lci0 = _ -> _ =>
    intros _;
    let lci := fresh "lci" in
    set (lci:=lci0);
    let lq := fresh "lq" in
    set (lq:=lq0);
    kont c rr lq lci
  end.

Ltac nsatz_call radicalmax info nparam p lp kont :=
  let rec try_n n :=
    lazymatch n with
    | 0%N => fail
    | _ =>
        (let r := eval compute in (N.sub radicalmax (N.pred n)) in
         nsatz_call_n info nparam p r lp kont) ||
         let n' := eval compute in (N.pred n) in try_n n'
    end in
  try_n radicalmax.


Ltac lterm_goal g :=
  match g with
    ?b1 == ?b2 => constr:(b1::b2::nil)
  | ?b1 == ?b2 -> ?g => let l := lterm_goal g in constr:(b1::b2::l)
  end.

Ltac reify_goal ro l le lb:=
  match le with
     nil => idtac
   | ?e::?le1 =>
        match lb with
         ?b::?lb1 => (* idtac "b="; idtac b;*)
           let x := fresh "B" in
           set (x:= b) at 1;
           change x with (interpret3(Ro:=ro) e l);
           clear x;
           reify_goal ro l le1 lb1
        end
  end.

Ltac get_lpol g :=
  match g with
  (interpret3 ?p _) == _ => constr:(p::nil)
  | (interpret3 ?p _) == _ -> ?g =>
       let l := get_lpol g in constr:(p::l)
  end.

(** We only make use of [discrR] if [nsatz] support for reals is
    loaded.  To do this, we redefine this tactic in RNsatz.v to make
    use of real discrimination. *)
Ltac nsatz_internal_discrR := idtac.

(** We only make use of [lia] if [nsatz] support for integers is
   loaded.  To do this, we redefine this tactic in ZNsatz.v to make use of
   linear-integer-arithmetic solving. *)
Ltac nsatz_internal_lia := idtac.


Ltac nsatz_generic di radicalmax info lparam lvar :=
 let ro := lazymatch type of di with Integral_domain(Ro:=?ro) => ro end in
 let rr := lazymatch type of di with Integral_domain(Rr:=?rr) => rr end in
 let cr := lazymatch type of di with Integral_domain(Rcr:=?cr) => cr end in
 let r0 := lazymatch type of di with Integral_domain(ring0:=?r0) => r0 end in
 let req := lazymatch type of di with Integral_domain(ring_eq:=?req) => req end in
 let nparam := eval compute in (Z.of_nat (List.length lparam)) in
 match goal with
  |- ?g => let lb := lterm_goal g in
     match (lazymatch lvar with
              |(@nil _) =>
                 lazymatch lparam with
                 |(@nil _) =>
                    let r := list_reifyl0 rr lb in
                    r
                   |_ =>
                     let reif := list_reifyl0 rr lb in
                     match reif with
                       |(?fv, ?le) =>
                         let fv := parametres_en_tete fv lparam in
                           (* we reify a second time, with the good order
                              for variables *)
                         list_reifyl rr fv lb
                     end
                  end
              |_ =>
                 let fv := parametres_en_tete lvar lparam in
                list_reifyl rr fv lb
            end) with
          |(?fv, ?le) =>
            reify_goal ro fv le lb ;
            match goal with
                   |- ?g =>
                       let lp := get_lpol g in
                       let lpol := eval compute in (List.rev lp) in
                       intros;

  let SplitPolyList kont :=
    match lpol with
    | ?p2::?lp2 => kont p2 lp2
    | _ => idtac "polynomial not in the ideal"
    end in

  SplitPolyList ltac:(fun p lp =>
    let p21 := fresh "p21" in
    let lp21 := fresh "lp21" in
    set (p21:=p) ;
    set (lp21:=lp);
(*    idtac "nparam:"; idtac nparam; idtac "p:"; idtac p; idtac "lp:"; idtac lp; *)
    nsatz_call radicalmax info nparam p lp ltac:(fun c r lq lci =>
      let q := fresh "q" in
      set (q := PEmul c (PEpow p21 r));
      let Hg := fresh "Hg" in
      assert (Hg:check lp21 q (lci,lq) = true);
      [ (vm_compute;reflexivity) || idtac "invalid nsatz certificate"
      | let Hg2 := fresh "Hg" in
            assert (Hg2: equality (Equality:=req) (interpret3 (Ro:=ro) q fv) r0);
        [ (*simpl*) idtac;
          generalize (@check_correct _ _ _ _ _ _ _ _ _ _ cr fv lp21 q (lci,lq) Hg);
          let cc := fresh "H" in
             (*simpl*) idtac; intro cc; apply cc; clear cc;
          (*simpl*) idtac;
          repeat (split;[assumption|idtac]); exact I
        | (*simpl in Hg2;*) (*simpl*) idtac;
          apply (@Rintegral_domain_pow _ _ _ _ _ _ _ _ _ _ _ di (interpret3 (Ro:=ro) c fv) _ (N.to_nat r));
          (*simpl*) idtac;
            try apply integral_domain_one_zero with (Integral_domain:=di);
            try apply integral_domain_minus_one_zero with (Rid:=di);
            try trivial;
            try exact (integral_domain_one_zero(Integral_domain:=di));
            try exact (integral_domain_minus_one_zero(Rid:=di))
          || (solve [simpl; unfold R2, equality, eq_notation, addition, add_notation,
                     one, one_notation, multiplication, mul_notation, zero, zero_notation;
                     nsatz_internal_discrR || nsatz_internal_lia ])
          || ((*simpl*) idtac) || idtac "could not prove discrimination result"
        ]
      ]
)
)
end end end .

Ltac nsatz_guess_domain :=
  let eq := lazymatch goal with | |- ?eq _ _ => eq end in
  let di := lazymatch open_constr:(ltac:(typeclasses eauto):Integral_domain (ring_eq:=eq)) with?di => di end in
  let __ := match di with _ => assert_fails (is_evar di) end in
  di.

Ltac nsatz_default :=
  intros;
  let di := nsatz_guess_domain in
  let r := lazymatch type of di with Integral_domain(R:=?r) => r end in
  let cr := lazymatch type of di with Integral_domain(Rcr:=?cr) => cr end in
  try apply (@psos_r1b _ _ _ _ _ _ _ _ _ _ cr);
  repeat equalities_to_goal cr;
  nsatz_generic di 6%N 1%Z (@nil r) (@nil r).

Tactic Notation "nsatz" := nsatz_default.

Tactic Notation "nsatz" "with"
 "radicalmax" ":=" constr(radicalmax)
 "strategy" ":=" constr(info)
 "parameters" ":=" constr(lparam)
 "variables" ":=" constr(lvar):=
  intros;
  let di := nsatz_guess_domain in
  let r := lazymatch type of di with Integral_domain(R:=?r) => r end in
  let cr := lazymatch type of di with Integral_domain(Rcr:=?cr) => cr end in
  try apply (@psos_r1b _ _ _ _ _ _ _ _ _ _ cr);
  repeat equalities_to_goal cr;
  nsatz_generic di radicalmax info lparam lvar.
