module RangeHash = Map.Make(struct
  open ProofObligation
  type t = Range.t * Category.t
  let compare (r1, c1) (r2, c2) =
    let cmp = Range.compare r1 r2 in
    if cmp <> 0 then cmp else Category.compare c1 c2
end)

module Conflict = struct
  open ProofObligation
  type kind =
    | Unchecked
    | Quantity
    | OnlyOneProofObligation
    | Safety
    | PrecisionW1
    | PrecisionW2
  [@@deriving show { with_path = false }]
  
  type t = {
    kind: kind;
    range: Range.t;
    from_w1: Check.t list;
    from_w2: Check.t list;
  }
  [@@deriving show]

  let pp_kind fmt kind =
    Format.fprintf fmt "@{<bold>@{<#f00>%a@}@}"
      pp_kind kind


  let pp fmt conflict =
    Format.fprintf fmt
      "%a (%a): @.    @[<v 2>" pp_kind conflict.kind Range.pp conflict.range;
    
    let pp_two_checks fmt conflict =
      Format.fprintf fmt "@{<#fff>ProofObligation 1 checks:@}@, @[<hov 4>%a@]@;<0 -2>"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_w1;
      Format.fprintf fmt "@{<#fff>ProofObligation 2 checks:@}@, @[<hov 4>%a@]"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_w2
    in

    match conflict.kind with
    | Quantity ->
      Format.fprintf fmt "ProofObligation 1 checked %d items, ProofObligation 2 checked %d items@;<0 -2>"
        (List.length conflict.from_w1) (List.length conflict.from_w2);
      pp_two_checks fmt conflict;
    | OnlyOneProofObligation ->
      if List.length conflict.from_w1 > 0 then
        Format.fprintf fmt "@{<#fff>Only ProofObligation 1 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_w1
      else
        Format.fprintf fmt "@{<#fff>Only ProofObligation 2 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_w2;
    | PrecisionW1 ->
      Format.fprintf fmt "@{<#fff>ProofObligation 1 detects safe sub ranges that ProofObligation 2 does not detect.@}@;<0 -2>";
      pp_two_checks fmt conflict;
    | PrecisionW2 ->
      Format.fprintf fmt "@{<#fff>ProofObligation 2 detects safe sub ranges that ProofObligation 1 does not detect.@}@;<0 -2>";
      pp_two_checks fmt conflict;
    | Safety ->
      Format.fprintf fmt "@{<#fff>The two proofObligations disagree on the safety of the range.@}@;<0 -2>";
      pp_two_checks fmt conflict;
    | Unchecked ->
      Format.fprintf fmt "@{<#fff>This has not been checked for conflicts yet.@}";


    Format.fprintf fmt "@]";
    Format.pp_print_newline fmt ()
end

let search_proofObligations_disagreements (w1: ProofObligation.t) (w2: ProofObligation.t) =
  let open ProofObligation in
  let insert_proofObligations proofObligation_id map (checks: Check.t list) =
    List.fold_left (fun acc check ->
      let key = Check.(check.range, check.title) in
      match RangeHash.find_opt key acc with
      | None ->
        RangeHash.add key Conflict.{
          kind = Unchecked;
          range = check.range;
          from_w1 = if proofObligation_id = 1 then [check] else [];
          from_w2 = if proofObligation_id = 2 then [check] else [];
        } acc
      | Some conflict ->
        let new_range = Range.union conflict.range check.range in
        let new_key = (new_range, check.title) in
        let new_conflict = Conflict.{
          conflict with
            range = new_range;
            from_w1 = if proofObligation_id = 1 then check :: conflict.from_w1 else conflict.from_w1;
            from_w2 = if proofObligation_id = 2 then check :: conflict.from_w2 else conflict.from_w2;
        } in
        RangeHash.add new_key new_conflict acc 
    ) map checks
  in
  let map1 = insert_proofObligations 1 RangeHash.empty w1.checks in
  let map2 = insert_proofObligations 2 map1 w2.checks in
  let conflicts = RangeHash.fold (fun _ (proofObligation : Conflict.t) acc ->
    match (proofObligation.from_w1, proofObligation.from_w2) with
    | ([], []) -> acc
    | ([], (_::_)) ->
      {proofObligation with kind = Conflict.OnlyOneProofObligation} :: acc
    | (_::_, []) ->
      {proofObligation with kind = Conflict.OnlyOneProofObligation} :: acc
    | (_::_ as checks1, (_::_ as checks2)) ->
      let c1_safe = List.exists (fun (c : Check.t) -> Kind.is_safe c.kind) checks1 in
      let c2_safe = List.exists (fun (c : Check.t) -> Kind.is_safe c.kind) checks2 in
      if c1_safe && c2_safe then
        acc
      else if c1_safe != c2_safe then
        if List.for_all (fun (c : Check.t) -> Kind.is_safe c.kind && not @@ Range.equal c.range proofObligation.range) checks1 || 
           List.for_all (fun (c : Check.t) -> Kind.is_safe c.kind && not @@ Range.equal c.range proofObligation.range) checks2 then
          {proofObligation with kind = Conflict.Safety} :: acc
        else if c1_safe then
          {proofObligation with kind = Conflict.PrecisionW1} :: acc
        else if c2_safe then
          {proofObligation with kind = Conflict.PrecisionW2} :: acc
        else
          assert false
      else if List.length checks1 <> List.length checks2 then
        {proofObligation with kind = Conflict.Quantity} :: acc
      else
        acc
  ) map2 [] in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts
