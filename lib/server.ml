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

let process_messages in_chan out_chan addr =
    Protocol.Common.process_messages in_chan out_chan
        ~on_data:(fun id content ->
            Logs_lwt.app (fun m -> m "Client[%d]: %s" id content))
        ~on_ack:(fun id rtt ->
            Logs_lwt.app (fun m -> m "ACK %d: %.2fms" id rtt))
        ~on_disconnect:(fun () ->
            let* () = Logs_lwt.info (fun m -> m "%s disconnected" addr) in
            current_client := None;
            Lwt.return_unit)

let input_loop =
    Protocol.Common.input_loop

let string_of_sockaddr = function
    | Unix.ADDR_INET (addr, port) ->
        Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port
    | Unix.ADDR_UNIX path ->
        path

let handle_connection (client_sock, client_sockaddr) =
    let in_chan = Lwt_io.of_fd ~mode:Input client_sock in
    let out_chan = Lwt_io.of_fd ~mode:Output client_sock in
    let addr = string_of_sockaddr client_sockaddr in
    current_client := Some out_chan;
    let* () = Logs_lwt.info
        (fun m -> m "Client conected: %s" addr) in
    Lwt.pick [
        process_messages in_chan out_chan addr;
        input_loop out_chan;
    ]

let rec serve sock =
    let* client = Lwt_unix.accept sock in
    let* () = handle_connection client in
    serve sock

let run port =
    Logs.set_level (Some Logs.Info);
    Logs.set_reporter (Logs.format_reporter ());
    Logs.info (fun m -> m "Starting server on port %d" port);
    let* sock = create_socket port in

    let shutdown_signal = Lwt_mvar.create_empty () in
    let _ = Lwt_unix.on_signal Sys.sigint (fun _ ->
        Logs.app (fun m -> m "Shutting down server...");
        Lwt.async (fun () -> Lwt_mvar.put shutdown_signal ())
    ) in

    let* () = Lwt.pick [serve sock; Lwt_mvar.take shutdown_signal] in
    Lwt_unix.close sock
