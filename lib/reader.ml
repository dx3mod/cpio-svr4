module In = Bytream.In
open Private

module Error = struct
  type t =
    | Invalid_magic_code
    | Invalid_header_hexadecimal
    | Invalid_content_length
    | Invalid_path_name
    | Invalid_mode
    | Checksum_mismatch
    | Too_much_read_content

  exception Error of t * string
end

let[@inline] raise_error kind message = raise (Error.Error (kind, message))

type t = { in_stream : In.t; decoded_hex_buf : bytes; hex_buf : bytes }
(* Reusable scratch buffers: 104 hex characters decode into 52 binary bytes (13
    big-endian 32-bit fields). No allocation per entry. *)

let make in_stream =
  { in_stream; decoded_hex_buf = Bytes.create 52; hex_buf = Bytes.create 104 }

let[@inline] input_version in_stream =
  match In.input_string in_stream 6 with
  | "070701" -> `Newc
  | "070702" -> `Crc
  | code ->
      raise_error Invalid_magic_code
      @@ Printf.sprintf "expected \"070701\" or \"070702\", got %S" code

let[@inline] input_path_string in_stream length =
  if length <= 0 then
    raise_error Invalid_path_name "the path length cannot be <= 0";

  let path = In.input_string in_stream (length - 1) in

  if In.input_uint8 in_stream <> 0 then
    raise_error Invalid_path_name "the path must be NULL-terminated";

  path

let read_entry_with { in_stream; decoded_hex_buf; hex_buf } f =
  let version = input_version in_stream in

  In.really_input_bytes in_stream hex_buf 0 104;

  begin try
    Hexen.decode_into (Bytes.unsafe_to_string hex_buf) 0 decoded_hex_buf 0 104
  with Invalid_argument msg -> raise_error Invalid_header_hexadecimal msg
  end;

  let inode = Bytes.get_int32_be decoded_hex_buf 0
  and mode = Bytes.get_int_be decoded_hex_buf 4
  and user_id = Bytes.get_int_be decoded_hex_buf 8
  and group_id = Bytes.get_int_be decoded_hex_buf 12
  and nlink = Bytes.get_int_be decoded_hex_buf 16
  and mtime = Bytes.get_int32_be decoded_hex_buf 20
  and content_length = Bytes.get_int_be decoded_hex_buf 24
  and dmajor = Bytes.get_int_be decoded_hex_buf 28
  and dminor = Bytes.get_int_be decoded_hex_buf 32
  and special_major = Bytes.get_int_be decoded_hex_buf 36
  and special_minor = Bytes.get_int_be decoded_hex_buf 40
  and name_size = Bytes.get_int_be decoded_hex_buf 44
  and stored_checksum = Bytes.get_int32_be decoded_hex_buf 48 in

  if content_length < 0 then
    raise_error Invalid_content_length
    @@ Printf.sprintf "file size %lu does not fit on this platform"
         (Bytes.get_int32_be decoded_hex_buf 24);

  let path = input_path_string in_stream name_size in

  let kind = if path = "TRAILER!!!" then `Regular else kind_of_mode mode in
  let special_device =
    match kind with
    | `Block_device | `Character_device ->
        Some File_entry.{ major = special_major; minor = special_minor }
    | _ -> None
  in
  let checksum =
    match version with `Crc -> Some stored_checksum | `Newc -> None
  in

  let file_entry =
    File_entry.
      {
        path;
        kind;
        content = ();
        checksum;
        metadata =
          {
            owner = { user_id; group_id };
            permission = permission_of_mode mode;
            modification_time = mtime;
            device = { major = dmajor; minor = dminor };
            special_device;
            inode = { inode; hard_link_count = nlink };
          };
      }
  in

  (* The "070701"/"070702" magic plus 13 hex fields is exactly 110 bytes.
     Alignment is relative to the start of the archive, so [make] requires a
     4-byte-aligned stream position. *)
  In.consume_bytes in_stream
    (calculate_padding (110 + String.length file_entry.path + 1));

  let result, bytes_read =
    In.with_size (fun _ -> f ~content_length file_entry) in_stream
  in

  let unread = content_length - bytes_read in
  if unread < 0 then
    raise_error Too_much_read_content
    @@ Printf.sprintf "expected at most %d content bytes, but %d were read"
         content_length bytes_read;

  (* Skip whatever the callback left unread, then the data padding. *)
  In.consume_bytes in_stream (unread + calculate_padding content_length);

  result

let read_entry reader =
  read_entry_with reader @@ fun ~content_length entry ->
  let content = In.input_string reader.in_stream content_length in
  let file_entry = { entry with content } in

  Option.iter
    (fun expected_checksum ->
      if File_entry.verify_string_content file_entry = false then
        raise_error Checksum_mismatch
        @@ Printf.sprintf "%S: expected checksum %08lx" file_entry.path
             expected_checksum)
    file_entry.checksum;

  file_entry

let read_entry_without_content reader =
  read_entry_with reader @@ fun ~content_length:_ file_entry -> file_entry

let rec fold f acc reader =
  let entry = read_entry reader in
  if File_entry.is_trailer entry then acc else fold f (f acc entry) reader

let iter f reader = fold (fun () entry -> f entry) () reader

let rec fold_with f acc reader =
  let acc, is_trailer =
    read_entry_with reader @@ fun ~content_length entry ->
    if File_entry.is_trailer entry then (acc, true)
    else (f ~content_length acc entry, false)
  in

  if is_trailer then acc else fold_with f acc reader

let iter_with f reader =
  fold_with (fun ~content_length () entry -> f ~content_length entry) () reader

let read_entries reader = fold (Fun.flip List.cons) [] reader
