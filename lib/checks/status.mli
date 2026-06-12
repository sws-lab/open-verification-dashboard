module Reachable:
sig
  type t = [
    | `Safe
    | `Warning
    | `Error
  ]
  [@@deriving show, yojson, ord]
end
