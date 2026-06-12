open Ovd_common
open Ovd_checks

type t = [
  | `Safe [@name "safe"]
  | `Warning [@name "warning"]
  | `Error [@name "error"]
  | `Unreached [@name "none"]
]
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = OvdYojson.string_t_of_yojson t_of_yojson "Status"
let yojson_of_t = OvdYojson.string_yojson_of_t yojson_of_t

let of_status (po_status : Status.t) =
  match po_status with
  | `Safe -> `Safe
  | `Warning -> `Warning
  | `Error -> `Error

let meet x y =
  match x, y with
  | `Warning, other
  | other, `Warning -> other
  | `Error, `Error -> `Error
  | `Safe, `Safe -> `Safe
  | `Error, `Safe
  | `Safe, `Error
  | `Unreached, _
  | _, `Unreached -> `Unreached

let join x y =
  match x, y with
  | `Unreached, other
  | other, `Unreached -> other
  | `Error, `Error -> `Error
  | `Safe, `Safe -> `Safe
  | `Error, `Safe
  | `Safe, `Error
  | `Warning, _
  | _, `Warning -> `Warning
