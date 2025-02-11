open Lwt.Syntax
open Lwt.Infix

let backlog = 1

let create_socket port =
    let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
    let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_any, port) in
    let _ = Lwt_unix.bind sock sockaddr in
    Lwt_unix.listen sock backlog;
    sock

let handle_message msg =
    Printf.sprintf "User typed: %s" msg

let rec handle_connection in_chan out_chan =
    let* msg = Lwt_io.read_line_opt in_chan in
    match msg with
    | Some msg ->
        let reply = handle_message msg in
        let _ = Lwt_io.write_line out_chan reply in
        handle_connection in_chan out_chan
    | None ->
        Logs_lwt.info (fun m -> m "Connection closed") 

let fail_callback error =
    Logs.err (fun m -> m "%s" (Printexc.to_string error))

let accept_connection conn =
    let (client_sock, _) = conn in
    let in_chan = Lwt_io.(of_fd ~mode:Input client_sock) in
    let out_chan = Lwt_io.(of_fd ~mode:Output client_sock) in
    Lwt.on_failure (handle_connection in_chan out_chan) fail_callback;
    Logs_lwt.info (fun m -> m "New connection") >>= Lwt.return

let create_server sock =
    let rec serve () =
        Lwt_unix.accept sock
        >>= accept_connection
        >>= serve
    in serve

let run_server port =
    let sock = create_socket port in
    let serve = create_server sock in
    Lwt_main.run @@ serve ()
