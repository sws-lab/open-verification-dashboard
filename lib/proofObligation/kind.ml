type t =
  | Safe [@name "safe"]
  | Warning [@name "warning"]
  | Error [@name "error"]
[@@deriving yojson, show { with_path = false }, ord]

let pp fmt kind =
  Format.fprintf fmt
    (match kind with
    | Safe -> "@{<green>safe"
    | Warning -> "@{<yellow>warning"
    | Error -> "@{<red>error");
  Format.fprintf fmt "@}"

let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Kind"
let yojson_of_t = Utils.string_yojson_of_t yojson_of_t
