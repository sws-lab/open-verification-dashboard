type t = Yojson.Safe.t [@@deriving show]

let compare = Stdlib.compare (* should be OK *)

let t_of_yojson j = j
let yojson_of_t j = j
