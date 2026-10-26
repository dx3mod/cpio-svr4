module In = Bytream.In

module Error = struct
  type t = Invalid_magic_code | Illegal_special_device | Checksum_mismatched

  exception Error of t * string
end

let[@inline] raise_error kind message = raise @@ Error.Error (kind, message)

(**********************************************************************************)

let input_padding in_stream =
  In.consume_bytes in_stream ((4 - (In.bytes_received in_stream mod 4)) mod 4)

module Bytes = struct
  include Bytes

  let get_int_be buf off = get_int32_be buf off |> Int32.to_int
end

(**********************************************************************************)

let kind_of_mode mode =
  match Int32.logand mode 0o170000l with
  | 0o140000l -> `Socket
  | 0o120000l -> `Symlink
  | 0o100000l -> `Regular
  | 0o060000l -> `Block_device
  | 0o040000l -> `Directory
  | 0o020000l -> `Character_device
  | 0o010000l -> `Fifo
  | typ ->
      invalid_arg @@ Printf.sprintf "illegal cpio file entry type 0o%06lo" typ

let permission_of_mode mode = Int32.logand mode 0o7777l

(**********************************************************************************)

type t = { in_stream : In.t; decoded_hex_buf : bytes; hex_buf : bytes }

let make in_stream =
  { in_stream; decoded_hex_buf = Bytes.create 57; hex_buf = Bytes.create 104 }

let input_version in_stream =
  match In.input_string in_stream 6 with
  | "070701" -> `Newc
  | "070702" -> `Crc
  | code ->
      raise_error Invalid_magic_code
      @@ Printf.sprintf "expected 070701 or 070702 code but got %s" code

exception Trailer

let read_entry_with reader f =
  let { in_stream; decoded_hex_buf; hex_buf } = reader in

  let version = input_version in_stream in

  In.really_input_bytes in_stream hex_buf 0 104;
  Hexen.decode_into (Bytes.unsafe_to_string hex_buf) 0 decoded_hex_buf 0 104;

  let inode = Bytes.get_int32_be decoded_hex_buf 0
  and mode = Bytes.get_int32_be decoded_hex_buf 4
  and user_id = Bytes.get_int_be decoded_hex_buf 8
  and group_id = Bytes.get_int_be decoded_hex_buf 12
  and nlink = Bytes.get_int_be decoded_hex_buf 16
  and mtime = Bytes.get_int32_be decoded_hex_buf 20
  and file_size = Bytes.get_int32_be decoded_hex_buf 24
  and dmajor = Bytes.get_int_be decoded_hex_buf 28
  and dminor = Bytes.get_int_be decoded_hex_buf 32
  and rdmajor = Bytes.get_int_be decoded_hex_buf 36
  and rdminor = Bytes.get_int_be decoded_hex_buf 40
  and name_size = Bytes.get_int_be decoded_hex_buf 44
  and checksum = Bytes.get_int_be decoded_hex_buf 48 in

  let path =
    let zero_code = char_of_int 0 in
    In.input_while' ~max_len:name_size (( <> ) zero_code) in_stream
  in

  input_padding in_stream;

  let content =
    let checksum =
      match version with
      | `Crc -> Some checksum
      | `Newc ->
          assert (checksum = 0);
          None
    in
    f checksum file_size
  in
  input_padding in_stream;

  let kind = if path <> "TRAILER!!!" then kind_of_mode mode else `Regular in

  let special_device =
    match kind with
    | `Block_device | `Character_device ->
        Some File_entry.{ major = rdmajor; minor = rdminor }
    | _ -> None
  in

  File_entry.
    {
      path;
      kind;
      content;
      metadata =
        {
          owner = { user_id; group_id };
          permission = permission_of_mode mode;
          modification_time = mtime;
          device = { major = dmajor; minor = dminor };
          special_device;
          inode = { inode; link_count = nlink };
        };
    }

let read_entry reader =
  read_entry_with reader @@ fun checksum size ->
  let content = In.input_string reader.in_stream (Int32.to_int size) in

  (* checksum assertion *)
  Option.iter
    (fun checksum ->
      let expected_checksum = Checksum.calculate_for_string_content content in
      if checksum <> expected_checksum then
        raise_error Checksum_mismatched
        @@ Printf.sprintf "expected 0x%X checksum but got 0x%X"
             expected_checksum checksum)
    checksum;

  content

let read_entry_without_content reader =
  read_entry_with reader @@ fun _ size ->
  In.consume_bytes reader.in_stream (Int32.to_int size)

let read_entries reader =
  let rec loop reader =
    let file_entry = read_entry reader in
    if File_entry.is_trailer file_entry then [] else file_entry :: loop reader
  in

  loop reader

let read_entries_seq reader =
  Seq.of_dispenser @@ fun () ->
  let file_entry = read_entry reader in
  if File_entry.is_trailer file_entry then None else Some file_entry

let read_entries_with reader f k =
  let rec loop reader f =
    let file_entry = read_entry_with reader f in
    if not (File_entry.is_trailer file_entry) then begin
      k file_entry;
      loop reader f
    end
  in

  loop reader f
