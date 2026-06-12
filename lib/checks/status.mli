type t = [
  | `Safe
  | `Warning
  | `Error
  | `Unreached
]
[@@deriving show, yojson]

(** Join two analyzers status in an optimistic way. *)
val meet : t -> t -> t

(** Join two analyzers status in a pessimistic way. *)
val join : t -> t -> t


module Reachable:
sig
  type t = [
    | `Safe
    | `Warning
    | `Error
  ]
  [@@deriving show, yojson, ord]
end


val of_reachable : Reachable.t -> t
