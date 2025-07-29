(** Set of functions used to analyse the project structure to match paths against it *)

module Folder = Hashtbl.Make(struct
  type t = string
  let equal = String.equal
  let hash = Hashtbl.hash
end)

type project_structure =
  | File of string
  | Directory of string * bool ref * project_structure Folder.t
(**
  Represents the structure of the project.
  - [File path]: a file with the given path.
  - [Directory (name, scanned, files)]: a directory with the given name,
    a boolean indicating if it has been scanned, and a map of files and directories.
*)


let rec pp_project_structure fmt = function
  | File path ->
    Format.fprintf fmt "File: %s" path
  | Directory (name, scanned, files) ->
    if not !scanned then
      Format.fprintf fmt "%s (not scanned)" name
    else
      Format.fprintf fmt "%s (scanned) @[<v 0>@,%a@]" name
        (Format.pp_print_list
           ~pp_sep:Format.pp_print_cut pp_project_structure)
        (Folder.to_seq files |> Seq.map snd |> List.of_seq)      

let project = Directory ("", ref false, Folder.create 10)
let base_path = ref ""

let init project_path =
  if !base_path = "" then (
    base_path := project_path
  ) else (
    assert (!base_path = project_path);
  )

let scan_folder path scanned files =
  if not !scanned then (
    scanned := true;
    let folder_content = Sys.readdir path in
    Array.iter (fun f ->
      let is_dir = Sys.is_directory @@ Filename.concat path f in
      if is_dir then
        Folder.replace files f (Directory (f, ref false, Folder.create 10))
      else
        Folder.replace files f (File f)
    ) folder_content
  )

let match_path (project_path: string) (path: string list) =
  let rec aux structure matched_path path acc =
    match path, structure with
    | [], _ -> acc
    | "." :: rest, _ -> 
      aux structure matched_path rest acc
    | ".." :: rest, _ -> (
      match acc with
      | [] ->
        aux structure matched_path rest acc
      | _ ->
        Format.eprintf "Error: '..' not allowed in project structure.\n";
        exit 1
    )
    | file :: [], Directory (_, scanned, files) ->
      scan_folder matched_path scanned files;
      (match Folder.find_opt files file with
      | Some (File file_path) ->
        file_path :: acc
      | Some (Directory _) ->
        []
      | None ->
        []
      )
    | dir :: rest, Directory (_, scanned, files) ->
      scan_folder matched_path scanned files;
      (match Folder.find_opt files dir with
      | Some (File _) ->
        []
      | Some (Directory _ as sub_dir) ->
        aux sub_dir (Filename.concat matched_path dir) rest (dir::acc)
      | None ->
        if acc = [] then (
          aux structure matched_path rest acc
        )
        else (
          []))
    | _ ->
      []
  in
  List.rev @@ aux project project_path path []
(**
  Tries to match the given path against the project structure. The function dynamically scans directories as needed.
*)


let warned = Folder.create 10
let memo = Folder.create 10

let path_to_project_relative__ ?(warn=true) project_path file_path =
  init project_path;
  match (match_path project_path (String.split_on_char '/' file_path)) with
  | [] -> 
      if warn then (
        (match Folder.find_opt warned file_path with
        | None ->
          Folder.replace warned file_path ();
          Format.printf "Warning: File %s not found in project structure.\n" file_path
        | Some () ->
          ());
        file_path
      ) else (
        Format.printf "File %s not found in project structure.\n" file_path;
        exit 1
      )
  | relative_path ->
      let relative_path_str = String.concat "/" relative_path in
      Filename.concat project_path relative_path_str
(**
  Converts a file path to a project-relative path.
  If the file is not found in the project structure, it prints a warning and returns the original path.
  If [warn] is false, it exits with an error if the file is not found.
  The function initializes the project structure and scans it dynamically as needed.
*)

let path_to_project_relative ?(warn=true) project_path file_path =
  match Folder.find_opt memo file_path with
  | Some relative_path -> relative_path
  | None ->
    Format.printf "Converting path %s to project-relative path...@." file_path;
    let relative_path = path_to_project_relative__ ~warn project_path file_path in
    Folder.replace memo file_path relative_path;
    relative_path
