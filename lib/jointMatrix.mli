type t [@@deriving yojson_of]

val create: unit -> t
val add: t -> Status.t -> Status.t -> unit
