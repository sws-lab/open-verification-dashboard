(** This module defines the conflict type and provides functions to create and
    manipulate conflicts. *)

open Ovd_checks
module ComparisonStatus = Status
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module ConflictCheck = struct
  type t = {
    status : Status.Reachable.t; [@key "kind"] (* kind is legacy name *)
    messages : string;
    range : Range.t;
    callstack : StackTrace.t;
  }
  [@@deriving show, yojson, ord]

  let pp fmt check =
    Format.fprintf fmt "@[<hov 2>%a (%a): %a@," Status.Reachable.pp check.status
      StackTrace.pp check.callstack Range.pp check.range;
    if String.length check.messages > 0 then Format.fprintf fmt " @,- ";
    let words = String.split_on_char ' ' check.messages in
    List.iter (fun word -> Format.fprintf fmt "%s@;<1 0>" word) words;
    Format.fprintf fmt "@]"

  let of_check (check : Check.t) =
    {
      status = check.status;
      messages = check.messages;
      range = check.range;
      callstack = check.callstack;
    }
end

module ChecksSet =
struct
  include Set.Make (ConflictCheck)
  let yojson_of_t s = [%yojson_of: ConflictCheck.t list] (elements s)
  let t_of_yojson j = of_list ([%of_yojson: ConflictCheck.t list] j)
end

type status = ComparisonStatus.t [@@deriving show { with_path = false }, yojson]

type t = {
  kind : CrossStatus.t;
  category : Category.t; [@key "title"] (* title is legacy name *)
  range : Range.t;
  from_po1 : ChecksSet.t;
  status_po1 : status; [@key "verdict_po1"] (* verdict is legacy name *)
  from_po2 : ChecksSet.t;
  status_po2 : status; [@key "verdict_po2"] (* verdict is legacy name *)
}
[@@deriving yojson]

let pp_kind fmt kind = Format.fprintf fmt "@{<bold>@{<#f00>%a@}@}" CrossStatus.pp kind

let pp fmt conflict =
  Format.fprintf fmt "%a (%a):@.    %a @.    @[<v 2>" pp_kind conflict.kind
    Category.pp conflict.category Range.pp conflict.range;

  let pp_two_checks fmt conflict =
    Format.fprintf fmt
      "@{<#fff>ProofObligation 1 checks:@}@, @[<hov 4>%a@]@;<0 -2>"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
         ConflictCheck.pp)
      (ChecksSet.elements conflict.from_po1); (* TODO: no elements *)
    Format.fprintf fmt "@{<#fff>ProofObligation 2 checks:@}@, @[<hov 4>%a@]"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
         ConflictCheck.pp)
      (ChecksSet.elements conflict.from_po2); (* TODO: no elements *)
  in

  match conflict.kind with
  | CoverageDisagreement ->
      if not (ChecksSet.is_empty conflict.from_po1) then
        Format.fprintf fmt
          "@{<#fff>Only ProofObligation 1 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list
             ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
             ConflictCheck.pp)
          (ChecksSet.elements conflict.from_po1) (* TODO: no elements *)
      else
        Format.fprintf fmt
          "@{<#fff>Only ProofObligation 2 checked:@}@, @[<hov 4>%a@]"
          (Format.pp_print_list
             ~pp_sep:(fun fmt () -> Format.pp_print_break fmt 0 (-4))
             ConflictCheck.pp)
          (ChecksSet.elements conflict.from_po2) (* TODO: no elements *)
  | Contradiction ->
      Format.fprintf fmt
        "@{<#fff>The two proofObligations disagree on the safety of the range.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | PrecisionAsymmetry ->
      Format.fprintf fmt
        "@{<#fff>The two proofObligations disagree on the error level of the \
         range.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict
  | PositiveAgreement ->
      Format.fprintf fmt "@{<#0f0>Safe: No conflict found.@}@;<0 -2>";
      pp_two_checks fmt conflict
  | NegativeAgreement ->
      Format.fprintf fmt
        "@{<#ff0>Warning: No conflict found, but they agree it's a warning/error.@}@;\
         <0 -2>";
      pp_two_checks fmt conflict;

      (* TODO: isn't this only in the last case? *)
      Format.fprintf fmt "@]";
      Format.pp_print_newline fmt ()
