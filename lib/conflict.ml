open ProofObligation
open Ppx_yojson_conv_lib.Yojson_conv.Primitives


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


type t = {
  kind: kind;
  range: Range.t;
  from_po1: Check.t list;
  from_po2: Check.t list;
}
[@@deriving show, yojson]

let pp_kind fmt kind =
  Format.fprintf fmt "@{<bold>@{<#f00>%a@}@}"
    pp_kind kind

let pp fmt conflict =
  Format.fprintf fmt
    "%a (%a): @.    @[<v 2>" pp_kind conflict.kind Range.pp conflict.range;
  
  let pp_two_checks fmt conflict =
    Format.fprintf fmt "@{<#fff>ProofObligation 1 checks:@}@, @[<hov 4>%a@]@;<0 -2>"
      (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_po1;
    Format.fprintf fmt "@{<#fff>ProofObligation 2 checks:@}@, @[<hov 4>%a@]"
      (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_po2
  in

  match conflict.kind with
  | OnlyOneProofObligation ->
    if List.length conflict.from_po1 > 0 then
      Format.fprintf fmt "@{<#fff>Only ProofObligation 1 checked:@}@, @[<hov 4>%a@]"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_po1
    else
      Format.fprintf fmt "@{<#fff>Only ProofObligation 2 checked:@}@, @[<hov 4>%a@]"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4)) Check.pp) conflict.from_po2;
  | PrecisionW1 ->
    Format.fprintf fmt "@{<#fff>ProofObligation 1 detects safe sub ranges that ProofObligation 2 does not detect.@}@;<0 -2>";
    pp_two_checks fmt conflict;
  | PrecisionW2 ->
    Format.fprintf fmt "@{<#fff>ProofObligation 2 detects safe sub ranges that ProofObligation 1 does not detect.@}@;<0 -2>";
    pp_two_checks fmt conflict;
  | SafetyW1 ->
    Format.fprintf fmt "@{<#fff>The two proofObligations disagree on the safety of the range. Proof Obligation 1 state that it is safe wile Proof Obligation 2 does not.@}@;<0 -2>";
    pp_two_checks fmt conflict;
  | SafetyW2 ->
    Format.fprintf fmt "@{<#fff>The two proofObligations disagree on the safety of the range. Proof Obligation 2 state that it is safe wile Proof Obligation 1 does not.@}@;<0 -2>";
    pp_two_checks fmt conflict;
  | ErrorLevel ->
    Format.fprintf fmt "@{<#fff>The two proofObligations disagree on the error level of the range.@}@;<0 -2>";
    pp_two_checks fmt conflict;
  | Unchecked ->
    Format.fprintf fmt "@{<#fff>This has not been checked for conflicts yet.@}";
  | NoConflictSafe ->
    Format.fprintf fmt "@{<#0f0>Safe: No conflict found.@}";
  | NoConflictWarning ->
    Format.fprintf fmt "@{<#ff0>Warning: No conflict found, but they agree it's a warning.@}";
  | NoConflictError ->
    Format.fprintf fmt "@{<#f00>Error: No conflict found, but they agree it's an error.@}";

  Format.fprintf fmt "@]";
  Format.pp_print_newline fmt ()