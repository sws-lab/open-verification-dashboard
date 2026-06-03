(** Definition of the OCaml proof obligation type. This module provides
    functions to create and manipulate proof obligations. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Range = struct
  type file_position = {
    line : int;
    column : int;
  }
  [@@deriving yojson_of, show, eq]

  let compare_file_position a b =
    if a.line <> b.line then compare a.line b.line
    else compare a.column b.column

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
end

module Kind = struct
  type t =
    | Safe [@name "safe"]
    | Warning [@name "warning"]
    | Error [@name "error"]
  [@@deriving yojson, show { with_path = false }, ord]

  (* Safe < Error < Warning *)
  let max a b =
    match (a, b) with
    | Warning, _ | _, Warning -> Warning
    | Safe, other | other, Safe -> other
    | Error, Error -> Error

  let min a b =
    match (a, b) with
    | Safe, _ | _, Safe -> Safe
    | Warning, other | other, Warning -> other
    | Error, Error -> Error

  let is_safe = function
    | Safe -> true
    | _ -> false

  let pp fmt kind =
    Format.fprintf fmt
      (match kind with
      | Safe -> "@{<green>safe"
      | Warning -> "@{<yellow>warning"
      | Error -> "@{<red>error");
    Format.fprintf fmt "@}"

  let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Kind"
  let yojson_of_t = Utils.string_yojson_of_t yojson_of_t
end

module Category = struct
  type t =
    | AssertionFailure [@name "Assertion failure"]
    | InvalidMemoryAccess [@name "Invalid memory access"]
    | DivisionByZero [@name "Division by zero"]
    | SignedIntegerOverflowInArithmeticOperator [@name "Signed integer overflow in arithmetic operator"]
    | SignedIntegerOverflowInExplicitCast [@name "Signed integer overflow in explicit cast"]
    | SignedIntegerOverflowInImplicitCast [@name "Signed integer overflow in implicit cast"]
    | UnsignedIntegerOverflowInArithmeticOperator [@name "Unsigned integer overflow in arithmetic operator"]
    | UnsignedIntegerOverflowInExplicitCast [@name "Unsigned integer overflow in explicit cast"]
    | UnsignedIntegerOverflowInImplicitCast [@name "Unsigned integer overflow in implicit cast"]
    | InvalidPointerComparison [@name "Invalid pointer comparison"]
    | InvalidPointerSubtraction [@name "Invalid pointer subtraction"]
    | DoubleFree [@name "Double free"]
    | NegativeArraySize [@name "Negative array size"]
    | InvalidFloatingPointOperation [@name "Invalid floating point operation"]
    | StubCondition [@name "Stub condition"]
    | InsufficientVariadicArguments [@name "Insufficient variadic arguments"]
    | InsufficientFormatArguments [@name "Insufficient format arguments"]
    | InvalidTypeOfFormatArgument [@name "Invalid type of format argument"]
    | FloatingpointDivisionByZero [@name "Floating-point division by zero"]
    | FloatingpointOverflow [@name "Floating-point overflow"]
    | IncorrectNumberOfArguments [@name "Incorrect number of arguments"]
    | InvalidShift [@name "Invalid shift"]
  [@@deriving yojson, show { with_path = false }, ord]

  let t_of_yojson = Utils.string_t_of_yojson t_of_yojson "Category"
  let yojson_of_t = Utils.string_yojson_of_t yojson_of_t

  let of_string s =
    match String.lowercase_ascii s with
    | "assertion_failure" -> Some AssertionFailure
    | "invalid_memory_access" -> Some InvalidMemoryAccess
    | "division_by_zero" -> Some DivisionByZero
    | "signed_integer_overflow_in_arithmetic_operator" -> Some SignedIntegerOverflowInArithmeticOperator
    | "signed_integer_overflow_in_explicit_cast" -> Some SignedIntegerOverflowInExplicitCast
    | "signed_integer_overflow_in_implicit_cast" -> Some SignedIntegerOverflowInImplicitCast
    | "unsigned_integer_overflow_in_arithmetic_operator" -> Some UnsignedIntegerOverflowInArithmeticOperator
    | "unsigned_integer_overflow_in_explicit_cast" -> Some UnsignedIntegerOverflowInExplicitCast
    | "unsigned_integer_overflow_in_implicit_cast" -> Some UnsignedIntegerOverflowInImplicitCast
    | "invalid_pointer_comparison" -> Some InvalidPointerComparison
    | "invalid_pointer_subtraction" -> Some InvalidPointerSubtraction
    | "double_free" -> Some DoubleFree
    | "negative_array_size" -> Some NegativeArraySize
    | "invalid_floating_point_operation" -> Some InvalidFloatingPointOperation
    | "stub_condition" -> Some StubCondition
    | "insufficient_variadic_arguments" -> Some InsufficientVariadicArguments
    | "insufficient_format_arguments" -> Some InsufficientFormatArguments
    | "invalid_type_of_format_argument" -> Some InvalidTypeOfFormatArgument
    | "floatingpoint_division_by_zero" -> Some FloatingpointDivisionByZero
    | "floatingpoint_overflow" -> Some FloatingpointOverflow
    | "incorrect_number_of_arguments" -> Some IncorrectNumberOfArguments
    | "invalid_shift" -> Some InvalidShift
    | _ -> None

  let to_string = function
    | AssertionFailure -> "Assertion failure"
    | InvalidMemoryAccess -> "Invalid memory access"
    | DivisionByZero -> "Division by zero"
    | SignedIntegerOverflowInArithmeticOperator -> "Signed integer overflow in arithmetic operator"
    | SignedIntegerOverflowInExplicitCast -> "Signed integer overflow in explicit cast"
    | SignedIntegerOverflowInImplicitCast -> "Signed integer overflow in implicit cast"
    | UnsignedIntegerOverflowInArithmeticOperator -> "Unsigned integer overflow in arithmetic operator"
    | UnsignedIntegerOverflowInExplicitCast -> "Unsigned integer overflow in explicit cast"
    | UnsignedIntegerOverflowInImplicitCast -> "Unsigned integer overflow in implicit cast"
    | InvalidPointerComparison -> "Invalid pointer comparison"
    | InvalidPointerSubtraction -> "Invalid pointer subtraction"
    | DoubleFree -> "Double free"
    | NegativeArraySize -> "Negative array size"
    | InvalidFloatingPointOperation -> "Invalid floating point operation"
    | StubCondition -> "Stub condition"
    | InsufficientVariadicArguments -> "Insufficient variadic arguments"
    | InsufficientFormatArguments -> "Insufficient format arguments"
    | InvalidTypeOfFormatArgument -> "Invalid type of format argument"
    | FloatingpointDivisionByZero -> "Floating-point division by zero"
    | FloatingpointOverflow -> "Floating-point overflow"
    | IncorrectNumberOfArguments -> "Incorrect number of arguments"
    | InvalidShift -> "Invalid shift"
end

module StackTrace = struct
  type t = int [@@deriving yojson_of, ord]

  let pp fmt stack_trace = Format.fprintf fmt "Stack trace: %d" stack_trace

  module StackSet = Hashtbl.Make (struct
    type t = string [@@deriving hash, eq]
  end)

  let stack_set = StackSet.create 16
  let reset () = StackSet.clear stack_set

  let add stack_trace =
    match StackSet.find_opt stack_set stack_trace with
    | Some n -> n
    | None ->
        let len = StackSet.length stack_set in
        StackSet.add stack_set stack_trace (len + 1);
        len + 1

  let t_of_yojson json = Yojson.Safe.to_string json |> add
end

module Check = struct
  type t = {
    kind : Kind.t;
    title : Category.t;
    messages : string;
    range : Range.t;
    callstack : StackTrace.t; [@default 0]
  }
  [@@deriving yojson, show, ord] [@@yojson.allow_extra_fields]

  let pp fmt check =
    Format.fprintf fmt "@[<hov 2>%a (%d): %a at %a@," Kind.pp check.kind
      check.callstack Category.pp check.title Range.pp check.range;
    if String.length check.messages > 0 then Format.fprintf fmt " @,- ";
    let words = String.split_on_char ' ' check.messages in
    List.iter (fun word -> Format.fprintf fmt "%s@;<1 0>" word) words;
    Format.fprintf fmt "@]"
end

module ProofObligation = struct
  type t = {
    name : string; [@default ""]
    time : float;
    checks : Check.t list;
  }
  [@@deriving yojson, ord] [@@yojson.allow_extra_fields]

  let t_of_yojson =
    StackTrace.reset ();
    t_of_yojson
end

type t = ProofObligation.t

(** Reads a proof obligation from a file, parsing it as JSON. If the file is
    ["stdin"], it reads from standard input, one json object per line. Returns
    an option type, which is None if there was an error. *)
let of_file (file : string) =
  try
    let json =
      if file = "stdin" then
        Yojson.Safe.from_string
        @@ Option.value ~default:"" (In_channel.input_line stdin)
      else Yojson.Safe.from_file file
    in
    let po = ProofObligation.t_of_yojson json in
    Some { po with name = Filename.basename @@ Filename.chop_extension file }
  with
  | Yojson.Json_error msg ->
      Format.eprintf "Error parsing JSON from file %s: %s\n" file msg;
      None
  | Ppx_yojson_conv_lib__Yojson_conv.Of_yojson_error (exn, json) -> (
      match exn with
      | Failure msg ->
          Format.eprintf
            "Error extracting proofObligation from file %s: %s\nJson: %s\n" file
            msg
            (Yojson.Safe.to_string json);
          None
      | _ -> raise exn)
  | Sys_error msg ->
      Format.eprintf "Error reading file %s: %s\n" file msg;
      None
  | Failure msg ->
      Format.eprintf "Error extracting proofObligation from file %s: %s\n" file
        msg;
      None
