open Ctypes
module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F

  let connect = foreign "monome_open" (const string @-> returning (ptr_opt Types.monome))
  let shutdown = foreign "monome_close" (ptr Types.monome @-> returning void)

  let set_rotation =
    foreign "monome_set_rotation" (ptr Types.monome @-> Types.rotation @-> returning void)
  ;;

  let get_rotation =
    foreign "monome_get_rotation" (ptr Types.monome @-> returning Types.rotation)
  ;;

  let device_to_const_string = ptr Types.monome @-> returning (const string)
  let get_serial = foreign "monome_get_serial" device_to_const_string
  let get_devpath = foreign "monome_get_devpath" device_to_const_string
  let get_friendly_name = foreign "monome_get_friendly_name" device_to_const_string
  let get_proto = foreign "monome_get_proto" device_to_const_string
  let get_rows = foreign "monome_get_rows" @@ ptr Types.monome @-> returning int
  let get_cols = foreign "monome_get_cols" @@ ptr Types.monome @-> returning int

  let register_handler =
    foreign "monome_register_handler"
    @@ ptr Types.monome
    @-> Types.event_t
    @-> Types.event_handler
    @-> ptr void
    @-> returning int
  ;;

  let unregister_handler =
    foreign "monome_unregister_handler"
    @@ ptr Types.monome
    @-> Types.event_t
    @-> returning int
  ;;

  let next =
    foreign "monome_event_next" @@ ptr Types.monome @-> ptr Types.event @-> returning int
  ;;

  let handle_next =
    foreign "monome_event_handle_next" @@ ptr Types.monome @-> returning int
  ;;

  let event_loop = foreign "monome_event_loop" @@ ptr Types.monome @-> returning void
  let get_fd = foreign "monome_get_fd" @@ ptr Types.monome @-> returning int

  (* Grid commands *)
  let set_led =
    foreign "monome_led_set"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> uint
    @-> returning int
  ;;

  let led_on =
    foreign "monome_led_on" @@ ptr Types.monome @-> uint @-> uint @-> returning int
  ;;

  let led_off =
    foreign "monome_led_off" @@ ptr Types.monome @-> uint @-> uint @-> returning int
  ;;

  let led_all = foreign "monome_led_all" @@ ptr Types.monome @-> uint @-> returning int

  let map_led =
    foreign "monome_led_map"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> ptr (const uint8_t)
    @-> returning int
  ;;

  let set_column =
    foreign "monome_led_col"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> size_t
    @-> ptr (const uint8_t)
    @-> returning int
  ;;

  let set_row =
    foreign "monome_led_row"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> size_t
    @-> ptr (const uint8_t)
    @-> returning int
  ;;

  let set_itensity =
    foreign "monome_led_intensity" @@ ptr Types.monome @-> uint @-> returning int
  ;;

  let set_level =
    foreign "monome_led_level_set"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> uint
    @-> returning int
  ;;

  let set_level_all =
    foreign "monome_led_level_all" @@ ptr Types.monome @-> uint @-> returning int
  ;;

  let level_map =
    foreign "monome_led_level_map"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> ptr (const uint8_t)
    @-> returning int
  ;;

  let set_level_row =
    foreign "monome_led_level_row"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> size_t
    @-> const (ptr uint8_t)
    @-> returning int
  ;;

  let set_level_col =
    foreign "monome_led_level_col"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> size_t
    @-> const (ptr uint8_t)
    @-> returning int
  ;;

  let get_grid =
    foreign "monome_event_get_grid"
    @@ ptr (const Types.event)
    @-> ptr uint
    @-> ptr uint
    @-> ptr (ptr Types.monome)
    @-> returning int
  ;;

  (* Arc functions *)
  let set_ring =
    foreign "monome_led_ring_set"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> uint
    @-> returning int
  ;;

  let set_ring_all =
    foreign "monome_led_ring_all" @@ ptr Types.monome @-> uint @-> uint @-> returning int
  ;;

  let ring_map =
    foreign "monome_led_ring_map"
    @@ ptr Types.monome
    @-> uint
    @-> ptr (const uint8_t)
    @-> returning int
  ;;

  let ring_range =
    foreign "monome_led_ring_range"
    @@ ptr Types.monome
    @-> uint
    @-> uint
    @-> uint
    @-> uint
    @-> returning int
  ;;

  (* Tilt functions *)
  let tilt_enable =
    foreign "monome_tilt_enable" @@ ptr Types.monome @-> uint @-> returning int
  ;;

  let tilt_disable =
    foreign "monome_tilt_disable" @@ ptr Types.monome @-> uint @-> returning int
  ;;
end
