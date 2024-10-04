let () =
  match Monome.create () with
  | Some device -> Printf.printf "Got device: %s" @@ Monome.get_name device
  | None -> failwith "No device detected"
  | exception Failure reason ->
    print_endline reason;
    exit 1
;;
