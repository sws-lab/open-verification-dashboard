(**
  This module provides functions to compare proof obligations and identify conflicts.
*)
module ChecksSet = Map.Make(struct
  type t = Conflict.ConflictCheck.t
  let compare = Conflict.ConflictCheck.compare
end)

module UniqueConflict = struct
  type t = {
    kind: Conflict.kind;
    title: ProofObligation.Category.t;
    range: ProofObligation.Range.t;
    from_po1: unit ChecksSet.t;
    from_po2: unit ChecksSet.t;
  }

  let check_of_unique_check ?new_kind (check: t) =
    Conflict.{
      kind = Option.value new_kind ~default:check.kind;
      range = check.range;
      title = check.title;
      from_po1 = ChecksSet.to_seq check.from_po1 |> Seq.map fst |> List.of_seq;
      from_po2 = ChecksSet.to_seq check.from_po2 |> Seq.map fst |> List.of_seq;
    }
end

type po_safety = {
  safe: bool;
  has_safe: bool;
  highest_error_level: ProofObligation.Kind.t;
}
(**
  Store comparison informations about a given range and category for later categorization.
  - [safe]: [true] if all checks are safe, [false] otherwise.
  - [has_safe]: [true] if there is at least one safe check in all possible contexts, [false] otherwise.
  - [highest_error_level]: the highest error level of all checks in the range, which can be used to determine the severity of the issues.
*)

module SafeMap = Map.Make(Int)

let safety_of_checks (checks: unit ChecksSet.t) : po_safety =
  let open Conflict in
  let res = ChecksSet.fold (fun (check : ConflictCheck.t) _ ((acc, safe_map) : po_safety * (int * ProofObligation.Kind.t) SafeMap.t) ->
    let is_safe = ProofObligation.Kind.is_safe check.kind in
    let highest_error_level = ProofObligation.Kind.max acc.highest_error_level check.kind in
    { safe = acc.safe && is_safe; has_safe = false; highest_error_level }, 
    SafeMap.update check.callstack (function
      | None -> Some (1, check.kind)
      | Some (count, existing_kind) -> Some (count + 1, ProofObligation.Kind.min existing_kind check.kind)
    ) safe_map
  ) checks ({ safe = true; has_safe = false; highest_error_level = ProofObligation.Kind.Safe }, SafeMap.empty) in
  let has_safe = SafeMap.exists (fun _ (count, kind) -> count > 1 && ProofObligation.Kind.is_safe kind) @@ snd res in
  { (fst res) with has_safe }

