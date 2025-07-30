open Dashboard

type args = {
  mutable project_path: string;
  proofObligations: ProofObligation.ProofObligation.t list;
  mutable only: string option;
  mutable output: string option;
  mutable exclude_not_found: bool;
}

let parse_args () =
  let args = {
    project_path = "."; (* The root directory of the project, used for resolving file paths *)
    proofObligations = []; (* List of proof obligations to compare, for now only two can be compared simultaneously *) 
    only = None; (* If set, only output conflicts for the given file *)
    output = None; (* If set, the path to the json output file *)
    exclude_not_found = false; (* If set, exclude files with path that can't be matched against the project structure *)
  } in
  let speclist = [
    ("--project", Arg.String (fun path -> args.project_path <- path), "The path to the project directory if it is not the current directory");
    ("--analyze", Arg.String (fun file -> args.only <- Some file), "Only output conflicts for the given file");
    ("--output", Arg.String (fun file -> args.output <- Some file), "The path to the json output file");
    ("--exclude-not-found", Arg.Bool (fun b -> args.exclude_not_found <- b), "Exclude not found files from the analysis");
  ]
  and usage_msg = 
    "Usage:\n  dashboard [--project <path>] [--analyze <file>] [--output <file>] [--exclude-not-found <bool>] PO1 PO2" ^ 
    "\nReturn code:" ^
    "\n  0 - no conflicts found" ^
    "\n  1 - error in input files or arguments" ^
    "\n  2 - precision conflicts found" ^
    "\n  3 - only one tool emit a PO for a given range" ^
    "\n  4 - safety conflicts found" ^
    "\n  5 - internal error (unexpected state)\n\n"
  in
  let input_files = ref [] in
  let add_file file = 
    let proofObligation = ProofObligation.of_file file in
    match proofObligation with
    | Some proofObligation -> input_files := proofObligation :: !input_files
    | None -> 
      Printf.eprintf "Failed to parse proof obligation from file %s.\n" file;
      exit 1
  in
  Arg.parse
    speclist add_file usage_msg;
  {
    args with
    proofObligations = List.rev !input_files;
  }

let () =
  let reset_ppf = Spectrum.prepare_ppf Format.std_formatter in
  let args = parse_args () in
  let num_proofObligations = List.length args.proofObligations in
  if num_proofObligations < 2 then (
    Printf.eprintf "At least two proofObligation files are required for comparison.\n";
    exit 1)
  else if num_proofObligations > 2 then (
    Printf.eprintf "More than two proofObligation files are not supported for comparison (TODO).\n";
    exit 1);
  
  let proofObligations = List.map (fun (proofObligation : ProofObligation.t) -> 
    Format.printf "Converting paths to project paths for proof obligation %s@." proofObligation.name;
    ProofObligation.convert_paths ~exclude_not_found:args.exclude_not_found proofObligation args.project_path
  ) args.proofObligations in
  let proofObligations = match args.only with
  | Some file ->
    let file = Project.path_to_project_relative ~warn:false args.project_path file in
    Format.printf "Filtering proof obligations for file %s@." file;
    List.map (fun (proofObligation : ProofObligation.t) ->
      let filtered_po = { proofObligation with
        checks = 
          List.filter (fun (check : ProofObligation.Check.t) -> 
            FilePath.compare check.range.file file == 0
          ) proofObligation.checks
      } in
      if List.length filtered_po.checks = 0 then (
        Printf.eprintf "No checks found in proof obligations %s.\n" filtered_po.name;
        exit 1
      );
      filtered_po
    ) proofObligations
  | None ->
    proofObligations
  in
  let po1 = List.hd proofObligations in
  let po2 = List.hd (List.tl proofObligations) in
  Format.printf "Comparing proof obligations %s and %s@." po1.name po2.name;
  let disagreement = CompareProofObligations.disagreements_between po1 po2 in
  if args.output <> None then (
    let report = Report.create po1.name po2.name in
    List.iter (fun (conflict : Conflict.t) ->
      Report.add_conflict report conflict.range.file conflict
    ) disagreement;

    Report.yojson_of_t report |> Yojson.Safe.to_file (Option.get args.output);
    Format.printf "Report written to %s@." (Option.get args.output);
  ) else (
    List.iter (fun conflict ->
      Format.printf "%a@." Conflict.pp conflict
    ) disagreement
  );
  reset_ppf ();
  exit @@ CompareProofObligations.exit_code_of_disagreement disagreement
