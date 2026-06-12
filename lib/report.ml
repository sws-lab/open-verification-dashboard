(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  conflicts : FileConflicts.t;
  po1_name : string;
  po2_name : string;
  global_result : Meta_status.t;
  category_results : Meta_status.map;
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = Hashtbl.create 16;
    po1_name;
    po2_name;
    global_result = Meta_status.create ();
    category_results = Meta_status.create_map ();
  }

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (conflict : Conflict.t) =
  FileConflicts.add_conflict report.conflicts conflict;
  Meta_status.update report.global_result conflict;
  Meta_status.update_map report.category_results conflict
