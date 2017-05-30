Require Import FreeSpec.Program.

Class Eq (T: Type) :=
  { eq (t t': T): Prop
  ; eq_refl (t: T): eq t t
  ; eq_sym (t t': T): eq t t' -> eq t' t
  ; eq_trans (t t' t'': T): eq t t' -> eq t' t'' -> eq t t''
  ; eq_dec (t t': T): {eq t t'}+{~ eq t t'}
  }.

Lemma neq_sym
      {T: Type}
     `{Eq T}
      (t: T)
      (Hneq_sym: ~ eq t t)
  : False.
Proof.
  assert (eq t t) as Heq by (apply eq_refl).
  apply Hneq_sym in Heq.
  exact Heq.
Qed.

Section MAP.
  Local Open Scope prog_scope.

  Variables (Key: Type)
            (key_eq: Eq Key)
            (Value: Type)
            (value_eq: Eq Value).

  Inductive Instruction: Type -> Type :=
  | Read (k: Key)
    : Instruction Value
  | Write (k: Key)
          (v: Value)
    : Instruction unit.

  Definition State := Key -> Value.

  Definition map_program_step
             (A: Type)
             (map: State)
             (i: Instruction A)
    : (A * State) :=
    match i with
    | Read k => (map k, map)
    | Write k v => (tt, fun k' =>
                          if eq_dec k k'
                          then v
                          else map k')
    end.

  Definition MapInterp
             (s: State)
    := mkInterp map_program_step s.


  Definition MapProgram := Program Instruction.

  Definition read_then_write
             (k: Key)
             (v: Value)
    : MapProgram Value :=
    _ <- [Write k v];
    [Read k].

  Lemma write_then_read_1
        (s: State)
        (k: Key)
        (v: Value)
    : MapInterp s <· read_then_write k v = v.
  Proof.
    cbn.
    destruct (eq_dec) as [He|Hne].
    + reflexivity.
    + apply neq_sym in Hne.
      destruct Hne.
  Qed.

  Lemma write_then_read_2
        (s: State)
        (k k': Key)
        (v: Value)
        (Hneq: ~ eq k k')
    : MapInterp s <· (_ <- [Write k' v];
                      [Read k])
       = MapInterp s <· [Read k].
  Proof.
    cbn.
    destruct (eq_dec k' k) as [He|Hne].
    + apply eq_sym in He.
      apply Hneq in He.
      destruct He.
    + reflexivity.
  Qed.

  Section CONTRACT.
    Variable (x: Value).

    Definition never_read_x_requirements
               (A: Type)
               (i: Instruction A) :=
      match i with
      | Read k => True
      | Write k v => ~ eq v x
      end.

    Definition never_read_x_promises
               (A: Type)
               (i: Instruction A)
      : typeret i -> Prop :=
      match i with
      | Read k => fun v => ~ eq v x
      | Write k v => fun x => True
      end.

    Definition never_read_x_contract :=
      {| requirements := never_read_x_requirements
       ; promises     := never_read_x_promises
       |}.
  End CONTRACT.
End MAP.