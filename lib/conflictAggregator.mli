module type S =
sig
  type t

  val add_conflict: t -> Conflict.t -> unit
  val merge: t -> t -> t
end

module type YojsonS =
sig
  type t [@@deriving yojson]

  include S with type t := t
end


module type ConflictGroup =
sig
  include Hashtbl.HashedType

  val to_string: t -> string
  val of_string: string -> t

  val of_conflict: Conflict.t -> t
end

module type GroupS =
sig
  include YojsonS
  val create: unit -> t
end

module MakeGrouped (_: ConflictGroup) (_: GroupS): GroupS
