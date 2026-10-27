let print_simple_filenames ic =
  In_channel.seek ic 0L;

  Cpio_svr4.of_channel ic
  |> List.iter @@ fun Cpio_svr4.File_entry.{ path; _ } -> ignore path

let print_effective_filenames ic =
  In_channel.seek ic 0L;

  let in_stream = Bytream.In.of_channel ic in
  let reader = Cpio_svr4.Reader.make in_stream in

  Cpio_svr4.Reader.read_entries_with reader
    (fun _ size -> Bytream.In.consume_bytes in_stream (Int32.to_int size))
    (fun file_entry -> ignore file_entry.path)

let _ =
  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading (effective)" 1000L
        print_effective_filenames ic
      |> ignore
    end;

  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading (simple)" 1000L
        print_simple_filenames ic
      |> ignore
    end
