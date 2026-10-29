module In = Bytream.In

module Error = struct
  type t =
    | Invalid_magic_code
    | Illegal_special_device
    | Checksum_mismatched
    | Too_much_read_content
    | Invalid_path_name

  exception Error of t * string
end

let[@inline] raise_error kind message = raise @@ Error.Error (kind, message)

(**********************************************************************************)

(** [calculate_padding n] calculates 32-bit alignment padding after [n] bytes.
*)
let[@inline] calculate_padding n_bytes = (4 - (n_bytes mod 4)) mod 4

module Bytes = struct
  include Bytes

  let[@inline] get_int_be buf off = get_int32_be buf off |> Int32.to_int
end

(**********************************************************************************)

let[@inline] kind_of_mode mode =
  match mode land 0o170000 with
  | 0o140000 -> `Socket
  | 0o120000 -> `Symlink
  | 0o100000 -> `Regular
  | 0o060000 -> `Block_device
  | 0o040000 -> `Directory
  | 0o020000 -> `Character_device
  | 0o010000 -> `Fifo
  | typ ->
      invalid_arg @@ Printf.sprintf "illegal cpio file entry type 0o%06o" typ

let[@inline] permission_of_mode mode = mode land 0o7777

(**********************************************************************************)

type t = { in_stream : In.t; decoded_hex_buf : bytes; hex_buf : bytes }

let make in_stream =
  { in_stream; decoded_hex_buf = Bytes.create 57; hex_buf = Bytes.create 104 }

let[@inline] input_version in_stream =
  match In.input_string in_stream 6 with
  | "070701" -> `Newc
  | "070702" -> `Crc
  | code ->
      raise_error Invalid_magic_code
      @@ Printf.sprintf "expected 070701 or 070702 magic code but got %S bytes"
           code

and[@inline] input_path_string in_stream length =
  let path = In.input_string in_stream (length - 1) in

  if In.input_uint8 in_stream <> 0 then
    raise_error Invalid_path_name "a path string must be NULL-terminated";

  path

let read_entry_with reader f =
  let { in_stream; decoded_hex_buf; hex_buf } = reader in

  let version = input_version in_stream in

  In.really_input_bytes in_stream hex_buf 0 104;
  Hexen.decode_into (Bytes.unsafe_to_string hex_buf) 0 decoded_hex_buf 0 104;

  let inode = Bytes.get_int32_be decoded_hex_buf 0
  and mode = Bytes.get_int_be decoded_hex_buf 4
  and user_id = Bytes.get_int_be decoded_hex_buf 8
  and group_id = Bytes.get_int_be decoded_hex_buf 12
  and nlink = Bytes.get_int_be decoded_hex_buf 16
  and mtime = Bytes.get_int32_be decoded_hex_buf 20
  and content_length = Bytes.get_int_be decoded_hex_buf 24
  and dmajor = Bytes.get_int_be decoded_hex_buf 28
  and dminor = Bytes.get_int_be decoded_hex_buf 32
  and rdmajor = Bytes.get_int_be decoded_hex_buf 36
  and rdminor = Bytes.get_int_be decoded_hex_buf 40
  and name_size = Bytes.get_int_be decoded_hex_buf 44
  and checksum = Bytes.get_int32_be decoded_hex_buf 48 in

  let path = input_path_string in_stream name_size in

  let kind = if path <> "TRAILER!!!" then kind_of_mode mode else `Regular in
  let special_device =
    match kind with
    | `Block_device | `Character_device ->
        Some File_entry.{ major = rdmajor; minor = rdminor }
    | _ -> None
  and checksum = match version with `Crc -> Some checksum | `Newc -> None in

  (* skip padding after path string *)
  In.consume_bytes in_stream @@ calculate_padding (110 + name_size);

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

  let result, content_bytes_read =
    In.with_size (fun _ -> f ~content_length file_entry) in_stream
  in

  let remaining_unreadable_content_bytes =
    content_length - content_bytes_read
  in

  (* If the user function read too much file content. *)
  if remaining_unreadable_content_bytes < 0 then begin
    raise_error Too_much_read_content
    @@ Printf.sprintf "%d bytes should have been read, but %d bytes were read"
         content_length content_bytes_read
  end;

  (* skip padding after file content *)
  In.consume_bytes in_stream
  @@ (calculate_padding content_length + remaining_unreadable_content_bytes);

  result

let read_entry reader =
  read_entry_with reader @@ fun ~content_length file_entry ->
  let content = In.input_string reader.in_stream content_length in
  let file_entry = { file_entry with content } in

  if File_entry.verify_string_content file_entry = false then begin
    let checksum = Option.get file_entry.checksum in
    raise_error Checksum_mismatched
    @@ Printf.sprintf "invalid 0x%04lX checksum" checksum
  end;

  file_entry

let read_entry_without_content reader =
  read_entry_with reader @@ fun ~content_length _ -> ()

(* *)

let rec fold f acc reader =
  let file_entry = read_entry reader in
  if File_entry.is_trailer file_entry then acc
  else fold f (f acc file_entry) reader

let iter f reader = fold (fun () file_entry -> f file_entry) () reader

(* *)

let rec fold_with f acc reader =
  let exception Trailer in
  try
    let acc =
      read_entry_with reader begin fun ~content_length file_entry ->
          if File_entry.is_trailer file_entry then raise_notrace Trailer;
          f ~content_length acc file_entry
        end
    in

    fold_with f acc reader
  with Trailer -> acc

let rec iter_with f reader =
  fold_with
    begin fun ~content_length () file_entry -> f ~content_length file_entry
    end
    () reader

(* *)

let read_entries reader = fold (Fun.flip List.cons) [] reader
