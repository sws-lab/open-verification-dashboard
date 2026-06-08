open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = int array array [@@deriving yojson_of]

let create () = Array.make_matrix 4 4 0

let add (matrix : t) status_po1 status_po2 =
  let po_status_to_id = function
    | Status.Warning -> 0
    | Status.Error -> 1
    | Status.Safe -> 2
    | _ -> 3
  in
  let id1 = po_status_to_id status_po1 in
  let id2 = po_status_to_id status_po2 in
  matrix.(id1).(id2) <- matrix.(id1).(id2) + 1
