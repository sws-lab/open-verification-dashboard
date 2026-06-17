open Ovd_comparison

let compare ~checks_files ~filter_category ~filter_path ~match_range ~format =
  let reset_ppf = Spectrum.prepare_ppf Format.std_formatter in
  match checks_files with
  | []
  | [_] ->
    Error "At least two proofObligation files are required for comparison."
  | _ :: _ :: _ :: _ ->
    Error "More than two proofObligation files are not supported for comparison (TODO)."
  | [checks_file1; checks_file2] ->
    let load_checks checks_file =
      let checks_file = Option.get (Ovd_checks.ChecksFile.of_file checks_file) in (* TODO: no Option.get *)
      let checks =
        match filter_path with
        | Some glob ->
          let glob = Re.compile (Re.Glob.glob ~anchored:true glob) in
          List.filter
            (fun (check : Ovd_checks.Check.t) ->
              Re.execp glob check.range.file)
            checks_file.checks
        | None -> checks_file.checks
      in
      let checks =
        Ovd_checks.ChecksFile.filter_checks checks filter_category
      in
      {checks_file with checks}
    in
    let po1 = load_checks checks_file1 in
    let po2 = load_checks checks_file2 in
    let conflict =
      match match_range with
      | `Overlap -> OverlapComparison.compare po1.checks po2.checks
      | `Direct -> DirectComparison.compare po1.checks po2.checks
    in

    (* Check that no checks were lost. *)
    let conflict_checks_count =
      List.fold_left (fun acc (conflict: Conflict.t) ->
          acc + Conflict.ChecksSet.cardinal conflict.from_po1 + Conflict.ChecksSet.cardinal conflict.from_po2
        ) 0 conflict
    in
    (* TODO: This fails if the original lists contain duplicates. *)
    assert (conflict_checks_count = List.length po1.checks + List.length po2.checks);

    begin match format with
      | `Json ->
        let report = Report.create po1.name po2.name in
        List.iter (Report.add_conflict report) conflict;
        Report.yojson_of_t report |> Yojson.Safe.pretty_to_channel stdout;
        output_char stdout '\n';
        flush stdout
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
  let module Category = Ovd_checks.Category in
  let enum =
    List.init (Category.max + 1) (fun i ->
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

let match_range =
  let enum =  [
      ("overlap", `Overlap);
      ("direct", `Direct);
    ]
  in
  let doc = Format.sprintf "Match check ranges, %s." (Arg.doc_alts_enum enum) in
  let format = Arg.enum ~docv:"MATCH" enum in
  Arg.(value & opt format `Overlap & info ["match-range"] ~doc)

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
  let+ checks_files and+ filter_category and+ filter_path and+ match_range and+ format in
  compare ~checks_files ~filter_category ~filter_path ~match_range ~format
