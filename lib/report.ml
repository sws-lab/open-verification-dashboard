open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type sources = (string, string) Hashtbl.t
let yojson_of_sources = yojson_of_hashtbl yojson_of_string yojson_of_string
let sources_of_yojson = hashtbl_of_yojson string_of_yojson string_of_yojson

type t = {
  mutable conflicts: Conflict.t list;
  sources: sources;
}
[@@deriving yojson]

let create () = {
  conflicts = [];
  sources = Hashtbl.create 16;
}

let extract_source file_path =
  let ic = open_in file_path in
  let hash = Sha256.input ic in
  close_in ic;
  Sha256.to_hex hash

let add_conflict t files conflicts =
  t.conflicts <- conflicts @ t.conflicts;
  List.iter (fun file ->
    let content = extract_source file in
    Hashtbl.add t.sources file content
  ) files
  
  