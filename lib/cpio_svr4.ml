module File_entry = File_entry
module Reader = Reader

let read in_stream =
  let reader = Reader.make in_stream in
  Reader.read_entries reader
