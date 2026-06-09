(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  mutable optimistic_status : Status.t option;
  mutable pessimistic_status : Status.t option;
  joint_matrix : JointMatrix.t;
}
[@@deriving yojson_of]

let create () =
  { optimistic_status = None; pessimistic_status = None; joint_matrix = JointMatrix.create () }

type map = (ProofObligation.Category.t, t) Hashtbl.t

let yojson_of_map (h : map) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc ->
         let key = ProofObligation.Category.to_string k in
         let value = yojson_of_t v in
         (key, value) :: acc)
       h [])

let create_map () = Hashtbl.create 10

let update (result : t) (conflict : Conflict.t) =
  let optimistic_status =
    Status.meet conflict.status_po1 conflict.status_po2
  in
  result.optimistic_status <- Some (Option.fold ~none:optimistic_status ~some:(Status.join optimistic_status) result.optimistic_status);
  let pessimistic_status =
    Status.join conflict.status_po1 conflict.status_po2
  in
  result.pessimistic_status <- Some (Option.fold ~none:pessimistic_status ~some:(Status.join pessimistic_status) result.pessimistic_status);
  JointMatrix.add result.joint_matrix conflict.status_po1 conflict.status_po2

let update_map (table : map) (conflict : Conflict.t)
    =
  match Hashtbl.find_opt table conflict.category with
  | Some result ->
      update result conflict
  | None ->
      let new_result = create () in
      update new_result conflict;
      Hashtbl.add table conflict.category new_result
