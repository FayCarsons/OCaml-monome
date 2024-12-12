module DeviceChanged = struct
  type t =
    | Added of string
    | Removed of string
end
