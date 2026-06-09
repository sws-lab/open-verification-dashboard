(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type conflicts = (string, Conflict.t list) Hashtbl.t

let yojson_of_conflicts (h : conflicts) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc -> (k, `List (List.map Conflict.yojson_of_t v)) :: acc)
       h [])

let conflicts_of_yojson = function
  | `Assoc l ->
      let tbl = Hashtbl.create 10 in
      List.iter
        (function
          | (k : string), `List v ->
              let conflicts = List.map Conflict.t_of_yojson v in
              Hashtbl.add tbl k conflicts
          | _ -> failwith "Expected a string key and a list of conflicts")
        l;
      tbl
  | _ -> failwith "Expected an associative list for conflicts"

type t = {
  conflicts : conflicts;
  po1_name : string;
  po2_name : string;
  global_result : Meta_status.t;
  category_results : Meta_status.map;
  joint_progress_matrix : JointMatrix.t;
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = Hashtbl.create 16;
    po1_name;
    po2_name;
    global_result = Meta_status.create ();
    category_results = Meta_status.create_map ();
    joint_progress_matrix = JointMatrix.create ();
  }

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  Meta_status.update report.global_result conflict;
  Meta_status.update_map report.category_results conflict;
  JointMatrix.add report.joint_progress_matrix conflict.status_po1 conflict.status_po2;
  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
