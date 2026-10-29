(** CPIO (SVR4) archive file entry with agnostic content type. *)

type 'content t = {
  path : string;
  kind : kind;
  content : 'content;
  metadata : metadata;
  checksum : int32 option;
}
(** The type represents a archive file entry with possible different content
    types. *)

and with_string_content = string t
(** The type represents a archive file entry with string content. *)

and with_bigstring_content = Bstr.t t
(** The type represents a archive file entry with bigstring content. *)

and without_content = unit t
(** The type represents a archive file entry withount content. *)

and kind =
  [ `Regular
  | `Directory
  | `Symlink
  | `Fifo
  | `Socket
  | `Block_device
  | `Character_device ]
(** The file entry type. *)

and metadata = {
  owner : owner;
  permission : int;
  modification_time : int32;
  device : device;
  special_device : device option;
  inode : index_node;
}
(** The file entry metadata from a filesystem. *)

and owner = { user_id : int; group_id : int }
and device = { major : int; minor : int }
and index_node = { inode : int32; hard_link_count : int }

val is_trailer : _ t -> bool
(** [is_trailer entry] returns [true] if the file [entry] has the name
    ["TRAILER!!!"] otherwise it returns [false]. *)

val trailer : unit t
(** Pre-defined trailer file entry. *)

val verify_string_content : string t -> bool
(** [verify_string_content entry] checks checksum for the file's [entry]
    content.

    @return
      If the checksum matches, then returns true. Otherwise, returns false. *)

val verify_bigstring_content : Bstr.t t -> bool
(** [verify_bigstring_content entry] is similar to the {!verify_string_content}
    function, but for bigstring values. *)
