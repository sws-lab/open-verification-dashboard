type t [@@deriving ord, yojson]

val default: t

val pp : Format.formatter -> t -> unit

val reset : unit -> unit
