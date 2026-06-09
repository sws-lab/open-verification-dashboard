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
  optimistic_result : Meta_status.report;
  pessimistic_result : Meta_status.report;
  joint_progress_matrix : JointMatrix.t;
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = Hashtbl.create 16;
    po1_name;
    po2_name;
    optimistic_result = Meta_status.create ();
    pessimistic_result = Meta_status.create ();
    joint_progress_matrix = JointMatrix.create ();
  }

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  let optimistic_status =
    Status.meet conflict.status_po1 conflict.status_po2
  in
  Meta_status.update report.optimistic_result.global_result
    optimistic_status;
  Meta_status.update_map report.optimistic_result.results conflict.category
    optimistic_status;
  let pessimistic_status =
    Status.join conflict.status_po1 conflict.status_po2
  in
  Meta_status.update report.pessimistic_result.global_result pessimistic_status;
  Meta_status.update_map report.pessimistic_result.results conflict.category
    pessimistic_status;
  JointMatrix.add report.joint_progress_matrix conflict.status_po1 conflict.status_po2;
  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
