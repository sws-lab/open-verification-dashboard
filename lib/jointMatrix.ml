open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = int array array [@@deriving yojson]

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

let merge m1 m2 =
  Array.map2 (Array.map2 (+)) m1 m2

let selectivity ~warning ~error ~safe =
  let reachable = warning + error + safe in
  if reachable = 0 then
    None
  else
    Some (float_of_int safe /. float_of_int reachable)

let selectivity1 m =
  (* TODO: less hard-coding *)
  let warning = m.(0).(0) + m.(0).(1) + m.(0).(2) + m.(0).(3) in
  let error = m.(1).(0) + m.(1).(1) + m.(1).(2) + m.(1).(3) in
  let safe = m.(2).(0) + m.(2).(1) + m.(2).(2) + m.(2).(3) in
  selectivity ~warning ~error ~safe

let selectivity2 m =
  (* TODO: less hard-coding *)
  let warning = m.(0).(0) + m.(1).(0) + m.(2).(0) + m.(3).(0) in
  let error = m.(0).(1) + m.(1).(1) + m.(2).(1) + m.(3).(1) in
  let safe = m.(0).(2) + m.(1).(2) + m.(2).(2) + m.(3).(2) in
  selectivity ~warning ~error ~safe

let joint_selectivity m =
  (* TODO: less hard-coding *)
  let warning = m.(0).(0) in
  let error = m.(0).(1) + m.(1).(1) + m.(1).(0) in
  let safe = m.(0).(2) + m.(2).(2) + m.(2).(0) in
  selectivity ~warning ~error ~safe

let alignment m =
  (* TODO: less hard-coding *)
  assert (m.(3).(3) = 0);
  let agree = m.(0).(0) + m.(1).(1) + m.(2).(2) in
  let reachable = Array.fold_left (Array.fold_left (+)) 0 m in
  if reachable = 0 then
    None
  else
    Some (float_of_int agree /. float_of_int reachable)
