[@@@warning "-69-32"]

open! Core

let ( let* ) r f = Result.bind r ~f

(* Amount of time without a device info message before all devices are
   considered received *)
let device_enumeration_timeout = 0.5
let serialosc_default_port = 12_002

module Builder = struct
  type t =
    { port : int option
    ; host : string option
    ; prefix : string option
    ; id : string option
    ; size : (int * int) option
    ; rotation : int option
    }

  let create () =
    { port = None; host = None; prefix = None; id = None; size = None; rotation = None }
  ;;

  type setup =
    | Bundle_during_setup
    | Not_sys
    | Invalid_data

  open Osc

  let parse_update self addr args =
    let open Types in
    match List.hd_exn addr, args with
    | "port", [ Int32 n ] -> Ok { self with port = Some (Int32.to_int_trunc n) }
    | "host", [ String host ] -> Ok { self with host = Some host }
    | "prefix", [ String prefix ] -> Ok { self with prefix = Some prefix }
    | "id", [ String id ] -> Ok { self with id = Some id }
    | "size", [ Int32 x; Int32 y ] ->
      Ok { self with size = Some (Int32.to_int_trunc x, Int32.to_int_trunc y) }
    | "rotation", [ Int32 rot ] ->
      Ok { self with rotation = Some (Int32.to_int_trunc rot) }
    | _ -> Error Invalid_data
  ;;

  let fill : t -> Types.packet -> (t, setup) result =
    fun self -> function
    | Message { address; arguments } ->
      (match String.split ~on:'/' address with
       | "sys" :: addr -> parse_update self addr arguments
       | _ -> Error Not_sys)
    | Bundle _ -> Error Bundle_during_setup
  ;;
end

module Kind = struct
  type t =
    | Grid
    | Arc

  let of_string : string -> t option = function
    | "arc" -> Some Arc
    | "grid" -> Some Grid
    | _ -> None
  ;;
end

module Device = struct
  type t =
    { name : string
    ; kind : Kind.t
    ; addr : Eio.Net.Sockaddr.datagram
    ; port : int
    }

  let create : name:string -> Kind.t -> addr:Eio.Net.Sockaddr.datagram -> port:int -> t =
    fun ~name kind ~addr ~port -> { name; kind; addr; port }
  ;;

  let name { name; _ } = name
  let kind { kind; _ } = kind
  let addr { addr; _ } = addr
  let port { port; _ } = port
end

