let _ =
  In_channel.with_open_bin Sys.argv.(1) @@ fun ic ->
  let file_entries = Cpio_svr4.of_channel ic in

  let dev_null = open_out_bin "/dev/null" in

  let buffer = Buffer.create 0xFFFF in
  let aux () =
    Buffer.clear buffer;

    let out_stream =
      Bytream.Out.make @@ fun slice ->
      Out_channel.output_bigarray dev_null slice.buf slice.off slice.len
    in

    Cpio_svr4.write out_stream file_entries
  in

  Benchmark.latency1 ~name:"CPIO archive string writing" 1000L aux ()
