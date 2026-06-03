open ProofObligation

type t =
  | Safe [@name "safe"]
  | Warning [@name "warning"]
  | Error [@name "error"]
  | Unreached [@name "none"]
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Status"
let yojson_of_t = Utils.string_yojson_of_t yojson_of_t


(** Join status where  *)
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

(** Join two analyzers status in an optimistic way. *)
let optimistic_join = function
  | Safe, Error | Error, Safe ->
      Unreached
  | Safe, _ | _, Safe -> Safe
  | Warning, Error
  | Error, Warning
  | Error, Error -> Error
  | Warning, _ | _, Warning -> Warning
  | _ -> Unreached

(** Join two analyzers status in a pessimistic way. *)
let pessimistic_join = function
  | Error, Error -> Error
  | Safe, Safe -> Safe
  | Error, Safe
  | Safe, Error
  | Warning, _
  | _, Warning -> Warning
  | Unreached, status | status, Unreached -> status

(* Error > Warning > Safe *)
let severity_join = function
  | Error, _ | _, Error -> Error
  | Warning, _ | _, Warning -> Warning
  | Safe, Safe -> Safe
  | Unreached, _ | _, Unreached -> assert false

