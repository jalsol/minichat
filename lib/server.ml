open Lwt.Syntax
open Lwt.Infix

let backlog = 1

let create_socket port =
    let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
    let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_any, port) in
    Lwt_main.run (
        let* () = Lwt_unix.bind sock sockaddr in
        Lwt_unix.listen sock backlog;
        Lwt.return_unit
    );
    sock

let handle_message msg =
    Printf.sprintf "User typed: %s" msg

let string_of_sockaddr = function
    | Unix.ADDR_INET (addr, port) ->
        Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port
    | Unix.ADDR_UNIX path ->
        path

let rec handle_connection sockaddr in_chan out_chan =
    let* msg = Lwt_io.read_line_opt in_chan in
    match msg with
    | Some msg ->
        Logs.app (fun m -> m "%s: %s" (string_of_sockaddr sockaddr) msg);
        let reply = handle_message msg in
        let* () = Lwt_io.write_line out_chan reply in
        handle_connection sockaddr in_chan out_chan
    | None ->
        Logs_lwt.info (fun m -> m "Connection closed: %s" (string_of_sockaddr sockaddr)) 

let accept_connection conn =
    let (client_sock, client_sockaddr) = conn in
    let in_chan = Lwt_io.(of_fd ~mode:Input client_sock) in
    let out_chan = Lwt_io.(of_fd ~mode:Output client_sock) in
    Lwt.on_failure
        (handle_connection client_sockaddr in_chan out_chan)
        (fun e -> Logs.err (fun m -> m "%s" (Printexc.to_string e)));
    let* () = Logs_lwt.info
        (fun m -> m "New connection: %s" (string_of_sockaddr client_sockaddr)) in
    Lwt.return_unit

let create_server sock =
    let rec serve () =
        Lwt_unix.accept sock
        >>= accept_connection
        >>= serve
    in serve

let run_server port =
    Logs.set_level (Some Logs.Info);
    Logs.set_reporter (Logs.format_reporter ());
    Logs.info (fun m -> m "Starting server on port %d" port);
    let sock = create_socket port in
    let serve = create_server sock in
    Lwt_main.run @@ serve ()
