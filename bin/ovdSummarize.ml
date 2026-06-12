open Dashboard

type t = {
  global_result : Meta_status.t;
  category_results : Meta_status.CategoryMap.t;
}
[@@deriving yojson] [@@yojson.allow_extra_fields]

let create () =
  {
    global_result = Meta_status.create ();
    category_results = Meta_status.CategoryMap.create ();
  }

let merge r1 r2 =
  {
    global_result = Meta_status.merge r1.global_result r2.global_result;
    category_results = Meta_status.CategoryMap.merge r1.category_results r2.category_results;
  }

let summarize ~comparison_files ~format:_: (int, string) result =
  try
    let summary =
      Array.of_list comparison_files
      |> Globlon.globs ~glob_nosort:true
      |> Array.to_seq
      |> Seq.map Yojson.Safe.from_file
      |> Seq.map t_of_yojson
      |> Seq.fold_left merge (create ())
    in
    Yojson.Safe.to_channel ~suf:"\n" stdout (yojson_of_t summary);
    flush stdout;
    Ok 0
  with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (e, j) ->
    Error (Printexc.to_string e ^ Yojson.Safe.to_string j)


open Cmdliner
open Cmdliner.Term.Syntax

let comparison_files =
  let doc = "OVD comparison files (by glob pattern)." in
  Arg.(value & pos_all string [] & info [] ~doc ~docv:"GLOB")

(* TODO: filter_category? *)

let format =
  let enum =  [
      (* ("pretty", `Pretty); *)
      ("json", `Json);
    ]
  in
  let doc = Format.sprintf "Output format, %s." (Arg.doc_alts_enum enum) in
  let format = Arg.enum ~docv:"FORMAT" enum in
  Arg.(value & opt format `Pretty & info ["format"] ~doc)

let cmd =
  let doc = "Summarize OVD comparison files." in
  Cmd.make (Cmd.info "summarize" ~doc) @@
  let+ comparison_files and+ format in
  summarize ~comparison_files ~format
