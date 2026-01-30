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

let meta_verdict_answer_of_yojson = Utils.string_t_of_yojson meta_verdict_answer_of_yojson "meta_verdict_answer"

let yojson_of_meta_verdict_answer = Utils.string_yojson_of_t yojson_of_meta_verdict_answer

type meta_verdict = {
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
        global_result = { verdict = Unknown; conflict = false };
        results = Hashtbl.create 10;
      };
    pessimistic_result =
      {
        global_result = { verdict = Unknown; conflict = false };
        results = Hashtbl.create 10;
      };
  }

(** Join two analyzers verdict in an optimistic way. I.e. Safe > Warning > Error *)
let optimistic_verdict_join = function
  | Conflict.Safe, _
  | _, Conflict.Safe
  | Conflict.SafeWarning, _
  | _, Conflict.SafeWarning -> Conflict.Safe
  | Conflict.Warning, _
  | _, Conflict.Warning
  | _, Conflict.ErrorWarning
  | Conflict.ErrorWarning, _ -> Conflict.Warning
  | Conflict.Error, Conflict.Error -> Conflict.Error
  | Conflict.Unknown, _ | _, Conflict.Unknown -> Conflict.Unknown
  | _ -> Conflict.VNone

(** Join two analyzers verdict in a pessimistic way. I.e. Error > Warning > Safe *)
let pessimistic_verdict_join = function
  | Conflict.Error, _
  | _, Conflict.Error
  | Conflict.ErrorWarning, _
  | _, Conflict.ErrorWarning -> Conflict.Error
  | Conflict.Warning, _
  | _, Conflict.Warning
  | _, Conflict.SafeWarning
  | Conflict.SafeWarning, _ -> Conflict.Warning
  | Conflict.Safe, Conflict.Safe -> Conflict.Safe
  | Conflict.Unknown, _ | _, Conflict.Unknown -> Conflict.Unknown
  | _ -> Conflict.VNone

let new_meta_verdict verdict new_verdict =
  match (verdict, new_verdict) with
  | Unknown, Conflict.Safe -> Yes
  | Yes, Conflict.Safe -> Yes
  | Yes, Conflict.Warning -> Yes
  | No, _ | _, Conflict.Error -> No
  | _, Conflict.VNone | _, Conflict.Unknown | _, Conflict.Warning -> verdict
  | _, Conflict.SafeWarning ->
      failwith "SafeWarning should not appear in meta verdict"
  | _, Conflict.ErrorWarning ->
      failwith "ErrorWarning should not appear in meta verdict"

let update_meta_result (result : meta_verdict) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t) =
  result.verdict <- new_meta_verdict result.verdict new_verdict;
  if conflict.kind = Conflict.ErrorLevel then result.conflict <- true

let update_meta_verdict_table (table : meta_verdict_map)
    (category : ProofObligation.Category.t) (new_verdict : Conflict.verdict)
    (conflict : Conflict.t) =
  match Hashtbl.find_opt table category with
  | Some result -> update_meta_result result new_verdict conflict
  | None ->
      let new_result = { verdict = Unknown; conflict = false } in
      update_meta_result new_result new_verdict conflict;
      Hashtbl.add table category new_result

(** Add a conflict to the report global conflicts table *)
let add_conflict (report : t) (file : string) (conflict : Conflict.t) =
  let optimistic_verdict =
    optimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
  in
  let pessimistic_verdict =
    pessimistic_verdict_join (conflict.verdict_po1, conflict.verdict_po2)
  in
  update_meta_result report.optimistic_result.global_result optimistic_verdict
    conflict;
  update_meta_verdict_table report.optimistic_result.results conflict.title
    optimistic_verdict conflict;

  update_meta_result report.pessimistic_result.global_result pessimistic_verdict
    conflict;
  update_meta_verdict_table report.pessimistic_result.results conflict.title
    pessimistic_verdict conflict;

  let existing = Hashtbl.find_opt report.conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace report.conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.printf "Writing conflicts for file %s@." file;
      Hashtbl.add report.conflicts file [ conflict ]
