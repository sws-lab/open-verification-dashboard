(** This module provides functions to compare proof obligations and identify
    conflicts. *)

open Ovd_checks
open Comparison

module ConflictCheck = Conflict.ConflictCheck
module ChecksSet = Conflict.ChecksSet

module RangeMap =
struct
  include Map.Make (Range)

  let of_checks checks =
    List.fold_left (fun acc (check: Check.t) ->
        let range = check.range in
        let group = Option.value (find_opt range acc) ~default:[] in
        add range (check :: group) acc (* reverses checks *)
      ) empty checks
end


let compare checks1 checks2 =
  let checks_of_file (checks: Check.t list) =
    CategoryFileMap.of_checks checks
    |> CategoryFileMap.map RangeMap.of_checks
  in
  let checks1 = checks_of_file checks1 in
  let checks2 = checks_of_file checks2 in
  let conflicts: PreConflict.t RangeMap.t CategoryFileMap.t = CategoryFileMap.merge (fun (category, _file) checks1 checks2 ->
      let checks1 = Option.value checks1 ~default:RangeMap.empty in
      let checks2 = Option.value checks2 ~default:RangeMap.empty in
      Some (RangeMap.merge (fun range checks1 checks2 ->
          let checks1 = Option.value checks1 ~default:[] in
          let checks2 = Option.value checks2 ~default:[] in
          Some PreConflict.{
            category;
            range;
            analyzer_checks = AnalyzerMap.of_seq (List.to_seq [
              (1, checks1 |> List.map ConflictCheck.of_check |> ChecksSet.of_list);
              (2, checks2 |> List.map ConflictCheck.of_check |> ChecksSet.of_list);
            ])
          }
        ) checks1 checks2)
    ) checks1 checks2
  in
  let conflicts =
    CategoryFileMap.to_rev_seq conflicts
    |> Seq.map snd
    |> Seq.concat_map RangeMap.to_seq
    |> Seq.map snd
    |> Seq.map PreConflict.to_conflict
    |> List.of_seq
  in
  List.sort Conflict.(fun c1 c2 -> Range.compare_overlap c1.range c2.range) conflicts
