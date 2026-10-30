(** [calculate_padding n] calculates 32-bit alignment padding after [n] bytes.
*)
let[@inline] calculate_padding n_bytes = (4 - (n_bytes mod 4)) mod 4

module Bytes = struct
  include Bytes

  let[@inline] get_int_be buf off = get_int32_be buf off |> Int32.to_int
  let[@inline] set_int_be buf off x = set_int32_be buf off (Int32.of_int x)
end

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

let[@inline] int32_of_kind kind =
  match kind with
  | `Socket -> 0o140000l
  | `Symlink -> 0o120000l
  | `Regular -> 0o100000l
  | `Block_device -> 0o060000l
  | `Directory -> 0o040000l
  | `Character_device -> 0o020000l
  | `Fifo -> 0o010000l

let[@inline] int32_of_permission perm = Int32.logand (Int32.of_int perm) 0o7777l
