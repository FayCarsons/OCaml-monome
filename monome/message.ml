open Osc

let build_message : address:string -> Types.argument list -> string =
  fun ~address arguments -> Codec.of_packet @@ Types.(Message { address; arguments })
;;
