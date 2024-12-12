module Kind : sig
  type t =
    | Grid
    | Arc
end

module Device : sig
  type t =
    { name : string
    ; kind : Kind.t
    ; addr : Eio.Net.Sockaddr.datagram
    ; port : int
    }
end

module Monome : sig
  val enumerate_devices
    :  sw:Eio.Switch.t
    -> net:[> [> `Generic ] Eio.Net.ty ] Eio.Resource.t
    -> ?host:Eio.Net.Ipaddr.v4v6
    -> ?port:int
    -> unit
    -> (Device.t list, string) result
end
