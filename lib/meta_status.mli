include ConflictAggregator.YojsonS

val create : unit -> t
val merge : t -> t -> t


module CategoryMap:
sig
  include ConflictAggregator.YojsonS

  val create : unit -> t
  val merge : t -> t -> t
end
