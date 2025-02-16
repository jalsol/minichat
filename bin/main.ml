open Minichat

let mode = ref ""
let host = ref ""
let port = ref 0

let speclist = [
    ("-m", Arg.Set_string mode, "Mode: \"server\" or \"client\"");
    ("-h", Arg.Set_string host, "Host address (required for client mode)");
    ("-p", Arg.Set_int port, "Port number (required)");
]

let usage_msg = "Usage: minichat -m [server|client] -p <port> [-h <address>]"

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
        Server.run !port
    | "client" ->
        Client.run !host !port
    | _ ->
        failwith "Error: --mode must be 'server' or 'client'"

let () =
    Lwt_main.run main
