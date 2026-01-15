(**
  This module defines the report structure and provides functions to create and export the final json report.
*)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type conflicts = (string, Conflict.t list) Hashtbl.t
let yojson_of_conflicts (h: conflicts)  = `Assoc (
  Hashtbl.fold (fun k v acc -> (k, `List (List.map Conflict.yojson_of_t v)) :: acc) h [])

let conflicts_of_yojson = function
  | `Assoc l -> 
    let tbl = Hashtbl.create 10 in
    List.iter (function
      | (k: string), `List v ->
        let conflicts = List.map Conflict.t_of_yojson v in
        Hashtbl.add tbl k conflicts
      | _ -> failwith "Expected a string key and a list of conflicts") l;
    tbl
  | _ -> failwith "Expected an associative list for conflicts"


type t = {
  conflicts: conflicts;
  po1_name: string;
  po2_name: string;
}
[@@deriving yojson]

let create po1_name po2_name = {
  conflicts = Hashtbl.create 16;
  po1_name;
  po2_name;
}

let add_conflict t file conflict =
  let existing = Hashtbl.find_opt t.conflicts file in
  match existing with
  | Some existing_conflicts -> 
    Hashtbl.replace t.conflicts file (conflict :: existing_conflicts)
  | None -> 
    Format.printf "Writing conflicts for file %s@." file;
    Hashtbl.add t.conflicts file [conflict]
  