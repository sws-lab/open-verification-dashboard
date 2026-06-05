type t =
  | Safe
  | Warning
  | Error
  | Unreached
[@@deriving show, yojson]

val of_kind : ProofObligation.Kind.t -> t

(** Join two analyzers status in an optimistic way. *)
val optimistic_join : t -> t -> t

(** Join two analyzers status in a pessimistic way. *)
val pessimistic_join : t -> t -> t
