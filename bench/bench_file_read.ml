let _ =
  In_channel.with_open_bin Sys.argv.(1) @@ fun ic ->
  let aux () =
    In_channel.seek ic 0L;

    Cpio_svr4.of_channel ic
  in

  Benchmark.latency1 ~name:"CPIO file reading" 1000L aux ()
