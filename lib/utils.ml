let string_yojson_of_t yojson_of_t kind =
  match yojson_of_t kind with
  | `List [l] -> l
  | _ -> failwith "Expected a list"

let string_t_of_yojson t_of_yojson name json =
  match json with
  | `String _ as kind ->
    t_of_yojson (`List [kind])
  | _ -> 
    failwith ("Expected a string value for " ^ name ^ ", got: " ^ Yojson.Safe.to_string json)