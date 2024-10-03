open Ctypes
module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F

  let connect = foreign "monome_open" (ptr (const char) @-> returning (ptr Types.monome))
  let shutdown = foreign "monome_close" (ptr Types.monome @-> returning void)

  let set_rotation =
    foreign "monome_set_rotation" (ptr Types.monome @-> Types.rotate @-> returning void)
  ;;

  let get_rotation =
    foreign "monome_get_rotation" (ptr Types.monome @-> returning Types.rotate)
  ;;

  let device_to_const_string = ptr Types.monome @-> returning (ptr (const char))
  let get_serial = foreign "monome_get_serial" device_to_const_string
  let get_devpath = foreign "monome_get_devpath" device_to_const_string
  let get_friendly_name = foreign "monome_get_friendly_name" device_to_const_string
  let get_proto = foreign "monome_get_proto" device_to_const_string
  let get_rows = foreign "monome_get_rows" (ptr Types.monome @-> returning int)
  let get_cold = foreign "monome_get_cols" (ptr Types.monome @-> returning int)
end
