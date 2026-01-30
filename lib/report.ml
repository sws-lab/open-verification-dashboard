(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type conflicts = (string, Conflict.t list) Hashtbl.t

let yojson_of_conflicts (h : conflicts) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc -> (k, `List (List.map Conflict.yojson_of_t v)) :: acc)
       h [])

type meta_verdict_answer =
  | Yes [@name "yes"]
  | No [@name "no"]
  | Unknown [@name "unknown"]
[@@deriving yojson]

let meta_verdict_answer_of_yojson =
  Utils.string_t_of_yojson meta_verdict_answer_of_yojson "meta_verdict_answer"

let yojson_of_meta_verdict_answer =
  Utils.string_yojson_of_t yojson_of_meta_verdict_answer

type meta_verdict = {
  mutable result : Conflict.verdict option;
  mutable verdict : meta_verdict_answer;
  mutable conflict : bool;
}
[@@deriving yojson]

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
}
[@@deriving yojson_of]

let create po1_name po2_name =
  {
    conflicts = Hashtbl.create 16;
    po1_name;
    po2_name;
    optimistic_result =
      {
        global_result = { verdict = Unknown; conflict = false; result = None };
        results = Hashtbl.create 10;
      };
    pessimistic_result =
      {
        global_result = { verdict = Unknown; conflict = false; result = None };
        results = Hashtbl.create 10;
      };
  }

(** Join two analyzers verdict in an optimistic way. *)
let optimistic_verdict_join = function
  | Conflict.Safe, Conflict.Error | Conflict.Error, Conflict.Safe ->
      Conflict.Unreached
  | Conflict.Safe, _ | _, Conflict.Safe -> Conflict.Safe
  | Conflict.Warning, Conflict.Error
  | Conflict.Error, Conflict.Warning
  | Conflict.Error, Conflict.Error -> Conflict.Error
  | Conflict.Warning, _ | _, Conflict.Warning -> Conflict.Warning
  | Conflict.Unknown, _ | _, Conflict.Unknown -> assert false
  | _ -> Conflict.Unreached

(** Join two analyzers verdict in a pessimistic way. *)
let pessimistic_verdict_join = function
  | Conflict.Error, Conflict.Error -> Conflict.Error
  | Conflict.Safe, Conflict.Safe -> Conflict.Safe
  | Conflict.Error, Conflict.Safe
  | Conflict.Safe, Conflict.Error
  | Conflict.Warning, _
  | _, Conflict.Warning -> Conflict.Warning
  | Conflict.Unreached, verdict | verdict, Conflict.Unreached -> verdict
  | Conflict.Unknown, _ | _, Conflict.Unknown -> assert false

(* Error > Warning > Safe *)
let severity_order_join = function
  | Conflict.Error, _ | _, Conflict.Error -> Conflict.Error
  | Conflict.Warning, _ | _, Conflict.Warning -> Conflict.Warning
  | Conflict.Safe, Conflict.Safe -> Conflict.Safe
  | Conflict.Unreached, _ | _, Conflict.Unreached -> assert false
  | Conflict.Unknown, _ | _, Conflict.Unknown -> assert false

let verdict_of_conflict_verdict = function
  | Conflict.Safe -> Yes
  | Conflict.Warning | Conflict.Error -> No
  | Conflict.Unreached | Conflict.Unknown -> Unknown

let update_meta_result (result : meta_verdict) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t)
    (update_function : Conflict.verdict * Conflict.verdict -> Conflict.verdict)
    =
  if conflict.kind = Conflict.ErrorLevel then result.conflict <- true;
  match result.result with
  | None ->
      result.result <- Some new_verdict;
      result.verdict <- verdict_of_conflict_verdict new_verdict
  | Some existing_kind ->
      let updated_kind = update_function (existing_kind, new_verdict) in
      result.result <- Some updated_kind;
      result.verdict <- verdict_of_conflict_verdict updated_kind

let update_meta_verdict_table (table : meta_verdict_map)
    (category : ProofObligation.Category.t) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t)
    (update_function : Conflict.verdict * Conflict.verdict -> Conflict.verdict)
    =
  match Hashtbl.find_opt table category with
  | Some result ->
      update_meta_result result new_verdict conflict update_function
  | None ->
      let new_result = { verdict = Unknown; conflict = false; result = None } in
      update_meta_result new_result new_verdict conflict update_function;
      Hashtbl.add table category new_result

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  (match conflict.kind with
  | Conflict.Unchecked | Conflict.OnlyOneProofObligation -> ()
  | _ ->
      let optimistic_verdict =
        optimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
      in
      update_meta_result report.optimistic_result.global_result
      optimistic_verdict conflict severity_order_join;
      update_meta_verdict_table report.optimistic_result.results conflict.title
      optimistic_verdict conflict severity_order_join);
  let pessimistic_verdict =
    pessimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
  in
  update_meta_result report.pessimistic_result.global_result
    pessimistic_verdict conflict severity_order_join;
  update_meta_verdict_table report.pessimistic_result.results conflict.title
    pessimistic_verdict conflict severity_order_join;
  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
