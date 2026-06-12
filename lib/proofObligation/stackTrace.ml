open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = int [@@deriving yojson_of, ord]

let default = 0

let pp fmt stack_trace = Format.fprintf fmt "Stack trace: %d" stack_trace

module StackSet = Hashtbl.Make (struct
  type t = string [@@deriving hash, eq]
end)

let stack_set = StackSet.create 16
let reset () = StackSet.clear stack_set

let add stack_trace =
  match StackSet.find_opt stack_set stack_trace with
  | Some n -> n
  | None ->
      let len = StackSet.length stack_set in
      StackSet.add stack_set stack_trace (len + 1);
      len + 1

let t_of_yojson json = Yojson.Safe.to_string json |> add
