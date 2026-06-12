(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

include JointMatrix

let yojson_of_t joint_matrix =
  `Assoc [
    ("optimistic_status", [%yojson_of: Status.t option] (JointMatrix.optimistic_status joint_matrix));
    ("pessimistic_status", [%yojson_of: Status.t option] (JointMatrix.pessimistic_status joint_matrix));
    ("joint_matrix", JointMatrix.yojson_of_t joint_matrix);
    ("selectivity1", [%yojson_of: float option] (JointMatrix.selectivity1 joint_matrix));
    ("selectivity2", [%yojson_of: float option] (JointMatrix.selectivity2 joint_matrix));
    ("joint_selectivity", [%yojson_of: float option] (JointMatrix.joint_selectivity joint_matrix));
    ("alignment", [%yojson_of: float option] (JointMatrix.alignment joint_matrix));
  ]

let t_of_yojson j =
  JointMatrix.t_of_yojson (Yojson.Safe.Util.member "joint_matrix" j)


module CategoryMap =
struct
  type meta_status = t
  type t = (ProofObligation.Category.t, meta_status) Hashtbl.t

  let yojson_of_t (h : t) =
    `Assoc
      (Hashtbl.fold
        (fun k v acc ->
          let key = ProofObligation.Category.to_string k in
          let value = yojson_of_t v in
          (key, value) :: acc)
        h [])

  let t_of_yojson: Yojson.Safe.t -> t = function
    | `Assoc l ->
      List.to_seq l
      |> Seq.map (fun (k, v) -> (ProofObligation.Category.t_of_yojson (`String k), t_of_yojson v))
      |> Hashtbl.of_seq
    | _ -> failwith "map_of_yojson"

  let merge map1 map2 =
    let h = Hashtbl.create (Hashtbl.length map1 + Hashtbl.length map2) in
    let f =
      Hashtbl.iter (fun k v ->
          let v0 = match Hashtbl.find_opt h k with
            | Some v0 -> v0
            | None -> create ()
          in
          Hashtbl.replace h k (merge v0 v)
        )
    in
    f map1;
    f map2;
    h

  let add_conflict (table : t) (conflict : Conflict.t)
      =
    match Hashtbl.find_opt table conflict.category with
    | Some result ->
        add_conflict result conflict
    | None ->
        let new_result = create () in
        add_conflict new_result conflict;
        Hashtbl.add table conflict.category new_result

  let create () = Hashtbl.create 10
end
