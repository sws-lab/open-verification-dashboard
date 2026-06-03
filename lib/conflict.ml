(** This module defines the conflict type and provides functions to create and
    manipulate conflicts. *)

open ProofObligation
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module ConflictCheck = struct
  type t = {
    kind : Kind.t;
    messages : string;
    range : Range.t;
    callstack : int;
  }
  [@@deriving show, yojson, ord]

  let pp fmt check =
    Format.fprintf fmt "@[<hov 2>%a (%d): %a@," Kind.pp check.kind
      check.callstack Range.pp check.range;
    if String.length check.messages > 0 then Format.fprintf fmt " @,- ";
    let words = String.split_on_char ' ' check.messages in
    List.iter (fun word -> Format.fprintf fmt "%s@;<1 0>" word) words;
    Format.fprintf fmt "@]"

  let of_check (check : Check.t) =
    {
      kind = check.kind;
      messages = check.messages;
      range = check.range;
      callstack = check.callstack;
    }
end

type kind =
  | NoConflictSafe [@name "NoConflictSafe"]
  | NoConflictWarning [@name "NoConflictWarning"]
  | NoConflictError [@name "NoConflictError"]
  | Unchecked [@name "Unchecked"]
  | OnlyOneProofObligation [@name "OnlyOneProofObligation"]
  | SafetyW1 [@name "SafetyW1"]
  | SafetyW2 [@name "SafetyW2"]
  | PrecisionW1 [@name "PrecisionW1"]
  | PrecisionW2 [@name "PrecisionW2"]
  | ErrorLevel [@name "ErrorLevel"]
[@@deriving show { with_path = false }, yojson]

let kind_of_yojson = Utils.string_t_of_yojson kind_of_yojson "Kind"
let yojson_of_kind = Utils.string_yojson_of_t yojson_of_kind

type verdict = Verdict.t [@@deriving show { with_path = false }, yojson]

let conflict_of_string s =
  match String.lowercase_ascii s with
  | "no_conflict_safe" -> Some NoConflictSafe
  | "no_conflict_warning" -> Some NoConflictWarning
  | "no_conflict_error" -> Some NoConflictError
  | "unchecked" -> Some Unchecked
  | "only_one_proof_obligation" -> Some OnlyOneProofObligation
  | "safety_w1" -> Some SafetyW1
  | "safety_w2" -> Some SafetyW2
  | "precision_w1" -> Some PrecisionW1
  | "precision_w2" -> Some PrecisionW2
  | "error_level" -> Some ErrorLevel
  | _ -> None

type t = {
  kind : kind;
  title : Category.t;
  range : Range.t;
  from_po1 : ConflictCheck.t list;
  verdict_po1 : verdict;
  from_po2 : ConflictCheck.t list;
  verdict_po2 : verdict;
}
[@@deriving show, yojson]

let pp_kind fmt kind = Format.fprintf fmt "@{<bold>@{<#f00>%a@}@}" pp_kind kind

let pp fmt conflict =
  Format.fprintf fmt "%a (%a):@.    %a @.    @[<v 2>" pp_kind conflict.kind
    Category.pp conflict.title Range.pp conflict.range;

  let pp_two_checks fmt conflict =
    Format.fprintf fmt
      "@{<#fff>ProofObligation 1 checks:@}@, @[<hov 4>%a@]@;<0 -2>"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
         ConflictCheck.pp)
      conflict.from_po1;
    Format.fprintf fmt "@{<#fff>ProofObligation 2 checks:@}@, @[<hov 4>%a@]"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
         ConflictCheck.pp)
      conflict.from_po2
  in

  match conflict.kind with
  | OnlyOneProofObligation ->
      if List.length conflict.from_po1 > 0 then
        Format.fprintf fmt
          "@{<#fff>Only ProofObligation 1 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list
             ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
             ConflictCheck.pp)
          conflict.from_po1
      else
        Format.fprintf fmt
          "@{<#fff>Only ProofObligation 2 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list
             ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
             ConflictCheck.pp)
          conflict.from_po2
  | PrecisionW1 ->
      Format.fprintf fmt
        "@{<#fff>ProofObligation 1 detects safe sub ranges that \
         ProofObligation 2 does not detect.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | PrecisionW2 ->
      Format.fprintf fmt
        "@{<#fff>ProofObligation 2 detects safe sub ranges that \
         ProofObligation 1 does not detect.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | SafetyW1 ->
      Format.fprintf fmt
        "@{<#fff>The two proofObligations disagree on the safety of the range. \
         Proof Obligation 1 state that it is safe wile Proof Obligation 2 does \
         not.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | SafetyW2 ->
      Format.fprintf fmt
        "@{<#fff>The two proofObligations disagree on the safety of the range. \
         Proof Obligation 2 state that it is safe wile Proof Obligation 1 does \
         not.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | ErrorLevel ->
      Format.fprintf fmt
        "@{<#fff>The two proofObligations disagree on the error level of the \
         range.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | Unchecked ->
      Format.fprintf fmt
        "@{<#fff>This has not been checked for conflicts yet.@}@;<0 -2>";
      pp_two_checks fmt conflict
  | NoConflictSafe ->
      Format.fprintf fmt "@{<#0f0>Safe: No conflict found.@}@;<0 -2>";
      pp_two_checks fmt conflict
  | NoConflictWarning ->
      Format.fprintf fmt
        "@{<#ff0>Warning: No conflict found, but they agree it's a warning.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | NoConflictError ->
      Format.fprintf fmt
        "@{<#f00>Error: No conflict found, but they agree it's an error.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict;

      Format.fprintf fmt "@]";
      Format.pp_print_newline fmt ()
