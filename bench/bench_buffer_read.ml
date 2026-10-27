let _ =
  In_channel.with_open_bin Sys.argv.(1) @@ fun ic ->
  let archive_content = In_channel.input_all ic |> Bstr.of_string in

  let aux () = Cpio_svr4.of_bigstring archive_content in

  Benchmark.latency1 ~name:"CPIO pre-allocated buffer reading" 1000L aux ()
