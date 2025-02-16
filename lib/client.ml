open Lwt.Syntax

let connect_to_server host port =
    let sock = Lwt_unix.(socket PF_INET SOCK_STREAM 0) in
    let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string host, port) in
    let* () = Lwt_unix.connect sock sockaddr in
    Lwt.return (Lwt_io.of_fd ~mode:Input sock, Lwt_io.of_fd ~mode:Output sock)

let process_messages in_chan out_chan =
    Protocol.Common.process_messages in_chan out_chan
        ~on_data:(fun id content ->
            Logs_lwt.app (fun m -> m "Server[%d]: %s" id content))
        ~on_ack:(fun id rtt ->
            Logs_lwt.app (fun m -> m "ACK %d: %.2fms" id rtt))
        ~on_disconnect:(fun () ->
            Logs_lwt.info (fun m -> m "Server disconnected"))

let input_loop =
    Protocol.Common.input_loop

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

    let* () = Lwt.pick [
        process_messages in_chan out_chan;
        input_loop out_chan;
        Lwt_mvar.take shutdown_signal
    ] in
    Lwt_io.close out_chan