let conflicts_between (w1: ProofObligation.t) (w2: ProofObligation.t) =
  let open ProofObligation in
  let open Conflict in
  let gather_conflicts checks f =
    let rec build_unique_conflict acc = function
      | [] -> acc, []
      | (analyzer_id, (check: Check.t)) :: rest ->
        match acc with
        | None -> build_unique_conflict (Some UniqueConflict.{ 
            kind = Conflict.Unchecked; 
            range = check.range;
            title = check.title;
            from_po1 = if analyzer_id = 1 then ChecksSet.singleton (ConflictCheck.of_check check) () else ChecksSet.empty;
            from_po2 = if analyzer_id = 2 then ChecksSet.singleton (ConflictCheck.of_check check) () else ChecksSet.empty;
          }) rest
        | Some conflict ->
          if Range.compare conflict.range check.range = 0 && Category.compare conflict.title check.title = 0 then
            let from_po1 = if analyzer_id = 1 then ChecksSet.add (ConflictCheck.of_check check) () conflict.from_po1 else conflict.from_po1 in
            let from_po2 = if analyzer_id = 2 then ChecksSet.add (ConflictCheck.of_check check) () conflict.from_po2 else conflict.from_po2 in
            let new_range = Range.union conflict.range check.range in
            build_unique_conflict (Some { conflict with from_po1; from_po2; range = new_range }) rest
          else
            acc, (analyzer_id, check) :: rest
    in
    let rec aux acc checks = 
      match build_unique_conflict None checks with
      | None, [] -> acc
      | Some conflict, [] -> f conflict :: acc
      | Some conflict, rest ->
        aux (f conflict :: acc) rest
      | None, _::_ -> assert false
    in
    aux [] checks
  in    

  let checks = List.rev_append (List.map (fun check -> (1, check)) w1.checks) (List.map (fun check -> (2, check)) w2.checks) in
  let checks = List.sort (
    fun (_, (c1: Check.t)) (_, (c2: Check.t)) -> 
      let comp = Category.compare c1.title c2.title in
      if comp <> 0 then comp
      else Range.compare_file_position c1.range.start c2.range.start
    ) checks in
  let conflicts = gather_conflicts checks (fun proofObligation -> 
    match (ChecksSet.is_empty proofObligation.from_po1, ChecksSet.is_empty proofObligation.from_po2) with
    | (true, false) 
    | (false, true) ->
      UniqueConflict.check_of_unique_check ~new_kind:Conflict.OnlyOneProofObligation proofObligation
    | false, false ->
      let c1_safety = safety_of_checks proofObligation.from_po1 in
      let c2_safety = safety_of_checks proofObligation.from_po2 in
      (* Order of conditions matter because there is an overlap between them *)
      if c1_safety.safe && c2_safety.safe then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.NoConflictSafe proofObligation
      else if c1_safety.safe && not c2_safety.safe then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.SafetyW1 proofObligation
      else if not c1_safety.safe && c2_safety.safe then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.SafetyW2 proofObligation
      else if c1_safety.has_safe && not c2_safety.has_safe then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.PrecisionW1 proofObligation
      else if not c1_safety.has_safe && c2_safety.has_safe then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.PrecisionW2 proofObligation
      else if c1_safety.highest_error_level <> c2_safety.highest_error_level then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.ErrorLevel proofObligation
      else if c1_safety.highest_error_level = Kind.Warning && c2_safety.highest_error_level = Kind.Warning then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.NoConflictWarning proofObligation
      else if c1_safety.highest_error_level = Kind.Error && c2_safety.highest_error_level = Kind.Error then
        UniqueConflict.check_of_unique_check ~new_kind:Conflict.NoConflictError proofObligation
      else
        assert false
    | (true, true) -> assert false
  ) in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts


let filter_conflicts (conflicts: Conflict.t list) (filter_kind: Conflict.kind list) (filter_error_category: ProofObligation.Category.t list) =
  match (filter_kind, filter_error_category) with
  | [], [] -> conflicts
  | _ ->
    let kind_set = Hashtbl.of_seq (List.to_seq filter_kind |> Seq.map (fun el -> (el, ()))) in
    let error_category_set = Hashtbl.of_seq (List.to_seq filter_error_category |> Seq.map (fun el -> (el, ()))) in
    List.filter (fun (conflict: Conflict.t) ->
      let kind_match = Hashtbl.length kind_set = 0 ||
        Hashtbl.mem kind_set conflict.kind in
      let error_category_match = Hashtbl.length error_category_set = 0 || Hashtbl.mem error_category_set conflict.title in
      kind_match && error_category_match
    ) conflicts

let exit_code_of_conflict (conflict: Conflict.t list) =
  List.fold_left (fun acc (conflict: Conflict.t) ->
    match conflict.kind with
    | Conflict.NoConflictSafe -> max acc 0
    | Conflict.NoConflictWarning -> max acc 0
    | Conflict.NoConflictError -> max acc 0
    | Conflict.OnlyOneProofObligation -> max acc 3
    | Conflict.SafetyW1 -> max acc 4
    | Conflict.SafetyW2 -> max acc 4
    | Conflict.PrecisionW1 -> max acc 2
    | Conflict.PrecisionW2 -> max acc 2
    | Conflict.ErrorLevel -> max acc 2
    | Conflict.Unchecked -> max acc 5
  ) 0 conflict