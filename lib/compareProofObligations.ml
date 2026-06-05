(** This module provides functions to compare proof obligations and identify
    conflicts. *)

let conflicts_between (w1 : ProofObligation.t) (w2 : ProofObligation.t) =
  let open ProofObligation in
  let open Conflict in
  let gather_conflicts checks f =
    let rec build_unique_conflict conflict = function
      | [] -> (conflict, [])
      | (analyzer_id, (check : Check.t)) :: rest -> (
        if
          Range.compare conflict.range check.range = 0
          && Category.compare conflict.title check.title = 0
        then
          let from_po1 =
            if analyzer_id = 1 then
              ChecksSet.add
                (ConflictCheck.of_check check)
                conflict.from_po1
            else conflict.from_po1
          in
          let from_po2 =
            if analyzer_id = 2 then
              ChecksSet.add
                (ConflictCheck.of_check check)
                conflict.from_po2
            else conflict.from_po2
          in
          let new_range = Range.union conflict.range check.range in
          let status_po1 =
            if analyzer_id = 1 then
              Status.pessimistic_join conflict.status_po1
                (Status.of_kind check.kind)
            else conflict.status_po1
          in
          let status_po2 =
            if analyzer_id = 2 then
              Status.pessimistic_join conflict.status_po2
                (Status.of_kind check.kind)
            else conflict.status_po2
          in
          build_unique_conflict
            {
              conflict with
              from_po1;
              from_po2;
              status_po1;
              status_po2;
              range = new_range;
            }
            rest
        else (conflict, (analyzer_id, check) :: rest))
    in
    let rec aux acc checks =
      match checks with
      | [] -> acc
      | (analyzer_id, (check : Check.t)) :: rest ->
        (* pick first check *)
        let conflict = Conflict.
          {
            kind = CrossStatus.PositiveAgreement; (* TODO: will be recomputed at the end, so this doesn't matter, but better to avoid the dummy value altogether *)
            range = check.range;
            title = check.title;
            from_po1 =
              (if analyzer_id = 1 then
                ChecksSet.singleton
                  (ConflictCheck.of_check check)
              else ChecksSet.empty);
            status_po1 =
              (if analyzer_id = 1 then
                Status.of_kind check.kind
              else Status.Unreached);
            from_po2 =
              (if analyzer_id = 2 then
                ChecksSet.singleton
                  (ConflictCheck.of_check check)
              else ChecksSet.empty);
            status_po2 =
              (if analyzer_id = 2 then
                Status.of_kind check.kind
              else Status.Unreached);
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
        let comp = Category.compare c1.title c2.title in
        if comp <> 0 then comp
        else Range.compare_file_position c1.range.start c2.range.start)
      checks
  in
  let conflicts =
    gather_conflicts checks (fun proofObligation ->
        let new_kind =
          CrossStatus.of_statuses proofObligation.status_po1 proofObligation.status_po2
        in
        {proofObligation with kind = new_kind})
  in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts
