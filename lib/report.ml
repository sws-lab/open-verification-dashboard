open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type sources = (string, unit) Hashtbl.t
let yojson_of_sources (h: (string, unit) Hashtbl.t)  = `List (
  Hashtbl.fold (fun k _ acc -> (`String k) :: acc) h [])

let sources_of_yojson = function
  | `List lst ->
    let tbl = Hashtbl.create (List.length lst) in
    List.iter (function
      | `String file -> Hashtbl.add tbl file ()
      | _ -> failwith "Invalid sources format") lst;
    tbl
  | _ -> failwith "Expected a list of sources"

type t = {
  mutable conflicts: Conflict.t list;
  mutable po1_name: string;
  mutable po2_name: string;
  sources: sources;
}
[@@deriving yojson]

let create po1_name po2_name = {
  conflicts = [];
  po1_name;
  po2_name;
  sources = Hashtbl.create 16;
}

let add_conflict t files conflicts =
  t.conflicts <- conflicts @ t.conflicts;
  List.iter (fun file ->
    Hashtbl.add t.sources file ()
  ) files
  
  