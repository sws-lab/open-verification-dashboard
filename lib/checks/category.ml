open Ovd_common

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
[@@deriving yojson, show { with_path = false }, ord, enum]

let equal: t -> t -> bool = (=)
let hash: t -> int = Hashtbl.hash

let t_of_yojson = OvdYojson.string_t_of_yojson t_of_yojson "Category"
let yojson_of_t = OvdYojson.string_yojson_of_t yojson_of_t

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
