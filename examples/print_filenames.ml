let print_simple_filenames ic =
  Cpio_svr4.of_channel ic
  |> List.iter @@ fun Cpio_svr4.File_entry.{ path; _ } -> print_endline path

let print_effective_filenames ic =
  let in_stream = Bytream.In.of_channel ~io_buffer_size:0xFFFF ic in
  let reader = Cpio_svr4.Reader.make in_stream in

  Cpio_svr4.Reader.iter_with
    (fun ~content_length:_ file_entry -> print_endline file_entry.path)
    reader

let () =
  In_channel.with_open_bin Sys.argv.(2) @@ fun ic ->
  match Sys.argv.(1) with
  | "simple" -> print_simple_filenames ic
  | "effective" -> print_effective_filenames ic
  | _ -> invalid_arg "unknown print filenames method"
