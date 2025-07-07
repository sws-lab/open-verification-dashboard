open Dashboard

type args = {
  project_path: string;
  proofObligations: ProofObligation.ProofObligation.t list;
  only: string option;
}

let parse_args () =
  let project_path = ref "" in
  let only = ref None in
  let speclist = [
    ("--project", Arg.Set_string project_path, "The path to the project directory if it is not the current directory");
    ("--analyze", Arg.String (fun file -> only := Some file), "Only output conflicts for the given file");
  ]
  and usage_msg = "Usage: dashboard [options]" in
  let input_files = ref [] in
  let add_file file = 
    let proofObligation = ProofObligation.of_file file in
    match proofObligation with
    | Some proofObligation -> input_files := proofObligation :: !input_files
    | None -> 
      exit 1
  in
  Arg.parse
    speclist add_file usage_msg;
  {
    project_path = !project_path;
    proofObligations = List.rev !input_files;
    only = !only;
  }

let () =
  let reset_ppf = Spectrum.prepare_ppf Format.std_formatter in
  let input_args = parse_args () in
  let num_proofObligations = List.length input_args.proofObligations in
  if num_proofObligations < 2 then (
    Printf.eprintf "At least two proofObligation files are required for comparison.\n";
    exit 1)
  else if num_proofObligations > 2 then (
    Printf.eprintf "More than two proofObligation files are not supported for comparison (TODO).\n";
    exit 1);
  
  let proofObligations = List.map (fun proofObligation -> ProofObligation.convert_paths proofObligation input_args.project_path) input_args.proofObligations in
  let proofObligations = match input_args.only with
  | Some file ->
    let file = FilePath.reduce ~no_symlink:true @@ FilePath.make_absolute (FileUtil.pwd ()) file in
    List.map (fun (proofObligation : ProofObligation.t) ->
      { proofObligation with
        checks = 
          List.filter (fun (check : ProofObligation.Check.t) -> 
            FilePath.compare check.range.start.file file == 0 &&
            FilePath.compare check.range.end_.file file == 0
          ) proofObligation.checks
      }
    ) proofObligations
  | None ->
    proofObligations
  in
  let disagreement = CompareProofObligations.search_proofObligations_disagreements (List.hd proofObligations) (List.hd (List.tl proofObligations)) in
  if List.length disagreement = 0 then
    Printf.printf "No disagreements found between the proofObligations.\n"
  else (
    Printf.printf "Disagreements found:\n";
    List.iter (fun conflict ->
      Format.printf "%a@." CompareProofObligations.Conflict.pp conflict
    ) disagreement
  );
  reset_ppf ()
