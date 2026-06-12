type t [@@deriving yojson]

val create: unit -> t

include ConflictAggregator.S with type t := t
