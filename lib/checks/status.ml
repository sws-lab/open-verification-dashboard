open Ovd_common

type t = [
  | `Safe [@name "safe"]
  | `Warning [@name "warning"]
  | `Error [@name "error"]
]
[@@deriving yojson, show { with_path = false }, ord]

let pp fmt status =
  Format.fprintf fmt
    (match status with
    | `Safe -> "@{<green>safe"
    | `Warning -> "@{<yellow>warning"
    | `Error -> "@{<red>error");
  Format.fprintf fmt "@}"

let t_of_yojson = OvdYojson.string_t_of_yojson t_of_yojson "Status"
let yojson_of_t = OvdYojson.string_yojson_of_t yojson_of_t
