type t [@@deriving yojson_of]

val create: unit -> t
val add: t -> Status.t -> Status.t -> unit

val selectivity1: t -> float option
val selectivity2: t -> float option
val joint_selectivity: t -> float option
val alignment: t -> float option
