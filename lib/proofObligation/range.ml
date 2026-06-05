open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type file_position = {
  line : int;
  column : int;
}
[@@deriving yojson_of, show, eq, ord]

let min_file_position a b = if compare_file_position a b < 0 then a else b
let max_file_position a b = if compare_file_position a b > 0 then a else b

let file_position_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc fields -> (
      let line = List.assoc "line" fields in
      let column = List.assoc "column" fields in
      match (line, column) with
      | `Int l, `Int c -> { line = l; column = c }
      | _ -> failwith "Expected an associative array for file_position")
  | _ -> failwith "Expected an associative array for file_position"

type t = {
  file : string;
  start : file_position;
  end_ : file_position; [@key "end"]
}
[@@deriving yojson_of, eq]

let pp fmt range =
  Format.fprintf fmt "%s:%d.%d-%d.%d" range.file range.start.line
    (range.start.column + 1) range.end_.line (range.end_.column + 1)

let pp fmt range = Format.fprintf fmt "@{<bold>%a@}" pp range

(** Converts a JSON object to a Range.t.
    This is made by hand because it can support multiple formats:
    - { "file": "path/to/file", "start": { "line": 1, "column": 0 }, "end": { "line": 2, "column": 5 } }
    - { "start": { "file": "path/to/file", "line": 1, "column": 0 }, "end": { "file": "path/to/file", "line": 2, "column": 5 } }
    Those two formats are equivalent, but the first one is the one used by the program and we want to support both.
*)
let t_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc fields -> (
      let start = List.assoc "start" fields in
      let end_ = List.assoc "end" fields in
      let file = List.assoc_opt "file" fields in
      match file with
      | Some (`String file) ->
          let start_pos = file_position_of_yojson start in
          let end_pos = file_position_of_yojson end_ in
          { file; start = start_pos; end_ = end_pos }
      | None -> (
          match start with
          | `Assoc start_fields -> (
              let file = List.assoc "file" start_fields in
              let start_pos = file_position_of_yojson (`Assoc start_fields) in
              let end_pos = file_position_of_yojson end_ in
              match file with
              | `String file -> { file; start = start_pos; end_ = end_pos }
              | _ -> failwith "Expected a string for file")
          | _ -> failwith "Expected an associative array for start position")
      | _ -> failwith "Expected a string for file")
  | _ -> failwith "Expected an associative array for Range.t"

(** Unions two ranges, assuming they are from the same file. *)
let union a b =
  if a.file <> b.file then failwith "Cannot union ranges from different files";
  {
    file = a.file;
    start = min_file_position a.start b.start;
    end_ = max_file_position a.end_ b.end_;
  }

(** Checks if two ranges overlap *)
let overlap a b =
  a.file = b.file
  && compare_file_position
        (max_file_position a.start b.start)
        (min_file_position a.end_ b.end_)
      <= 0

let compare a b =
  if a.file <> b.file then compare a.file b.file
  else if overlap a b then 0
  else if compare_file_position a.end_ b.start < 0 then -1
  else if compare_file_position a.start b.end_ > 0 then 1
  else (
    Format.eprintf "Ranges are not comparable: %a and %a\n" pp a pp b;
    exit 1)
