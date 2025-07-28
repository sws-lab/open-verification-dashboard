module RangeHash = Map.Make(struct
  open ProofObligation
  type t = Range.t * Category.t
  let compare (r1, c1) (r2, c2) =
    let cmp = Range.compare r1 r2 in
    if cmp <> 0 then cmp else Category.compare c1 c2
end)

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

let safety_of_checks (checks: ProofObligation.Check.t list) : po_safety =
  let res = List.fold_left (fun ((acc, safe_map) : po_safety * (int * ProofObligation.Kind.t) SafeMap.t) (check : ProofObligation.Check.t) ->
    let is_safe = ProofObligation.Kind.is_safe check.kind in
    let highest_error_level = ProofObligation.Kind.max acc.highest_error_level check.kind in
    { safe = acc.safe && is_safe; has_safe = false; highest_error_level }, 
    SafeMap.update check.callstack (function
      | None -> Some (1, check.kind)
      | Some (count, existing_kind) -> Some (count + 1, ProofObligation.Kind.min existing_kind check.kind)
    ) safe_map
  ) ({ safe = true; has_safe = false; highest_error_level = ProofObligation.Kind.Safe }, SafeMap.empty) checks in
  let has_safe = SafeMap.exists (fun _ (count, kind) -> count > 1 && ProofObligation.Kind.is_safe kind) @@ snd res in
  { (fst res) with has_safe }

let disagreements_between (w1: ProofObligation.t) (w2: ProofObligation.t) =
  let open ProofObligation in
  let insert_proofObligations proofObligation_id map (checks: Check.t list) =
    List.fold_left (fun acc check ->
      let key = Check.(check.range, check.title) in
      match RangeHash.find_opt key acc with
      | None ->
        RangeHash.add key Conflict.{
          kind = Unchecked;
          range = check.range;
          from_po1 = if proofObligation_id = 1 then [check] else [];
          from_po2 = if proofObligation_id = 2 then [check] else [];
        } acc
      | Some conflict ->
        let new_range = Conflict.(Range.union conflict.range check.range) in
        let new_key = (new_range, check.title) in
        let new_conflict = Conflict.{
          conflict with
            range = new_range;
            from_po1 = if proofObligation_id = 1 then check :: conflict.from_po1 else conflict.from_po1;
            from_po2 = if proofObligation_id = 2 then check :: conflict.from_po2 else conflict.from_po2;
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
  let conflicts = RangeHash.fold (fun _ (proofObligation : Conflict.t) acc ->
    match (proofObligation.from_po1, proofObligation.from_po2) with
    | ([], []) -> acc
    | ([], (_::_)) ->
      {proofObligation with kind = Conflict.OnlyOneProofObligation} :: acc
    | (_::_, []) ->
      {proofObligation with kind = Conflict.OnlyOneProofObligation} :: acc
    | (_::_ as checks1, (_::_ as checks2)) ->
      let c1_safety = safety_of_checks checks1 in
      let c2_safety = safety_of_checks checks2 in
      (* Order of conditions matter because there is an overlap between them *)
      if c1_safety.safe && c2_safety.safe then
        {proofObligation with kind = Conflict.NoConflictSafe} :: acc
      else if c1_safety.safe && not c2_safety.safe then
        {proofObligation with kind = Conflict.SafetyW1; from_po2 = checks2} :: acc
      else if not c1_safety.safe && c2_safety.safe then
        {proofObligation with kind = Conflict.SafetyW2; from_po1 = checks1} :: acc
      else if c1_safety.has_safe && not c2_safety.has_safe then
        {proofObligation with kind = Conflict.PrecisionW1; from_po2 = checks2} :: acc
      else if not c1_safety.has_safe && c2_safety.has_safe then
        {proofObligation with kind = Conflict.PrecisionW2; from_po1 = checks1} :: acc
      else if c1_safety.highest_error_level <> c2_safety.highest_error_level then
        {proofObligation with kind = Conflict.ErrorLevel} :: acc
      else if c1_safety.highest_error_level = Kind.Warning && c2_safety.highest_error_level = Kind.Warning then
        {proofObligation with kind = Conflict.NoConflictWarning} :: acc
      else if c1_safety.highest_error_level = Kind.Error && c2_safety.highest_error_level = Kind.Error then
        {proofObligation with kind = Conflict.NoConflictError} :: acc
      else
        assert false
  ) map2 [] in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts
