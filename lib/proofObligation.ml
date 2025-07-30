open Ppx_yojson_conv_lib.Yojson_conv.Primitives


module Range = struct
  type file_position = {
    line: int;
    column: int;
  }[@@deriving yojson_of, show, eq]

  let file_position_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Assoc fields -> (
      let line = List.assoc "line" fields in
      let column = List.assoc "column" fields in
      match line, column with
      | `Int l, `Int c -> { line = l; column = c }
      | _ -> failwith "Expected an associative array for file_position"
    )
    | _ -> failwith "Expected an associative array for file_position"

  type t = {
    file: string;
    start: file_position;
    end_: file_position [@key "end"];
  }
  [@@deriving yojson_of, show, eq]

  let t_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Assoc fields ->
      let start = List.assoc "start" fields in
      let end_ = List.assoc "end" fields in
      let file = List.assoc_opt "file" fields in (
      match file with
      | Some (`String file) ->
        let start_pos = file_position_of_yojson start in
        let end_pos = file_position_of_yojson end_ in
        { file; start = start_pos; end_ = end_pos }
      | None -> (
        match start with
        | `Assoc start_fields ->
          let file = List.assoc "file" start_fields in
          let start_pos = file_position_of_yojson (`Assoc start_fields) in
          let end_pos = file_position_of_yojson end_ in (
          match file with
          | `String file ->
            { file = file; start = start_pos; end_ = end_pos }
          | _ -> failwith "Expected a string for file")
        | _ -> failwith "Expected an associative array for start position")
      | _ -> failwith "Expected a string for file")
    | _ ->
        failwith "Expected an associative array for Range.t"
  (** Converts a JSON object to a Range.t. 
      This is made by hand because it can support multiple formats:
      - { "file": "path/to/file", "start": { "line": 1, "column": 0 }, "end": { "line": 2, "column": 5 } }
      - { "start": { "file": "path/to/file", "line": 1, "column": 0 }, "end": { "file": "path/to/file", "line": 2, "column": 5 } }
      Those two formats are equivalent, but the first one is the one used by the program and we want to support both.
  *)


  let union a b =
    if a.file <> b.file then
      failwith "Cannot union ranges from different files";
    {
      file = a.file;
      start = {
        line = min a.start.line b.start.line;
        column = min a.start.column b.start.column;
      };
      end_ = {
        line = max a.end_.line b.end_.line;
        column = max a.end_.column b.end_.column;
      };
    }
  (** Unions two ranges, assuming they are from the same file. *)

  let eq_or_includes a b =
    a.file = b.file &&
    a.start.line = b.start.line &&
    a.end_.line = b.end_.line && (
      (a.start.column <= b.start.column && a.end_.column >= b.end_.column) ||
      (a.start.column >= b.start.column && a.end_.column <= b.end_.column)
    )
  (** Checks if two ranges are equal or if one includes the other. *)


  let compare a b =
    if a.file <> b.file then
      compare a.file b.file
    else if eq_or_includes a b then
      0
    else if a.end_.line < b.end_.line then
      -1
    else if a.end_.line > b.end_.line then
      1
    else if a.end_.column < b.end_.column then
      -1
    else if a.end_.column > b.end_.column then
      1
    else
      failwith "Ranges are not comparable"

  let pp fmt range =
    Format.fprintf fmt "%s:%d.%d-%d.%d"
      range.file
      range.start.line
      (range.start.column + 1)
      range.end_.line
      (range.end_.column + 1)
  
  let pp fmt range =
    Format.fprintf fmt "@{<bold>%a@}"
      pp range
end

module Kind = struct
  type t =
    | Safe [@name "safe"]
    | Warning [@name "warning"]
    | Error [@name "error"]
  [@@deriving yojson, show { with_path = false }, ord]

  (* Safe < Warning < Error *)
  let max a b =
    match a, b with
    | _, Error | Error, _ -> Error
    | Safe, n | n, Safe -> n
    | Warning, Warning -> Warning
    
  let min a b =
    match a, b with
    | Safe, _ | _, Safe -> Safe
    | Error, n | n, Error -> n 
    | Warning, Warning -> Warning

  let is_safe = function
    | Safe -> true
    | _ -> false

  let pp fmt kind =
    Format.fprintf fmt (
    match kind with
    | Safe -> "@{<green>safe"
    | Warning -> "@{<yellow>warning"
    | Error -> "@{<red>error");
    Format.fprintf fmt "@}"

  let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Kind"
  let yojson_of_t = Utils.string_yojson_of_t yojson_of_t
end

