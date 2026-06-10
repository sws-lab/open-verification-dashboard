open Cmdliner

let cmds = [
  OvdCompare.cmd;
  OvdSummarize.cmd;
]

let cmd =
  let doc = "Open Verification Dashboard" in
  let info = Cmd.info "ovd" ~version:"%%VERSION%%" ~doc in
  Cmd.group info cmds

let () = exit (Cmd.eval_result' cmd)
