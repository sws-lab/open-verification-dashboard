open Ovd_checks

module AnalyzerId = Int
module AnalyzerMap = Map.Make (AnalyzerId)

module CategoryFile =
struct
  type t = Category.t * string [@@deriving ord]
end

module CategoryFileMap =
struct
  include Map.Make (CategoryFile)

  let of_checks checks =
    List.fold_left (fun acc (check: Check.t) ->
        let category_file = (check.category, check.range.file) in
        let group = Option.value (find_opt category_file acc) ~default:[] in
        add category_file (check :: group) acc (* reverses checks *)
      ) empty checks
end

module PreConflict =
struct
  type t = {
    category : Category.t;
    range : Range.t;
    analyzer_checks : Conflict.ChecksSet.t AnalyzerMap.t;
  }

  let to_conflict pc =
    let analyzer_statuses = AnalyzerMap.map (fun checks ->
        Conflict.ChecksSet.fold (fun c acc -> Status.join (Status.of_reachable c.Conflict.ConflictCheck.status) acc) checks `Unreached
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
    }
end


module type S =
sig
  val compare: Check.t list -> Check.t list -> Conflict.t list
end
