type t = [
  | `Safe
  | `Warning
  | `Error
  | `Unreached
]
[@@deriving show, yojson]

val of_status : Ovd_checks.Status.t -> t

(** Join two analyzers status in an optimistic way. *)
val meet : t -> t -> t

(** Join two analyzers status in a pessimistic way. *)
val join : t -> t -> t
