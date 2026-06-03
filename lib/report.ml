(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module Utils = ProofObligation.Utils

type conflicts = (string, Conflict.t list) Hashtbl.t

let yojson_of_conflicts (h : conflicts) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc -> (k, `List (List.map Conflict.yojson_of_t v)) :: acc)
       h [])

type meta_status = {
  mutable result : Conflict.status option;
  mutable conflict : bool;
}

let yojson_of_meta_status {result; conflict} =
  let verdict =
    match result with
    | Some Safe -> "yes"
    | Some Warning | Some Error -> "no"
    | Some Unreached | None -> "unknown"
  in
  `Assoc [
    ("result", [%yojson_of: Conflict.status option] result);
    ("verdict", `String verdict); (* TODO: remove this redundant field, causes output diffs *)
    ("conflict", [%yojson_of: bool] conflict);
  ]


type meta_status_map = (ProofObligation.Category.t, meta_status) Hashtbl.t

let yojson_of_meta_status_map (h : meta_status_map) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc ->
         let key = ProofObligation.Category.to_string k in
         let value = yojson_of_meta_status v in
         (key, value) :: acc)
       h [])

type report_meta_status = {
  global_result : meta_status;
  results : meta_status_map;
}
[@@deriving yojson_of]

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
  optimistic_result : report_meta_status;
  pessimistic_result : report_meta_status;
  joint_progress_matrix : int array array;
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = Hashtbl.create 16;
    po1_name;
    po2_name;
    optimistic_result =
      {
        global_result = { conflict = false; result = None };
        results = Hashtbl.create 10;
      };
    pessimistic_result =
      {
        global_result = { conflict = false; result = None };
        results = Hashtbl.create 10;
      };
    joint_progress_matrix = Array.make_matrix 4 4 0;
  }


let update_meta_result (result : meta_status) (new_status : Conflict.status)
    (conflict : Conflict.t)
    (update_function : Conflict.status * Conflict.status -> Conflict.status)
    =
  if conflict.kind = Conflict.ErrorLevel then result.conflict <- true;
  match result.result with
  | None ->
      result.result <- Some new_status
  | Some existing_kind ->
      let updated_kind = update_function (existing_kind, new_status) in
      result.result <- Some updated_kind

let update_meta_status_table (table : meta_status_map)
    (category : ProofObligation.Category.t) (new_status : Conflict.status)
    (conflict : Conflict.t)
    (update_function : Conflict.status * Conflict.status -> Conflict.status)
    =
  match Hashtbl.find_opt table category with
  | Some result ->
      update_meta_result result new_status conflict update_function
  | None ->
      let new_result = { conflict = false; result = None } in
      update_meta_result new_result new_status conflict update_function;
      Hashtbl.add table category new_result

let add_joint_status (report : t) (conflict : Conflict.t) =
  let po_status_to_id = function
    | Status.Warning -> 0
    | Status.Error -> 1
    | Status.Safe -> 2
    | _ -> 3
  in
  let id1 = po_status_to_id conflict.status_po1 in
  let id2 = po_status_to_id conflict.status_po2 in
  report.joint_progress_matrix.(id1).(id2) <-
    report.joint_progress_matrix.(id1).(id2) + 1

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  (match conflict.kind with
  | Conflict.Unchecked | Conflict.OnlyOneProofObligation -> ()
  | _ ->
      let optimistic_status =
        Status.optimistic_join (conflict.status_po1, conflict.status_po2)
      in
      update_meta_result report.optimistic_result.global_result
        optimistic_status conflict Status.severity_join;
      update_meta_status_table report.optimistic_result.results conflict.title
        optimistic_status conflict Status.severity_join);
  let pessimistic_status =
    Status.pessimistic_join (conflict.status_po1, conflict.status_po2)
  in
  update_meta_result report.pessimistic_result.global_result pessimistic_status
    conflict Status.severity_join;
  update_meta_status_table report.pessimistic_result.results conflict.title
    pessimistic_status conflict Status.severity_join;
  add_joint_status report conflict;
  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
