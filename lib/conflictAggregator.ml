module type S =
sig
  type t

  val add_conflict: t -> Conflict.t -> unit
  val merge: t -> t -> t
end

module type YojsonS =
sig
  type t [@@deriving yojson]

  include S with type t := t
end


module type ConflictGroup =
sig
  include Hashtbl.HashedType

  val to_string: t -> string
  val of_string: string -> t

  val of_conflict: Conflict.t -> t
end

module type GroupS =
sig
  include YojsonS
  val create: unit -> t
end

module MakeGrouped (Group: ConflictGroup) (Aggregator: GroupS) =
struct
  module GroupTbl = Hashtbl.Make (Group)
  type t = Aggregator.t GroupTbl.t

  let yojson_of_t (h : t) =
    `Assoc
      (GroupTbl.fold
        (fun k v acc ->
          let key = Group.to_string k in
          let value = Aggregator.yojson_of_t v in
          (key, value) :: acc)
        h [])

  let t_of_yojson: Yojson.Safe.t -> t = function
    | `Assoc l ->
      List.to_seq l
      |> Seq.map (fun (k, v) -> (Group.of_string k, Aggregator.t_of_yojson v))
      |> GroupTbl.of_seq
    | _ -> failwith "map_of_yojson"

  let merge map1 map2 =
    let h = GroupTbl.create (GroupTbl.length map1 + GroupTbl.length map2) in
    let f =
      GroupTbl.iter (fun k v ->
          let v0 = match GroupTbl.find_opt h k with
            | Some v0 -> v0
            | None -> Aggregator.create ()
          in
          GroupTbl.replace h k (Aggregator.merge v0 v)
        )
    in
    f map1;
    f map2;
    h

  let add_conflict (table : t) (conflict : Conflict.t)
      =
    let group = Group.of_conflict conflict in
    match GroupTbl.find_opt table group with
    | Some result ->
        Aggregator.add_conflict result conflict
    | None ->
        let new_result = Aggregator.create () in
        Aggregator.add_conflict new_result conflict;
        GroupTbl.add table group new_result

  let create () = GroupTbl.create 10
end
