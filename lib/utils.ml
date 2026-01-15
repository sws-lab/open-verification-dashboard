let string_yojson_of_t yojson_of_t kind =
  match yojson_of_t kind with
  | `List [l] -> l
  | _ -> failwith "Expected a list"
(**
  Utility function to convert a JSON representation of the form [`List [`String s]] to [`String s].
  This is useful for converting JSON objects that are outputted as lists by yojson_ppx into the expected string format.
*)

let string_t_of_yojson t_of_yojson name json =
  match json with
  | `String _ as kind ->
    t_of_yojson (`List [kind])
  | _ -> 
    failwith ("Expected a string value for " ^ name ^ ", got: " ^ Yojson.Safe.to_string json)
(**
  Utility function to convert a JSON representation of the form [`String s] to a form [`List [`String s]].
  This is useful for converting JSON objects that are expected to be a single string in the file into the expected yojson_ppx list format.
*)