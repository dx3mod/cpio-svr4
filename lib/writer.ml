module Out = Bytream.Out
open Private

module Error = struct
  type t = Invalid_content_length

  exception Error of t * string
end

let[@inline] raise_error kind msg = raise Error.(Error (kind, msg))

type t = { out_stream : Out.t; header_buf : bytes; hex_buf : bytes }

let make out_stream =
  { out_stream; header_buf = Bytes.create 52; hex_buf = Bytes.create 104 }

let output_version out_stream file_entry =
  match file_entry.File_entry.checksum with
  | None -> Out.output_string out_stream "070701"
  | Some _ -> Out.output_string out_stream "070702"

let output_padding out_stream n =
  for i = 1 to n do
    Out.output_byte out_stream 0
  done

let write_entry_with ~content_length writer file_entry f =
  let { out_stream; header_buf; hex_buf } = writer in

  output_version out_stream file_entry;

  Bytes.set_int32_be header_buf 0 file_entry.metadata.inode.inode;
  Bytes.set_int32_be header_buf 4
    Int32.(
      logor
        (int32_of_kind file_entry.kind)
        (int32_of_permission file_entry.metadata.permission));
  Bytes.set_int_be header_buf 8 file_entry.metadata.owner.user_id;
  Bytes.set_int_be header_buf 12 file_entry.metadata.owner.group_id;
  Bytes.set_int_be header_buf 16 file_entry.metadata.inode.hard_link_count;
  Bytes.set_int32_be header_buf 20 file_entry.metadata.modification_time;
  Bytes.set_int_be header_buf 24 content_length;
  Bytes.set_int_be header_buf 28 file_entry.metadata.device.major;
  Bytes.set_int_be header_buf 32 file_entry.metadata.device.minor;

  let rdmajor, rdminor =
    match file_entry.metadata.special_device with
    | None -> (0, 0)
    | Some { major; minor } -> (major, minor)
  in

  Bytes.set_int_be header_buf 36 rdmajor;
  Bytes.set_int_be header_buf 40 rdminor;

  let path_len = String.length file_entry.path + 1 in
  Bytes.set_int_be header_buf 44 path_len;

  let checksum = Option.value ~default:0l file_entry.checksum in
  Bytes.set_int32_be header_buf 48 checksum;

  Hexen.encode_into (Bytes.unsafe_to_string header_buf) 0 hex_buf 0 52;
  Out.output_string out_stream (Bytes.unsafe_to_string hex_buf);

  Out.output_string out_stream file_entry.path;
  Out.output_byte out_stream 0;

  output_padding out_stream (calculate_padding (110 + path_len));

  let bytes_written_snapshot = Out.bytes_written out_stream in
  f out_stream;

  let current_bytes_written = Out.bytes_written out_stream in
  if current_bytes_written - bytes_written_snapshot <> content_length then
    raise_error Invalid_content_length
      (Printf.sprintf "expected %d bytes to be written, but %d were written"
         content_length
         (current_bytes_written - bytes_written_snapshot));

  output_padding out_stream (calculate_padding content_length)

let write_entry writer (file_entry : File_entry.with_string_content) =
  write_entry_with
    ~content_length:(String.length file_entry.content)
    writer file_entry
  @@ fun out_stream -> Out.output_string out_stream file_entry.content

let write_trailer writer =
  write_entry_with ~content_length:0 writer File_entry.trailer ignore

let write_entries writer entries = List.iter (write_entry writer) entries

let write_entries_with_trailer writer entries =
  write_entries writer entries;
  write_trailer writer
