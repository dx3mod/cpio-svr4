let _ =
  In_channel.with_open_bin Sys.argv.(1) @@ fun ic ->
  let aux () =
    In_channel.seek ic 0L;

    let in_stream = Bytream.In.of_channel ic in

    Cpio_svr4.read in_stream
  in

  Benchmark.latency1 ~name:"optimized bytream cpio" 1000L aux ()
