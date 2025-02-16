type entry = float * bool ref

let store : (int, entry) Hashtbl.t = Hashtbl.create 50
let counter = ref 0
let timeout_sec = 5.0

let generate_id () = 
    incr counter;
    !counter

let record id = 
    Hashtbl.replace store id (Unix.gettimeofday (), ref false)

let handle_ack id =
    match Hashtbl.find_opt store id with
    | Some (start_time, _) ->
        let rtt = (Unix.gettimeofday () -. start_time) *. 1000. in
        Hashtbl.remove store id;
        rtt
    | None ->
        invalid_arg "Unknown ACK ID"
