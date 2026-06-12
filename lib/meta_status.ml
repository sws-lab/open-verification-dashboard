(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  mutable optimistic_status : Status.t option; [@default None]
  mutable pessimistic_status : Status.t option; [@default None]
  joint_matrix : JointMatrix.t;
  mutable selectivity1 : float option; [@default None]
  mutable selectivity2 : float option; [@default None]
  mutable joint_selectivity : float option; [@default None]
  mutable alignment : float option; [@default None]
}
[@@deriving yojson]

let create () =
  { optimistic_status = None; pessimistic_status = None; joint_matrix = JointMatrix.create (); selectivity1 = None; selectivity2 = None; joint_selectivity = None; alignment = None }

let add_conflict (result : t) (conflict : Conflict.t) =
  JointMatrix.add_conflict result.joint_matrix conflict;
  (* TODO: don't recompute each time *)
  result.optimistic_status <- JointMatrix.optimistic_status result.joint_matrix;
  result.pessimistic_status <- JointMatrix.pessimistic_status result.joint_matrix;
  result.selectivity1 <- JointMatrix.selectivity1 result.joint_matrix;
  result.selectivity2 <- JointMatrix.selectivity2 result.joint_matrix;
  result.joint_selectivity <- JointMatrix.joint_selectivity result.joint_matrix;
  result.alignment <- JointMatrix.alignment result.joint_matrix

let merge ms1 ms2 =
  let joint_matrix = JointMatrix.merge ms1.joint_matrix ms2.joint_matrix in
  {
    joint_matrix;
    (* TODO: don't recompute each time *)
    optimistic_status = JointMatrix.optimistic_status joint_matrix;
    pessimistic_status = JointMatrix.pessimistic_status joint_matrix;
    selectivity1 = JointMatrix.selectivity1 joint_matrix;
    selectivity2 = JointMatrix.selectivity2 joint_matrix;
    joint_selectivity = JointMatrix.joint_selectivity joint_matrix;
    alignment = JointMatrix.alignment joint_matrix
  }

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
