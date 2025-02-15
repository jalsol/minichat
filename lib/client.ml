open Lwt.Syntax

let connect_to_server host port =
    let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
    let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string host, port) in
    let* () = Lwt_unix.connect sock sockaddr in
    Lwt.return (Lwt_io.of_fd ~mode:Input sock, Lwt_io.of_fd ~mode:Output sock)

let rec receive_messages in_chan =
    let* msg = Lwt_io.read_line_opt in_chan in
    match msg with
    | Some msg ->
        Logs.app (fun m -> m "Server: %s" msg);
        receive_messages in_chan
    | None ->
        let* () = Logs_lwt.info (fun m -> m "Server disconnected") in
        Lwt.return_unit

let rec client_input_loop out_chan =
    let* msg = Lwt_io.read_line Lwt_io.stdin in
    let* () = Lwt_io.write_line out_chan msg in
    client_input_loop out_chan

let run host port =
    Logs.set_level (Some Logs.Info);
    Logs.set_reporter (Logs.format_reporter ());
    Logs.info (fun m -> m "Connecting to %s:%d" host port);
    let* in_chan, out_chan = connect_to_server host port in

    let shutdown_signal = Lwt_mvar.create_empty () in
    let _ = Lwt_unix.on_signal Sys.sigint (fun _ ->
        Logs.app (fun m -> m "Disconnecting from server...");
        Lwt.async (fun () -> Lwt_mvar.put shutdown_signal ())
    ) in

    let* () = Lwt.pick [receive_messages in_chan; client_input_loop out_chan; Lwt_mvar.take shutdown_signal] in
    Lwt_io.close out_chan
