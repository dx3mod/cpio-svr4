type 'content t = {
  path : string;
  kind : kind;
  content : 'content;
  metadata : metadata;
  checksum : int32 option;
}

and with_string_content = string t
and with_bigstring_content = Bstr.t t
and without_content = unit t

and kind =
  [ `Regular
  | `Directory
  | `Symlink
  | `Fifo
  | `Socket
  | `Block_device
  | `Character_device ]

and metadata = {
  owner : owner;
  permission : int32;
  modification_time : int32;
  device : device;
  special_device : device option;
  inode : index_node;
}

and owner = { user_id : int; group_id : int }
and device = { major : int; minor : int }
and index_node = { inode : int32; link_count : int }

val is_trailer : _ t -> bool
val verify_string_content : string t -> bool
val verify_bigstring_content : Bstr.t t -> bool