module Monome = struct
  type t =
    { name : string
    ; kind : Kind.t
    ; port : int
    ; host : string
    ; id : string
    ; prefix : string
    ; rotation : int
    ; size : int * int
    ; incoming : bytes Eio.Stream.t
    ; outgoing : bytes Eio.Stream.t
    }

  (*
     type t =
    { port : int option
    ; host : string option
    ; prefix : string option
    ; id : string option
    ; size : (int * int) option
    ; rotation : int option
    }
  *)
  let from_builder : name:string -> Kind.t -> Builder.t -> t option =
    fun ~name kind Builder.{ port; host; prefix; id; size; rotation } ->
    let ( let* ) o f = Option.bind ~f o in
    let* port = port in
    let* host = host in
    let* prefix = prefix in
    let* id = id in
    let* size = size in
    let* rotation = rotation in
    let incoming = Eio.Stream.create 128
    and outgoing = Eio.Stream.create 128 in
    Some { name; kind; port; host; id; prefix; rotation; size; incoming; outgoing }
  ;;

  let buf_of_osc_message : address:string -> Osc.Types.argument list -> Cstruct.t =
    fun ~address args -> Message.build_message ~address args |> Cstruct.string
  ;;

  open! Eio

  let register_device_changed_callback
    ~sw
    ~net
    ?(host = Eio.Net.Ipaddr.V4.loopback)
    ?(port = serialosc_default_port)
    (callback : Events.DeviceChanged.t -> unit)
    : unit
    =
    let decode =
      let open Osc.Types in
      function
      | Message message ->
        if String.is_prefix ~prefix:"/serialosc/add" message.address
        then (
          match message.arguments with
          | [ String device ] -> Some (Events.DeviceChanged.Added device)
          | _ -> None)
        else if String.is_prefix ~prefix:"/serialosc/remove" message.address
        then (
          match message.arguments with
          | [ String device ] -> Some (Events.DeviceChanged.Removed device)
          | _ -> None)
        else None
      | Bundle _ ->
        traceln "Received an unexpected bundle in 'register_device_changed_callback'";
        None
    in
    let transport = Connection.find_free_port ~sw ~net in
    Eio.Fiber.fork ~sw (fun () ->
      let server_port = transport.port in
      let message =
        buf_of_osc_message
          ~address:"/serialosc/notify"
          Osc.Types.[ String "127.0.0.1"; Int32 server_port ]
      in
      let recv_buf = Cstruct.create 1024 in
      let rec loop need_notify =
        if need_notify
        then (
          Net.send transport.socket ~dst:(`Udp (host, port)) [ message ];
          recv transport.socket recv_buf)
      and recv socket buff =
        let _ = Net.recv socket buff in
        let s = Cstruct.to_string buff in
        match Osc.Codec.to_packet s with
        | Ok packet ->
          (match decode packet with
           | Some (Added _ as event) ->
             callback event;
             loop true
           | Some removed ->
             callback removed;
             loop false
           | None -> loop false)
        | Error _ -> loop false
      in
      loop true)
  ;;

  let enumerate_devices
    ~sw
    ~net
    ?(host = Net.Ipaddr.V4.loopback)
    ?(port = serialosc_default_port)
    ()
    =
    let transport = Connection.find_free_port ~sw ~net in
    let addrs = Connection.string_of_addr transport.addr in
    let serialosc_conn = Net.datagram_socket ~sw net `UdpV4 in
    let list_devices =
      buf_of_osc_message
        ~address:"/serialosc/list"
        Osc.Types.[ String addrs; Int32 transport.port ]
    in
    Net.send serialosc_conn ~dst:(`Udp (host, port)) [ list_devices ];
    let rec recv_device acc buf =
      let res =
        Fiber.first
          (fun _ -> Net.recv transport.socket buf |> fst |> Option.return)
          (fun _ ->
            Eio_unix.sleep device_enumeration_timeout;
            None)
      in
      match res with
      | Some addr -> parse_response acc addr buf
      | None -> Ok acc
    and parse_response acc addr buf =
      let message = Cstruct.to_string buf in
      match Osc.Codec.to_packet message with
      | Ok (Message message) when String.equal message.address "/serialosc/device" ->
        (match message.arguments with
         | String name :: String kind :: Int32 port :: _ ->
           let kind = Option.value ~default:Kind.Grid @@ Kind.of_string kind
           and port = Int32.to_int_trunc port in
           let device = Device.create ~name kind ~addr ~port in
           recv_device (device :: acc) buf
         | _ -> recv_device acc buf)
      | Ok _ -> recv_device acc buf
      | _ -> assert false
    in
    recv_device [] @@ Cstruct.create 1024
  ;;

  type error =
    | Osc of [ `Missing_typetag_string | `Unsupported_typetag of char ]
    | Builder of Builder.setup
    | Incomplete

  let setup
    :  sw:Switch.t -> net:'a Resource.t -> ?prefix:string -> Device.t
    -> ('a Net.datagram_socket_ty Connection.Transport.t * t, 'e) result
    =
    fun ~sw ~net ?(prefix = "/grid") device ->
    let Device.{ name; kind; addr; _ } = device in
    let transport = Connection.find_free_port ~sw ~net in
    let device_connection = Net.datagram_socket ~sw net @@ addr in
    let msg =
      buf_of_osc_message ~address:"/sys/port" Osc.Types.[ Int32 transport.port ]
    in
    Net.send device_connection [ msg ];
    let msg =
      buf_of_osc_message
        ~address:"/sys/host"
        Osc.Types.[ String (Connection.string_of_addr addr) ]
    in
    Net.send device_connection [ msg ];
    let msg = buf_of_osc_message ~address:"/sys/prefix" Osc.Types.[ String prefix ] in
    Net.send device_connection [ msg ];
    let msg = buf_of_osc_message ~address:"/sys/info" [] in
    Net.send device_connection [ msg ];
    let builder = Builder.create () in
    let recvbuf = Cstruct.create 1024 in
    let rec build builder =
      let response =
        Fiber.first
          (fun () -> Net.recv transport.socket recvbuf |> fst |> Option.return)
          (fun () ->
            Eio_unix.sleep device_enumeration_timeout;
            None)
      in
      match response with
      | Some _ ->
        let* packet =
          Cstruct.to_string recvbuf
          |> Osc.Codec.to_packet
          |> Result.map_error ~f:(fun e -> Osc e)
        in
        let* builder =
          Builder.fill builder packet |> Result.map_error ~f:(fun e -> Builder e)
        in
        build builder
      | None -> Ok builder
    in
    let* builder = build builder in
    match from_builder ~name kind builder with
    | Some monome -> Ok (transport, monome)
    | None -> Error Incomplete
  ;;
end
