open Lwt.Syntax

let backlog = 1
let current_client = ref None

let create_socket port =
    let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
    let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_any, port) in
    Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true;
    let* () = Lwt_unix.bind sock sockaddr in
    Lwt_unix.listen sock backlog;
    Lwt.return sock

let rec handle_connection in_chan =
    let* msg = Lwt_io.read_line_opt in_chan in
    match msg with
    | Some msg ->
        Logs.app (fun m -> m "Client: %s" msg);
        handle_connection in_chan
    | None ->
        let* () = Logs_lwt.info (fun m -> m "Client disconnected") in
        current_client := None;
        Lwt.return_unit

let rec server_input_loop () =
    match !current_client with
    | Some out_chan ->
        let* msg = Lwt_io.read_line Lwt_io.stdin in
        let* () = Lwt_io.write_line out_chan msg in
        server_input_loop ()
    | None ->
        server_input_loop ()

let string_of_sockaddr = function
    | Unix.ADDR_INET (addr, port) ->
        Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port
    | Unix.ADDR_UNIX path ->
        path

let accept_connection (client_sock, client_sockaddr) =
    let in_chan = Lwt_io.of_fd ~mode:Input client_sock in
    let out_chan = Lwt_io.of_fd ~mode:Output client_sock in
    current_client := Some out_chan;
    let* () = Logs_lwt.info
        (fun m -> m "Client conected: %s" (string_of_sockaddr client_sockaddr)) in
    Lwt.pick [handle_connection in_chan; server_input_loop ()]

let rec serve sock =
    let* client = Lwt_unix.accept sock in
    let* () = accept_connection client in
    serve sock

let run port =
    Logs.set_level (Some Logs.Info);
    Logs.set_reporter (Logs.format_reporter ());
    Logs.info (fun m -> m "Starting server on port %d" port);
    let* sock = create_socket port in
    Lwt_main.run @@ serve sock
