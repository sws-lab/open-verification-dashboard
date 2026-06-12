type t [@@deriving yojson]

val create : unit -> t
val merge : t -> t -> t

include ConflictAggregator.S with type t := t


module CategoryMap:
sig
  type t [@@deriving yojson]

  val create : unit -> t
  val merge : t -> t -> t

  include ConflictAggregator.S with type t := t
end
