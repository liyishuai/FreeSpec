From ExtLib Require Import StateMonad MonadTrans.
Existing Instance Monad_stateT.
From FreeSpec.Core Require Import Interface Semantics Contract.

Notation instrument Ω i := (stateT Ω (state (semantics i))).

Definition interface_to_instrument `{MayProvide ix i} `(c : contract i Ω)
  : ix ~> instrument Ω ix :=
  fun a e =>
    let* x := lift $ interface_to_state _ e in
    modify (fun ω => gen_witness_update c ω e x);;
    ret x.

Definition to_instrument `{MayProvide ix i} `(c : contract i Ω)
  : impure ix ~> instrument Ω ix :=
  impure_lift $ interface_to_instrument c.

Arguments to_instrument {ix i _ Ω} (c) {α}.

Definition instrument_to_state {i} `(ω : Ω) : instrument Ω i ~> state (semantics i) :=
  fun a instr => fst <$> runStateT instr ω.

Arguments instrument_to_state {i Ω} (ω) {α}.
