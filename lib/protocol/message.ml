type message =
    | Data of int * string
    | Ack of int

let separator = '\x1f' (* ASCII unit separator *)

let parse msg =
    match String.split_on_char separator msg with
    | ["DATA"; id; content] -> Data (int_of_string id, content)
    | ["ACK"; id] -> Ack (int_of_string id)
    | _ -> failwith "Invalid message format"

let create_data id content = 
    Printf.sprintf "DATA%c%d%c%s" separator id separator content

let create_ack id = 
    Printf.sprintf "ACK%c%d" separator id
