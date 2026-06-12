open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  kind : Kind.t;
  category : Category.t; [@key "title"] (* title is legacy name *)
  messages : string;
  range : Range.t;
  callstack : StackTrace.t; [@default StackTrace.default]
}
[@@deriving yojson, show, ord] [@@yojson.allow_extra_fields]

let pp fmt check =
  Format.fprintf fmt "@[<hov 2>%a (%a): %a at %a@," Kind.pp check.kind
    StackTrace.pp check.callstack Category.pp check.category Range.pp check.range;
  if String.length check.messages > 0 then Format.fprintf fmt " @,- ";
  let words = String.split_on_char ' ' check.messages in
  List.iter (fun word -> Format.fprintf fmt "%s@;<1 0>" word) words;
  Format.fprintf fmt "@]"
