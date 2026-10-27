module File_entry = File_entry
module Reader = Reader

let read in_stream =
  let reader = Reader.make in_stream in
  Reader.read_entries reader

let of_bigstring source = Bytream.In.of_bigstring source |> read
and of_channel ic = Bytream.In.of_channel ic |> read
