open Dashboard

let compare ~checks_files ~filter_category ~filter_path ~format =
  let reset_ppf = Spectrum.prepare_ppf Format.std_formatter in
  match checks_files with
  | []
  | [_] ->
    Error "At least two proofObligation files are required for comparison."
  | _ :: _ :: _ :: _ ->
    Error "More than two proofObligation files are not supported for comparison (TODO)."
  | [checks_file1; checks_file2] ->
    let load_checks checks_file =
      let checks_file = Option.get (ProofObligation.of_file checks_file) in (* TODO: no Option.get *)
      let checks =
        match filter_path with
        | Some glob ->
          let glob = Re.compile (Re.Glob.glob ~anchored:true glob) in
          List.filter
            (fun (check : ProofObligation.Check.t) ->
              Re.execp glob check.range.file)
            checks_file.checks
        | None -> checks_file.checks
      in
      let checks =
        ProofObligation.filter_checks checks filter_category
      in
      {checks_file with checks}
    in
    let po1 = load_checks checks_file1 in
    let po2 = load_checks checks_file2 in
    let conflict = CompareProofObligations.conflicts_between po1 po2 in
    begin match format with
      | `Json ->
        let report = Report.create po1.name po2.name in
        List.iter
          (fun (conflict : Conflict.t) ->
            Report.add_conflict report conflict.range.file conflict)
          conflict;
        Report.yojson_of_t report |> Yojson.Safe.to_channel stdout
      | `Pretty ->
        List.iter
          (fun conflict -> Format.printf "%a@." Conflict.pp conflict)
          conflict;
    end;
    reset_ppf ();
    Ok 0


open Cmdliner
open Cmdliner.Term.Syntax

let checks_files =
  let doc = "OVD checks file." in
  Arg.(value & pos_left 2 non_dir_file [] & info [] ~doc)

let filter_category =
  let module Category = ProofObligation.Category in
  let enum =
    List.init Category.max (fun i ->
        let category = Option.get (Category.of_enum i) in
        (Category.to_string category, category)
      )
  in
  let doc = Format.sprintf "Filter checks to given categories, %s." (Arg.doc_alts_enum enum) in (* TODO: format these better *)
  let category = Arg.enum ~docv:"CATEGORY" enum in
  Arg.(value & opt_all category [] & info ["filter-category"] ~doc)

let filter_path =
  let doc = "Filter checks to given paths (by glob pattern)." in
  Arg.(value & opt (some string) None & info ["filter-path"] ~doc ~docv:"GLOB")

let format =
  let enum =  [
      ("pretty", `Pretty);
      ("json", `Json);
    ]
  in
  let doc = Format.sprintf "Output format, %s." (Arg.doc_alts_enum enum) in
  let format = Arg.enum ~docv:"FORMAT" enum in
  Arg.(value & opt format `Pretty & info ["format"] ~doc)

let cmd =
  let doc = "Compare OVD checks files." in
  Cmd.make (Cmd.info "compare" ~doc) @@
  let+ checks_files and+ filter_category and+ filter_path and+ format in
  compare ~checks_files ~filter_category ~filter_path ~format
