(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  mutable result : Status.t option;
}
[@@deriving yojson_of]

type map = (ProofObligation.Category.t, t) Hashtbl.t

let yojson_of_map (h : map) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc ->
         let key = ProofObligation.Category.to_string k in
         let value = yojson_of_t v in
         (key, value) :: acc)
       h [])

type report = {
  global_result : t;
  results : map;
}
[@@deriving yojson_of]

let create () =
  {
    global_result = { result = None };
    results = Hashtbl.create 10;
  }

let update (result : t) (new_status : Status.t)
    =
  match result.result with
  | None ->
      result.result <- Some new_status
  | Some existing_kind ->
      let updated_kind = Status.pessimistic_join existing_kind new_status in
      result.result <- Some updated_kind

let update_map (table : map)
    (category : ProofObligation.Category.t) (new_status : Status.t)
    =
  match Hashtbl.find_opt table category with
  | Some result ->
      update result new_status
  | None ->
      let new_result = { result = None } in
      update new_result new_status;
      Hashtbl.add table category new_result
