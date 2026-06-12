open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Filename =
struct
  include String
  let of_string = Fun.id
  let to_string = Fun.id
  let hash: t -> int = Hashtbl.hash
  let of_conflict conflict = conflict.Conflict.range.file
end

module Conflicts =
struct
  type t = Conflict.t list ref [@@deriving yojson]
  let create () = ref []
  let add_conflict l conflict =
    l := conflict :: !l
  let merge l1 l2 = ref (!l1 @ !l2)
end

include ConflictAggregator.MakeGrouped (Filename) (Conflicts)
