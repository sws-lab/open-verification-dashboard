(** This module provides functions to compare proof obligations and identify
    conflicts. *)

open ProofObligation

module ConflictCheck = Conflict.ConflictCheck
module ChecksSet = Conflict.ChecksSet

type pre_conflict = {
  category : Category.t;
  range : Range.t;
  from_po1 : ChecksSet.t;
  from_po2 : ChecksSet.t;
}

let conflicts_between (w1 : ProofObligation.t) (w2 : ProofObligation.t) =
  let gather_conflicts checks f =
    let rec build_unique_conflict conflict = function
      | [] -> (conflict, [])
      | (analyzer_id, (check : Check.t)) :: rest -> (
        if
          Range.compare conflict.range check.range = 0
          && Category.compare conflict.category check.category = 0
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
          build_unique_conflict
            {
              conflict with
              from_po1;
              from_po2;
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
        let conflict =
          {
            range = check.range;
            category = check.category;
            from_po1 =
              (if analyzer_id = 1 then
                ChecksSet.singleton
                  (ConflictCheck.of_check check)
              else ChecksSet.empty);
            from_po2 =
              (if analyzer_id = 2 then
                ChecksSet.singleton
                  (ConflictCheck.of_check check)
              else ChecksSet.empty);
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
        else Range.compare_file_position c1.range.start c2.range.start)
      checks
  in
  let conflicts =
    gather_conflicts checks (fun pc ->
        let status_po1 =
          ChecksSet.fold (fun c acc -> Status.join (Status.of_kind c.ConflictCheck.kind) acc) pc.from_po1 Unreached
        in
        let status_po2 =
          ChecksSet.fold (fun c acc -> Status.join (Status.of_kind c.ConflictCheck.kind) acc) pc.from_po2 Unreached
        in
        let kind =
          CrossStatus.of_statuses status_po1 status_po2
        in
        Conflict.{
          kind;
          category = pc.category;
          range = pc.range;
          from_po1 = pc.from_po1;
          status_po1;
          from_po2 = pc.from_po2;
          status_po2;
        })
  in
  List.sort Conflict.(fun c1 c2 -> Range.compare c1.range c2.range) conflicts
