open ProofObligation

type t =
  | Safe [@name "safe"]
  | Warning [@name "warning"]
  | Error [@name "error"]
  | Unreached [@name "none"]
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Status"
let yojson_of_t = Utils.string_yojson_of_t yojson_of_t


let join_po_kind (status : t) (po_kind : Kind.t) =
  match (status, po_kind) with
  | Unreached, Safe -> Safe
  | Unreached, Warning -> Warning
  | Unreached, Error -> Error
  | Safe, Safe
  | Warning, Warning
  | Error, Error -> status
  | Error, Warning | Warning, Error -> Warning
  | Safe, Warning | Warning, Safe -> Warning
  | Safe, Error
  | Error, Safe -> Warning

let optimistic_join x y =
  match x, y with
  | Safe, Error | Error, Safe ->
      Unreached
  | Safe, _ | _, Safe -> Safe
  | Warning, Error
  | Error, Warning
  | Error, Error -> Error
  | Warning, _ | _, Warning -> Warning
  | _ -> Unreached

let pessimistic_join x y =
  match x, y with
  | Error, Error -> Error
  | Safe, Safe -> Safe
  | Error, Safe
  | Safe, Error
  | Warning, _
  | _, Warning -> Warning
  | Unreached, status | status, Unreached -> status

let severity_join x y =
  match x, y with
  | Error, _ | _, Error -> Error
  | Warning, _ | _, Warning -> Warning
  | Safe, Safe -> Safe
  | Unreached, _ | _, Unreached -> assert false

