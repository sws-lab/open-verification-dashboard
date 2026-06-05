type t =
  | Safe
  | Warning
  | Error
  | Unreached
[@@deriving show, yojson]

(** Join status where  *)
val join_po_kind : t -> ProofObligation.Kind.t -> t

(** Join two analyzers status in an optimistic way. *)
val optimistic_join : t -> t -> t

(** Join two analyzers status in a pessimistic way. *)
val pessimistic_join : t -> t -> t
