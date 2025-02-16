open Lwt.Syntax
open Lwt.Infix

let input_loop out_chan =
    let rec loop () =
        let* msg = Lwt_io.read_line Lwt_io.stdin in
        let id = Rtt.generate_id () in
        Rtt.record id;
        let* () = Lwt_io.write_line out_chan (Message.create_data id msg) in
        loop ()
    in
    loop ()

let process_messages in_chan out_chan ~on_data ~on_ack ~on_disconnect =
    let rec loop () =
        let* msg = Lwt_io.read_line_opt in_chan in
        match msg with
        | Some raw_msg ->
            (try
                match Message.parse raw_msg with
                | Data (id, content) ->
                    let* () = on_data id content in
                    let* () = Lwt_io.write_line out_chan (Message.create_ack id) in
                    loop ()
                | Ack id ->
                    let rtt = Rtt.handle_ack id in
                    let* () = on_ack id rtt in
                    loop ()
            with ex ->
                Logs_lwt.err (fun m -> m "Protocol error: %s" (Printexc.to_string ex)))
            >>= loop
        | None ->
            on_disconnect ()
    in
    loop ()
