open Ovd_checks

include ConflictAggregator.YojsonS

val create: unit -> t
val add: t -> Status.t -> Status.t -> unit

val optimistic_status: t -> Status.t option
val pessimistic_status: t -> Status.t option

val selectivity1: t -> float option
val selectivity2: t -> float option
val joint_selectivity: t -> float option
val alignment: t -> float option
