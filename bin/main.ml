open Minichat

let mode = ref ""
let host = ref ""
let port = ref 0

let speclist = [
    ("--mode", Arg.Set_string mode, "Mode: server or client");
    ("--host", Arg.Set_string host, "Host address (required for client mode)");
    ("--port", Arg.Set_int port, "Port number (required)");
]

let usage_msg =
    "Usage: program --mode [server|client] --port <num> [--host <addr>]"

let check_args () =
    match !mode with
    | "server" ->
        if !port = 0 then
            failwith "Error: --port is required in server mode"
    | "client" ->
        if !port = 0 then
            failwith "Error: --port is required in client mode";
        if !host = "" then
            failwith "Error: --host is required in client mode"
    | _ ->
        failwith "Error: --mode must be 'server' or 'client'"

let main =
    Arg.parse speclist print_endline usage_msg;
    check_args ();
    match !mode with
    | "server" ->
        Server.run_server !port
    | "client" ->
        failwith "Not implemented"
    | _ ->
        failwith "Error: --mode must be 'server' or 'client'"

let () = main
