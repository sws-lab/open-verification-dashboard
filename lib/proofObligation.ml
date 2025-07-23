open Ppx_yojson_conv_lib.Yojson_conv.Primitives

let string_yojson_of_t yojson_of_t kind =
  match yojson_of_t kind with
  | `List [l] -> (match l with
    | `String s -> `List [`String s]
    | _ -> failwith "Expected a string for field ")
  | _ -> failwith "Expected a list"

let string_t_of_yojson t_of_yojson name json =
  match json with
  | `String _ as kind ->
    t_of_yojson (`List [kind])
  | _ -> 
    failwith ("Expected a string value for " ^ name ^ ", got: " ^ Yojson.Safe.to_string json)

module Range = struct
  type file_range = {
    line: int;
    column: int;
    file: string;
  }[@@deriving yojson, show, eq]

  type t = {
    start: file_range;
    end_: file_range [@key "end"];
  }[@@deriving yojson, show, eq]
  

  let pp fmt range =
    Format.fprintf fmt "%s:%d.%d-%d.%d"
      range.start.file
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
  [@@deriving yojson, show { with_path = false }, eq]

  (* Safe < Warning < Error *)
  let max a b =
    match a, b with
    | _, Error | Error, _ -> Error
    | Safe, n | n, Safe -> n
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

  let t_of_yojson = string_t_of_yojson t_of_yojson "Kind"

  let yojson_of_t t = string_yojson_of_t yojson_of_t t
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
  [@@deriving yojson, show { with_path = false }, ord]

  let t_of_yojson = string_t_of_yojson t_of_yojson  "Category"
  let yojson_of_t = string_yojson_of_t yojson_of_t
end

module StackTrace = struct
  type t = int [@@deriving yojson_of]

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
  } [@@deriving yojson, show] [@@yojson.allow_extra_fields]

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
  } [@@deriving yojson ] [@@yojson.allow_extra_fields]

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



let convert_paths ~exclude_not_found proofObligation project_path =
  if project_path = "" then
    proofObligation
  else
    let path_to_project_relative = Project.path_to_project_relative project_path in
    let convert_file_range_path (file_range: Range.file_range) =
      { file_range with
        file = path_to_project_relative file_range.file
      }
    in
    let open Check in
    ProofObligation.{
      proofObligation with
      checks = List.filter_map (fun check ->
        let start = convert_file_range_path check.range.start in
        let end_ = convert_file_range_path check.range.end_ in
        if exclude_not_found && (Project.Folder.mem Project.warned check.range.start.file) then
          None
        else
          Some ({ check with
          range = {
            start; 
            end_;
          }
        })
      ) proofObligation.checks
    }
