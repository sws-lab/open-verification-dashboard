module RangeHash = Map.Make(struct
  open ProofObligation
  type t = Range.t * Category.t
  let compare (r1, c1) (r2, c2) =
    let cmp = Range.compare r1 r2 in
    if cmp <> 0 then cmp else Category.compare c1 c2
end)

module ChecksSet = Map.Make(struct
  type t = ProofObligation.Check.t
  let compare = ProofObligation.Check.compare
end)

type unique_conflict = {
  kind: Conflict.kind;
  range: ProofObligation.Range.t;
  from_po1: unit ChecksSet.t;
  from_po2: unit ChecksSet.t;
}

let check_of_unique_check ?new_kind (check: unique_conflict) =
  Conflict.{
    kind = Option.value new_kind ~default:check.kind;
    range = check.range;
    from_po1 = ChecksSet.to_seq check.from_po1 |> Seq.map fst |> List.of_seq;
    from_po2 = ChecksSet.to_seq check.from_po2 |> Seq.map fst |> List.of_seq;
  }

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
  let res = ChecksSet.fold (fun (check : ProofObligation.Check.t) _ ((acc, safe_map) : po_safety * (int * ProofObligation.Kind.t) SafeMap.t) ->
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

let disagreements_between (w1: ProofObligation.t) (w2: ProofObligation.t) =
  let open ProofObligation in
  let insert_proofObligations proofObligation_id map (checks: Check.t list) =
    List.fold_left (fun acc check ->
      let key = Check.(check.range, check.title) in
      match RangeHash.find_opt key acc with
      | None ->
        RangeHash.add key {
          kind = Unchecked;
          range = check.range;
          from_po1 = if proofObligation_id = 1 then ChecksSet.singleton check () else ChecksSet.empty;
          from_po2 = if proofObligation_id = 2 then ChecksSet.singleton check () else ChecksSet.empty;
        } acc
      | Some conflict ->
        let new_range = Range.union conflict.range check.range in
        let new_key = (new_range, check.title) in
        let new_conflict = {
          conflict with
            range = new_range;
            from_po1 = if proofObligation_id = 1 then ChecksSet.add check () conflict.from_po1 else conflict.from_po1;
            from_po2 = if proofObligation_id = 2 then ChecksSet.add check () conflict.from_po2 else conflict.from_po2;
        } in
        RangeHash.add new_key new_conflict acc
    ) map checks
  (**
    Insert proof obligations into a map, categorizing them by their range and title.
    The [proofObligation_id] is used to distinguish between the two proof obligations being compared.
  *)
  in
  let map1 = insert_proofObligations 1 RangeHash.empty w1.checks in
  let map2 = insert_proofObligations 2 map1 w2.checks in
  let conflicts = RangeHash.fold (fun _ (proofObligation : unique_conflict) acc ->
    match (ChecksSet.is_empty proofObligation.from_po1, ChecksSet.is_empty proofObligation.from_po2) with
    | (true, true) -> acc
    | (true, false) 
    | (false, true) ->
      check_of_unique_check ~new_kind:Conflict.OnlyOneProofObligation proofObligation :: acc
    | false, false ->
      let c1_safety = safety_of_checks proofObligation.from_po1 in
      let c2_safety = safety_of_checks proofObligation.from_po2 in
      (* Order of conditions matter because there is an overlap between them *)
      if c1_safety.safe && c2_safety.safe then
        check_of_unique_check ~new_kind:Conflict.NoConflictSafe proofObligation :: acc
      else if c1_safety.safe && not c2_safety.safe then
        check_of_unique_check ~new_kind:Conflict.SafetyW1 proofObligation :: acc
      else if not c1_safety.safe && c2_safety.safe then
        check_of_unique_check ~new_kind:Conflict.SafetyW2 proofObligation :: acc
      else if c1_safety.has_safe && not c2_safety.has_safe then
        check_of_unique_check ~new_kind:Conflict.PrecisionW1 proofObligation :: acc
      else if not c1_safety.has_safe && c2_safety.has_safe then
        check_of_unique_check ~new_kind:Conflict.PrecisionW2 proofObligation :: acc
      else if c1_safety.highest_error_level <> c2_safety.highest_error_level then
        check_of_unique_check ~new_kind:Conflict.ErrorLevel proofObligation :: acc
      else if c1_safety.highest_error_level = Kind.Warning && c2_safety.highest_error_level = Kind.Warning then
        check_of_unique_check ~new_kind:Conflict.NoConflictWarning proofObligation :: acc
      else if c1_safety.highest_error_level = Kind.Error && c2_safety.highest_error_level = Kind.Error then
        check_of_unique_check ~new_kind:Conflict.NoConflictError proofObligation :: acc
      else
        assert false
  ) map2 [] in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts


let filter_disagreements (disagreements: Conflict.t list) (filter_kind: Conflict.kind list) (filter_error_category: ProofObligation.Category.t list) =
  match (filter_kind, filter_error_category) with
  | [], [] -> disagreements
  | _ ->
    let kind_set = Hashtbl.of_seq (List.to_seq filter_kind |> Seq.map (fun el -> (el, ()))) in
    let error_category_set = Hashtbl.of_seq (List.to_seq filter_error_category |> Seq.map (fun el -> (el, ()))) in
    List.filter (fun (conflict: Conflict.t) ->
      let kind_match = Hashtbl.length kind_set = 0 ||
        Hashtbl.mem kind_set conflict.kind in
      let error_category_match = Hashtbl.length error_category_set = 0 || 
        match conflict.from_po1, conflict.from_po2 with
          | [], [] -> false
          | po::_, _ ->
            Hashtbl.mem error_category_set po.title
          | _, po::_ ->
            Hashtbl.mem error_category_set po.title
      in
      kind_match && error_category_match
    ) disagreements

let exit_code_of_disagreement (disagreement: Conflict.t list) =
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
  ) 0 disagreement