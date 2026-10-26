let _ =
  let aux () =
    In_channel.with_open_bin Sys.argv.(1) @@ fun ic ->
    let in_stream = Bytream.In.of_channel ic in
    let reader = Cpio_svr4.Reader.make in_stream in

    Cpio_svr4.Reader.read_entries_seq reader |> Seq.iter ignore
  in

  Benchmark.latency1 1000L aux ()
