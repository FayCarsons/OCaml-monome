open Eio
open Core

module Transport = struct
  type 'a t =
    { port : int32
    ; addr : Net.Sockaddr.datagram
    ; socket : 'a Net.datagram_socket
    ; rx : bytes Stream.t
    ; tx : bytes Stream.t
    }

  let create port addr socket =
    let rx = Stream.create 32
    and tx = Stream.create 32 in
    { port; addr; socket; rx; tx }
  ;;

  let send self msg = Stream.add self.tx msg
  let receive self = Stream.take self.rx

  let run self =
    let rec send_loop () =
      Eio.Stream.take self.rx
      |> Cstruct.of_bytes
      |> List.return
      |> Net.send self.socket
      |> send_loop
    in
    let recv_buf = Cstruct.create 1024 in
    let rec recv_loop () =
      let _, len = Net.recv self.socket recv_buf in
      let msg = Cstruct.to_bytes @@ Cstruct.sub recv_buf 0 len in
      Eio.Stream.add self.tx msg;
      recv_loop ()
    in
    Fiber.both send_loop recv_loop
  ;;
end

let default_serialosc_port = 12_002

(* The port this library will start searching for serialosc on *)
let start_port = 10_000l

let string_of_addr : Net.Sockaddr.datagram -> string = function
  | `Udp (addr, _) -> Fmt.to_to_string Net.Ipaddr.pp addr
  | _ -> assert false
;;

exception Ports_exhausted

let find_free_port ~sw ~net =
  let rec go = function
    | 0l ->
      Switch.fail sw Ports_exhausted;
      assert false
    | port ->
      (try
         let addr = `Udp (Net.Ipaddr.V4.loopback, Int32.to_int_trunc port) in
         let socket =
           Net.datagram_socket ~reuse_addr:true ~reuse_port:true ~sw net addr
         in
         Transport.create port addr socket
       with
       | _ -> go (Int32.succ port))
  in
  go start_port
;;
