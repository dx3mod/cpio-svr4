type 'content t = {
  path : string;
  kind : kind;
  content : 'content;
  metadata : metadata;
}

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

let is_trailer { path; _ } = path = "TRAILER!!!"
