let to_flat_index : x:int -> y:int -> width:int -> int =
  fun ~x ~y ~width -> x + (y * width)
;;
