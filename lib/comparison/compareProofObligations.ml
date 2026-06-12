(** This module provides functions to compare proof obligations and identify
    conflicts. *)

open Ovd_checks

module ConflictCheck = Conflict.ConflictCheck
module ChecksSet = Conflict.ChecksSet

module AnalyzerId = Int
module AnalyzerMap = Map.Make (AnalyzerId)

type pre_conflict = {
  category : Category.t;
  range : Range.t;
  analyzer_checks : ChecksSet.t AnalyzerMap.t;
}

let conflicts_between (w1 : ChecksFile.t) (w2 : ChecksFile.t) =
  let empty_analyzer_checks =
    AnalyzerMap.of_seq (Seq.init 2 (fun i -> (i + 1, ChecksSet.empty)))
  in
  let gather_conflicts checks f =
    let rec build_unique_conflict conflict = function
      | [] -> (conflict, [])
      | (analyzer_id, (check : Check.t)) :: rest -> (
        if
          Range.overlap conflict.range check.range
          && Category.compare conflict.category check.category = 0
        then
          let new_range = Range.union conflict.range check.range in
          let conflict_check = ConflictCheck.of_check check in
          let checks = match AnalyzerMap.find_opt analyzer_id conflict.analyzer_checks with
            | Some checks -> ChecksSet.add conflict_check checks
            | None -> ChecksSet.singleton conflict_check
          in
          build_unique_conflict
            {
              conflict with
              range = new_range;
              analyzer_checks = AnalyzerMap.add analyzer_id checks conflict.analyzer_checks;
            }
            rest
        else (conflict, (analyzer_id, check) :: rest))
    in
    let rec aux acc checks =
      match checks with
      | [] -> acc
      | (analyzer_id, (check : Check.t)) :: rest ->
        (* pick first check *)
        let conflict =
          {
            range = check.range;
            category = check.category;
            analyzer_checks = AnalyzerMap.add analyzer_id (ChecksSet.singleton (ConflictCheck.of_check check)) empty_analyzer_checks;
          }
        in
        (* build conflict of all matching checks *)
        let (conflict, rest') = build_unique_conflict conflict rest in
        (* continue with unmached checks *)
        aux (f conflict :: acc) rest'
    in
    aux [] checks
  in

  let checks =
    List.rev_append
      (List.map (fun check -> (1, check)) w1.checks)
      (List.map (fun check -> (2, check)) w2.checks)
  in
  let checks =
    List.sort
      (fun (_, (c1 : Check.t)) (_, (c2 : Check.t)) ->
        let comp = Category.compare c1.category c2.category in
        if comp <> 0 then comp
        else
          let comp = String.compare c1.range.file c2.range.file in
          if comp <> 0 then comp
          else Range.compare_file_position c1.range.start c2.range.start)
      checks
  in
  let conflicts =
    gather_conflicts checks (fun pc ->
        let analyzer_statuses = AnalyzerMap.map (fun checks ->
            ChecksSet.fold (fun c acc -> Status.join (Status.of_reachable c.ConflictCheck.status) acc) checks `Unreached
          ) pc.analyzer_checks
        in
        let status_po1 = AnalyzerMap.find 1 analyzer_statuses in
        let status_po2 = AnalyzerMap.find 2 analyzer_statuses in
        let kind =
          CrossStatus.of_statuses status_po1 status_po2
        in
        Conflict.{
          kind;
          category = pc.category;
          range = pc.range;
          from_po1 = AnalyzerMap.find 1 pc.analyzer_checks;
          status_po1;
          from_po2 = AnalyzerMap.find 2 pc.analyzer_checks;
          status_po2;
        })
  in
  List.sort Conflict.(fun c1 c2 -> Range.compare_overlap c1.range c2.range) conflicts
