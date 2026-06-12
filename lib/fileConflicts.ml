type t = (string, Conflict.t list) Hashtbl.t

let yojson_of_t (h : t) =
  `Assoc
    (Hashtbl.fold
       (fun k v acc -> (k, `List (List.map Conflict.yojson_of_t v)) :: acc)
       h [])

let t_of_yojson = function
  | `Assoc l ->
      let tbl = Hashtbl.create 10 in
      List.iter
        (function
          | (k : string), `List v ->
              let conflicts = List.map Conflict.t_of_yojson v in
              Hashtbl.add tbl k conflicts
          | _ -> failwith "Expected a string key and a list of conflicts")
        l;
      tbl
  | _ -> failwith "Expected an associative list for conflicts"

(** Add a conflict to the report global conflicts table *)
let add_conflict (conflicts : t) (conflict : Conflict.t) =
  let file = conflict.range.file in
  let existing = Hashtbl.find_opt conflicts file in
  match existing with
  | Some existing_conflicts ->
      Hashtbl.replace conflicts file (conflict :: existing_conflicts)
  | None ->
      Format.eprintf "Writing conflicts for file %s@." file;
      Hashtbl.add conflicts file [ conflict ]
