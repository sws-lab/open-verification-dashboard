(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  conflicts : FileConflicts.t;
  po1_name : string;
  po2_name : string;
  global_result : Meta_status.t;
  category_results : Meta_status.CategoryMap.t;
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = FileConflicts.create ();
    po1_name;
    po2_name;
    global_result = Meta_status.create ();
    category_results = Meta_status.CategoryMap.create ();
  }

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (conflict : Conflict.t) =
  FileConflicts.add_conflict report.conflicts conflict;
  Meta_status.add_conflict report.global_result conflict;
  Meta_status.CategoryMap.add_conflict report.category_results conflict
