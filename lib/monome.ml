[@@@warning "-32"]

module UNSAFE = struct
  module Types = Lib_monome.Type
  module Functions = Lib_monome.Functions
end

module Private = struct
  let parse_name _name = assert false
end

type device = UNSAFE.Types.monome Ctypes.structure Ctypes_static.ptr

let create ?(address = UNSAFE.Types.default_udp_address) () : device option =
  UNSAFE.Functions.connect address
;;

let destroy self = UNSAFE.Functions.shutdown self
let get_name self = UNSAFE.Functions.get_friendly_name self

module Grid = struct
  type nonrec t = Grid of device [@warning "-32"]

  let of_device (device : device) : t option = Some (Grid device)
  let set_rotation (Grid self) rotation = UNSAFE.Functions.set_rotation self rotation
  let get_rotation (Grid self) = UNSAFE.Functions.get_rotation self
end [@warning "-27"]
