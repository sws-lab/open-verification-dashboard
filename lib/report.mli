type t [@@deriving yojson_of]

val create : string -> string -> t

include ConflictAggregator.S with type t := t
