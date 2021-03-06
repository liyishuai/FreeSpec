type 'a t = { next_key : Uint63.t ref; table : (Uint63.t, 'a) Hashtbl.t }

let unwrap : Constr.t -> Uint63.t = fun x ->
  match Constr.kind x with
  | Constr.Int x -> x
  | _ -> assert false

let create _ =
  { next_key = ref Uint63.zero; table = Hashtbl.create ~random:false 100 }

let add t trm = begin
  let r = t.next_key in
  let k = !r in
  r := Uint63.add k Uint63.one;
  Hashtbl.add t.table k trm;
  Constr.of_kind(Int k)
end

let remove t k = Hashtbl.remove t.table (unwrap k)
let find t k = Hashtbl.find t.table (unwrap k)
let replace t k = Hashtbl.replace t.table (unwrap k)
