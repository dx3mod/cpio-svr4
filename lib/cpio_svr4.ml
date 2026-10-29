module File_entry = File_entry
module Reader = Reader
module Writer = Writer

let read in_stream =
  let reader = Reader.make in_stream in
  Reader.read_entries reader

let of_bigstring source = Bytream.In.of_bigstring source |> read
and of_channel ic = Bytream.In.of_channel ic |> read

let write out_stream entries =
  let writer = Writer.make out_stream in
  Writer.write_entries_with_trailer writer entries

let to_buffer buffer entries =
  Bytream.Out.to_buffer buffer (Fun.flip write entries)

let to_string entries = Bytream.Out.to_string (Fun.flip write entries)
let to_channel oc entries = Bytream.Out.of_channel oc |> Fun.flip write entries
