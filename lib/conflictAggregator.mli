module type S =
sig
  type t

  val add_conflict: t -> Conflict.t -> unit
end
