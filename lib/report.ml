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

type meta_verdict = {
  mutable result : Conflict.verdict option;
  mutable conflict : bool;
}

let yojson_of_meta_verdict {result; conflict} =
  let verdict =
    match result with
    | Some Safe -> "yes"
    | Some Warning | Some Error -> "no"
    | Some Unreached | None -> "unknown"
  in
  `Assoc [
    ("result", [%yojson_of: Conflict.verdict option] result);
    ("verdict", `String verdict); (* TODO: remove this redundant field, causes output diffs *)
    ("conflict", [%yojson_of: bool] conflict);
  ]


type meta_verdict_map = (ProofObligation.Category.t, meta_verdict) Hashtbl.t

let yojson_of_meta_verdict_map (h : meta_verdict_map) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc ->
         let key = ProofObligation.Category.to_string k in
         let value = yojson_of_meta_verdict v in
         (key, value) :: acc)
       h [])

type report_meta_verdict = {
  global_result : meta_verdict;
  results : meta_verdict_map;
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
  optimistic_result : report_meta_verdict;
  pessimistic_result : report_meta_verdict;
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


let update_meta_result (result : meta_verdict) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t)
    (update_function : Conflict.verdict * Conflict.verdict -> Conflict.verdict)
    =
  if conflict.kind = Conflict.ErrorLevel then result.conflict <- true;
  match result.result with
  | None ->
      result.result <- Some new_verdict
  | Some existing_kind ->
      let updated_kind = update_function (existing_kind, new_verdict) in
      result.result <- Some updated_kind

let update_meta_verdict_table (table : meta_verdict_map)
    (category : ProofObligation.Category.t) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t)
    (update_function : Conflict.verdict * Conflict.verdict -> Conflict.verdict)
    =
  match Hashtbl.find_opt table category with
  | Some result ->
      update_meta_result result new_verdict conflict update_function
  | None ->
      let new_result = { conflict = false; result = None } in
      update_meta_result new_result new_verdict conflict update_function;
      Hashtbl.add table category new_result

let add_joint_verdict (report : t) (conflict : Conflict.t) =
  let po_verdict_to_id = function
    | Verdict.Warning -> 0
    | Verdict.Error -> 1
    | Verdict.Safe -> 2
    | _ -> 3
  in
  let id1 = po_verdict_to_id conflict.verdict_po1 in
  let id2 = po_verdict_to_id conflict.verdict_po2 in
  report.joint_progress_matrix.(id1).(id2) <-
    report.joint_progress_matrix.(id1).(id2) + 1

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  (match conflict.kind with
  | Conflict.Unchecked | Conflict.OnlyOneProofObligation -> ()
  | _ ->
      let optimistic_verdict =
        Verdict.optimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
      in
      update_meta_result report.optimistic_result.global_result
        optimistic_verdict conflict Verdict.severity_order_join;
      update_meta_verdict_table report.optimistic_result.results conflict.title
        optimistic_verdict conflict Verdict.severity_order_join);
  let pessimistic_verdict =
    Verdict.pessimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
  in
  update_meta_result report.pessimistic_result.global_result pessimistic_verdict
    conflict Verdict.severity_order_join;
  update_meta_verdict_table report.pessimistic_result.results conflict.title
    pessimistic_verdict conflict Verdict.severity_order_join;
  add_joint_verdict report conflict;
  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
