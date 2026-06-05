(** Definition of the OCaml proof obligation type. This module provides
    functions to create and manipulate proof obligations. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Range = Range
module Kind =  Kind
module Category = Category
module StackTrace = StackTrace
module Check = Check
module Utils = Utils

type t = {
  name : string; [@default ""]
  time : float;
  checks : Check.t list;
}
[@@deriving yojson, ord] [@@yojson.allow_extra_fields]

let t_of_yojson =
  StackTrace.reset ();
  t_of_yojson

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
    let po = t_of_yojson json in
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

let filter_checks (checks : Check.t list)
    (filter_error_category : Category.t list) =
  match filter_error_category with
  | [] -> checks
  | _ ->
      let error_category_set =
        Hashtbl.of_seq
          (List.to_seq filter_error_category |> Seq.map (fun el -> (el, ())))
      in
      List.filter
        (fun (check : Check.t) ->
          Hashtbl.mem error_category_set check.title)
        checks
