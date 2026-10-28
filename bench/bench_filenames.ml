let print_simple_filenames in_stream =
  Cpio_svr4.Reader.make in_stream
  |> Cpio_svr4.Reader.read_entries
  |> List.iter @@ fun Cpio_svr4.File_entry.{ path; _ } -> ignore path

let print_effective_filenames in_stream =
  let reader = Cpio_svr4.Reader.make in_stream in

  Cpio_svr4.Reader.iter_with
    (fun ~content_length:_ file_entry -> ignore file_entry.path)
    reader

let _ =
  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading from file (effective)"
        1000L
        begin fun ic ->
          In_channel.seek ic 0L;
          print_effective_filenames @@ Bytream.In.of_channel ic
        end
        ic
      |> ignore
    end;

  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading from file (simple)" 1000L
        begin fun ic ->
          In_channel.seek ic 0L;
          print_simple_filenames @@ Bytream.In.of_channel ic
        end
        ic
      |> ignore
    end;

  print_endline "\n\n";

  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading from buffer (effective)"
        10_000L
        begin fun archive_content ->
          print_effective_filenames @@ Bytream.In.of_bigstring archive_content
        end
        (In_channel.input_all ic |> Bstr.of_string)
      |> ignore
    end;

  In_channel.with_open_bin Sys.argv.(1) begin fun ic ->
      Benchmark.latency1 ~name:"CPIO filenames reading from buffer (simple)"
        10_000L
        begin fun archive_content ->
          print_simple_filenames @@ Bytream.In.of_bigstring archive_content
        end
        (In_channel.input_all ic |> Bstr.of_string)
      |> ignore
    end
