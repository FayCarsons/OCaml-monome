open Ctypes

module Types (F : Ctypes.TYPE) = struct
  open F

  let button_up = constant "MONOME_BUTTON_UP" int64_t
  let button_down = constant "MONOME_BUTTON_DOWN" int64_t
  let encoder_delta = constant "MONOME_ENCODER_DELTA" int64_t
  let encoder_key_up = constant "MONOME_ENCODER_KEY_UP" int64_t
  let encoder_key_down = constant "MONOME_ENCODER_KEY_DOWN" int64_t
  let tilt = constant "MONOME_TILT" int64_t
  let event_max = constant "MONOME_EVENT_MAX" int64_t

  type event_t =
    | Button_up
    | Button_down
    | Encoder_delta
    | Encoder_up
    | Encoder_down
    | Tilt
    | Max

  let event_t =
    enum
      "monome_event_type_t"
      [ Button_up, button_up
      ; Button_down, button_down
      ; Encoder_delta, encoder_delta
      ; Encoder_up, encoder_key_up
      ; Encoder_down, encoder_key_down
      ; Tilt, tilt
      ; Max, event_max
      ]
      ~typedef:true
      ~unexpected:(fun n ->
        Printf.printf "Cannot match \'monome_even_type_t\' value %d" (Int64.to_int n);
        exit 1)
  ;;

  let d0 = constant "MONOME_ROTATE_0" int64_t
  let d90 = constant "MONOME_ROTATE_90" int64_t
  let d180 = constant "MONOME_ROTATE_180" int64_t
  let d270 = constant "MONOME_ROTATE_270" int64_t

  type rotate =
    | No_turn
    | Quarter_turn
    | Half_turn
    | Three_quarter_turn

  let rotate =
    enum
      "monome_rotate_t"
      [ No_turn, d0; Quarter_turn, d90; Half_turn, d180; Three_quarter_turn, d270 ]
      ~typedef:true
      ~unexpected:(fun n ->
        Printf.printf "Cannot match \'monome_rotate_t\' value %d" (Int64.to_int n);
        exit 1)
  ;;

  type monome

  let monome : monome structure typ = typedef (structure "monome") "monome_t"

  type event

  let event : event_t structure typ = typedef (structure "monome_event") "monome_event_t"
  let device = field event "monome" monome
  let tag = field event "event_type" event_t
  (* How tf do I add an anonymous union field ????????????? *)

  type event_handler

  let event_handler =
    typedef
      (static_funptr (ptr (const monome) @-> ptr void @-> returning void))
      "monome_event_callback_t"
  ;;
end
