open Ovd_common

type t = [
  | `Safe [@name "safe"]
  | `Warning [@name "warning"]
  | `Error [@name "error"]
  | `Unreached [@name "none"]
]
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = OvdYojson.string_t_of_yojson t_of_yojson "Status"
let yojson_of_t = OvdYojson.string_yojson_of_t yojson_of_t

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


module Reachable =
struct
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

  let join = join (* this is unused but very neatly reuses the general join, which due to its particular structure has a nice polymorphic type *)
end

let of_reachable (status: Reachable.t) = (status :> t)
