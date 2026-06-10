(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  mutable optimistic_status : Status.t option;
  mutable pessimistic_status : Status.t option;
  joint_matrix : JointMatrix.t;
  mutable selectivity1 : float option;
  mutable selectivity2 : float option;
  mutable joint_selectivity : float option;
  mutable alignment : float option;
}
[@@deriving yojson]

let create () =
  { optimistic_status = None; pessimistic_status = None; joint_matrix = JointMatrix.create (); selectivity1 = None; selectivity2 = None; joint_selectivity = None; alignment = None }

let merge ms1 ms2 =
  let joint_matrix = JointMatrix.merge ms1.joint_matrix ms2.joint_matrix in
  {
    joint_matrix;
    optimistic_status = None; (* TODO *)
    pessimistic_status = None; (* TODO *)
  (* TODO: don't recompute each time *)
    selectivity1 = JointMatrix.selectivity1 joint_matrix;
    selectivity2 = JointMatrix.selectivity2 joint_matrix;
    joint_selectivity = JointMatrix.joint_selectivity joint_matrix;
    alignment = JointMatrix.alignment joint_matrix
  }

type map = (ProofObligation.Category.t, t) Hashtbl.t

let yojson_of_map (h : map) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc ->
         let key = ProofObligation.Category.to_string k in
         let value = yojson_of_t v in
         (key, value) :: acc)
       h [])

let map_of_yojson: Yojson.Safe.t -> map = function
  | `Assoc l ->
    List.to_seq l
    |> Seq.map (fun (k, v) -> (ProofObligation.Category.t_of_yojson (`String k), t_of_yojson v))
    |> Hashtbl.of_seq
  | _ -> failwith "map_of_yojson"

let create_map () = Hashtbl.create 10

let merge_map map1 map2 =
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

let update (result : t) (conflict : Conflict.t) =
  let optimistic_status =
    Status.meet conflict.status_po1 conflict.status_po2
  in
  result.optimistic_status <- Some (Option.fold ~none:optimistic_status ~some:(Status.join optimistic_status) result.optimistic_status);
  let pessimistic_status =
    Status.join conflict.status_po1 conflict.status_po2
  in
  result.pessimistic_status <- Some (Option.fold ~none:pessimistic_status ~some:(Status.join pessimistic_status) result.pessimistic_status);
  JointMatrix.add result.joint_matrix conflict.status_po1 conflict.status_po2;
  (* TODO: don't recompute each time *)
  result.selectivity1 <- JointMatrix.selectivity1 result.joint_matrix;
  result.selectivity2 <- JointMatrix.selectivity2 result.joint_matrix;
  result.joint_selectivity <- JointMatrix.joint_selectivity result.joint_matrix;
  result.alignment <- JointMatrix.alignment result.joint_matrix

let update_map (table : map) (conflict : Conflict.t)
    =
  match Hashtbl.find_opt table conflict.category with
  | Some result ->
      update result conflict
  | None ->
      let new_result = create () in
      update new_result conflict;
      Hashtbl.add table conflict.category new_result
