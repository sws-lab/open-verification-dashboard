(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  mutable result : Status.t option;
  mutable conflict : bool;
}

let yojson_of_t {result; conflict} =
  let verdict =
    match result with
    | Some Safe -> "yes"
    | Some Warning | Some Error -> "no"
    | Some Unreached | None -> "unknown"
  in
  `Assoc [
    ("result", [%yojson_of: Status.t option] result);
    ("verdict", `String verdict); (* TODO: remove this redundant field, causes output diffs *)
    ("conflict", [%yojson_of: bool] conflict);
  ]


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
    global_result = { conflict = false; result = None };
    results = Hashtbl.create 10;
  }

let update (result : t) (new_status : Status.t)
    (conflict : bool)
    (update_function : Status.t -> Status.t -> Status.t)
    =
  if conflict then result.conflict <- true;
  match result.result with
  | None ->
      result.result <- Some new_status
  | Some existing_kind ->
      let updated_kind = update_function existing_kind new_status in
      result.result <- Some updated_kind

let update_map (table : map)
    (category : ProofObligation.Category.t) (new_status : Status.t)
    (conflict : bool)
    (update_function : Status.t -> Status.t -> Status.t)
    =
  match Hashtbl.find_opt table category with
  | Some result ->
      update result new_status conflict update_function
  | None ->
      let new_result = { conflict = false; result = None } in
      update new_result new_status conflict update_function;
      Hashtbl.add table category new_result