module Category = struct
  type t = 
    | AssersionFaillure [@name "Assertion failure"]
    | InvalidMemoryAccess [@name "Invalid memory access"]
    | DivisionByZero [@name "Division by zero"]
    | IntegerOverflow [@name "Integer overflow"]
    | InvalidPointerComparison [@name "Invalid pointer comparison"]
    | InvalidPointerSubtraction [@name "Invalid pointer subtraction"]
    | DoubleFree [@name "Double free"]
    | NegativeArraySize [@name "Negative array size"]
    | InvalidFloatingPointOperation [@name "Invalid floating point operation"]
    | StubCondition [@name "Stub condition"]
    | InsuficientVariadicArguments [@name "Insufficient variadic arguments"]
    | InsuficientFormatArguments [@name "Insufficient format arguments"]
    | InvalidTypeOfFormatArgument [@name "Invalid type of format argument"]
    | FloatingpointDivisionByZero [@name "Floating-point division by zero"]
    | FloatingpointOverflow [@name "Floating-point overflow"]
    | IncorrectNumberOfArguments [@name "Incorrect number of arguments"]
    | InvalidShift [@name "Invalid shift"]
  [@@deriving yojson, show { with_path = false }, ord]

  let t_of_yojson = Utils.string_t_of_yojson t_of_yojson  "Category"
  let yojson_of_t = Utils.string_yojson_of_t yojson_of_t
end

module StackTrace = struct
  type t = int [@@deriving yojson_of, ord]

  let pp fmt stack_trace =
    Format.fprintf fmt "Stack trace: %d" stack_trace

  module StackSet = Hashtbl.Make(struct
    type t = string [@@deriving hash,eq]
  end)

  let stack_set = StackSet.create 16

  let reset () =
    StackSet.clear stack_set

  let add stack_trace =
    match StackSet.find_opt stack_set stack_trace with
    | Some n -> n
    | None ->
        let len = StackSet.length stack_set in
        StackSet.add stack_set stack_trace (len + 1);
        len + 1
  
  let t_of_yojson json =
    Yojson.Safe.to_string json
    |> add
end

module Check = struct
  type t = {
    kind: Kind.t;
    title: Category.t;
    messages: string;
    range: Range.t;
    callstack: StackTrace.t; [@default 0]
  } [@@deriving yojson, show, ord] [@@yojson.allow_extra_fields]

  let pp fmt check =
    Format.fprintf fmt "@[<hov 2>%a (%d): %a at %a@,"
      Kind.pp check.kind
      check.callstack
      Category.pp check.title
      Range.pp check.range;
    if String.length check.messages > 0 then
      Format.fprintf fmt " @,- ";
      let words = String.split_on_char ' ' check.messages in
      List.iter (fun word ->
        Format.fprintf fmt "%s@;<1 0>" word
      ) words;
      Format.fprintf fmt "@]"
end

module ProofObligation = struct
  type t = {
    name: string; [@default ""]
    time: float;
    checks: Check.t list;
  } [@@deriving yojson, ord ] [@@yojson.allow_extra_fields]

  let t_of_yojson =
    StackTrace.reset ();
    t_of_yojson
end

type t = ProofObligation.t


let of_file (file: string) =
  try
    let json = if file = "stdin" then
      Yojson.Safe.from_string @@ Option.value ~default:"" (In_channel.input_line stdin)
    else
      Yojson.Safe.from_file file
    in
    let po = ProofObligation.t_of_yojson json in
    Some({
      po with
      name = FilePath.basename @@ FilePath.chop_extension file;
    })
  with
  | Yojson.Json_error msg ->
      Format.eprintf "Error parsing JSON from file %s: %s\n" file msg;
      None
  | Ppx_yojson_conv_lib__Yojson_conv.Of_yojson_error(exn, json) -> (
    match exn with
    | Failure msg ->
        Format.eprintf "Error extracting proofObligation from file %s: %s\nJson: %s\n" file msg (Yojson.Safe.to_string json);
        None
    | _ ->
        raise exn)
  | Sys_error msg ->
      Format.eprintf "Error reading file %s: %s\n" file msg;
      None
  | Failure msg ->
      Format.eprintf "Error extracting proofObligation from file %s: %s\n" file msg;
      None
(**
  Reads a proof obligation from a file, parsing it as JSON.
  If the file is ["stdin"], it reads from standard input, one json object per line.
  Returns an option type, which is None if there was an error.
*)


let convert_paths ~exclude_not_found proofObligation project_path =
  if project_path = "" then
    proofObligation
  else
    let path_to_project_relative = Project.path_to_project_relative project_path in
    let convert_file_range_path (file_range: Range.t) =
      { file_range with
        file = path_to_project_relative file_range.file
      }
    in
    let open Check in
    ProofObligation.{
      proofObligation with
      checks = List.filter_map (fun check ->
        let range = convert_file_range_path check.range in
        if (exclude_not_found && (Project.Folder.mem Project.warned check.range.file)) || 
           range.start.column = -1 || range.start.line = -1 || range.end_.column = -1 || range.end_.line = -1 
        then
          None
        else
          Some ({ check with
          range
        })
      ) proofObligation.checks
    }
