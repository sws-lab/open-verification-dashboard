module type S =
sig
  type t

  val add_conflict: t -> Conflict.t -> unit
end

module type YojsonS =
sig
  type t [@@deriving yojson]

  include S with type t := t
end
