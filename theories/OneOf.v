Require Import Coq.Lists.List.
Require Import Coq.Arith.PeanoNat.
Require Import Omega.
Require Import FreeSpec.Control.Either.

Import ListNotations.
Local Open Scope list_scope.

(* Set Universe Polymorphism. *)

Inductive inhabited : Type.

Polymorphic Fixpoint get
            (set:  list Type)
            (n:    nat)
            {struct n}
  : Type :=
  match n, set with
  | 0, t :: _
    => t
  | S n, _ :: set'
    => get set' n
  | _, _
    => inhabited
  end.

Polymorphic Inductive oneOf
            (set:  list Type)
  : Type :=
| OneOf {t:  Type}
        (n:  nat)
        (H:  get set n = t)
        (x:  t)
  : oneOf set.

Arguments OneOf [set t] (n H x).

Polymorphic Class Contains
            (t:    Type)
            (set:  list Type)
  := { rank:         nat
     ; rank_get_t:   get set rank = t
     ; small_set:    list Type
     ; small_set_lt_p:  forall (m:  nat),
         m < rank -> get small_set m = get set m
     ; small_set_gt_p:  forall (m:  nat),
         rank <= m -> get small_set m = get set (S m)
     }.

Arguments rank (t set) [_].
Arguments small_set (t set) [_].
Arguments rank_get_t (t set) [_].
Arguments small_set_lt_p (t set) [_] (m _).
Arguments small_set_gt_p (t set) [_] (m _).

Polymorphic Instance Contains_head
            (t:    Type)
            (set:  list Type)
  : Contains t (cons t set) :=
  { rank       := 0
  ; small_set  := set
  }.
+ reflexivity.
+ intros m H.
  apply PeanoNat.Nat.nlt_0_r in H.
  destruct H.
+ intros m H.
  reflexivity.
Defined.

Polymorphic Instance Contains_tail
            (t any:  Type)
            (set:    list Type)
            (H:      Contains t set)
  : Contains t (cons any set) :=
  { small_set  := any :: small_set t set
  ; rank       := S (rank t set)
  }.
+ cbn.
  apply rank_get_t.
+ intros m Hlt.
  induction m.
  ++ reflexivity.
  ++ clear IHm.
     cbn.
     apply small_set_lt_p.
     apply Lt.lt_S_n in Hlt.
     exact Hlt.
+ intros m Hgt.
  induction m.
  ++ apply PeanoNat.Nat.nlt_0_r in Hgt.
     destruct Hgt.
  ++ clear IHm.
     apply Le.le_S_n in Hgt.
     apply small_set_gt_p in Hgt.
     assert (R: get (any :: small_set t set) (S m) = get (small_set t set) m)
       by reflexivity.
     rewrite R.
     rewrite Hgt.
     reflexivity.
Defined.

Polymorphic Definition inj
            {t:    Type}
            {set:  list Type} `{Contains t set}
            (x:    t)
  : oneOf set :=
  OneOf (rank t set) (rank_get_t t set) x.

Polymorphic Definition remove
           {set:  list Type}
           (x:    oneOf set)
           (t:    Type) `{Contains t set}
  : Either t (oneOf (small_set t set)).
  refine (
  match x with
  | OneOf n H x
    => _
  end
    ).
  + case_eq (n =? (rank t set));
      intro Heq.
    ++ apply PeanoNat.Nat.eqb_eq in Heq.
       assert (Ht: T = t). {
         rewrite <- H.
         rewrite Heq.
         apply rank_get_t.
       }
       refine (left (eq_rect T id x t Ht)).
    ++ refine (right _).
       case_eq (n <? rank t set).
       +++ intros Hlt.
           apply Nat.ltb_lt in Hlt.
           refine (OneOf n _ x).
           rewrite <- H.
           apply small_set_lt_p.
           apply Hlt.
       +++ intros Hgt.
           apply Nat.ltb_ge in Hgt.
           apply Nat.eqb_neq in Heq.
           assert (Hr: rank t set < n) by omega.
           induction n; [ omega |].
           clear IHn.
           refine (OneOf n _ x).
           rewrite <- H.
           apply small_set_gt_p.
           apply lt_n_Sm_le in Hr.
           exact Hr.
Defined.

Ltac evaluate_exact v :=
  let x := fresh "x" in
  let Heqx := fresh "Heqx" in
  remember v as x eqn:Heqx;
  vm_compute in Heqx;
  match type of Heqx with
  | x = ?ev => exact ev
  end.

Ltac inj v :=
  match goal with
  | [ |- oneOf ?set]
    => evaluate_exact (@inj _ set _ v)
  end.