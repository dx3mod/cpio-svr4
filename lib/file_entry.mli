(** CPIO (SVR4) archive file entry with polymorphic content type. *)

type 'content t = {
  path : string;
  kind : kind;
  content : 'content;
  metadata : metadata;
  checksum : int32 option;
}
(** The type represents an archive file entry with polymorphic content.

    The ['content] type parameter allows the entry to hold different content
    representations:
    - [string] for buffered content
    - [Bstr.t] for bigstring content
    - [unit] when content is not loaded or not applicable *)

and with_string_content = string t
(** An archive file entry with string content. *)

and with_bigstring_content = Bstr.t t
(** An archive file entry with bigstring content. *)

and without_content = unit t
(** An archive file entry without content. *)

and kind =
  [ `Regular
  | `Directory
  | `Symlink
  | `Fifo
  | `Socket
  | `Block_device
  | `Character_device ]
(** The type of file entry. *)

and metadata = {
  owner : owner;
  permission : int;
  modification_time : int32;
  device : device;
  special_device : device option;
  inode : index_node;
}
(** File entry metadata from the filesystem. *)

and owner = { user_id : int; group_id : int }
(** File owner information. *)

and device = { major : int; minor : int }
(** Device numbers (major and minor). *)

and index_node = { inode : int32; hard_link_count : int }
(** Inode information including the inode number and hard link count. *)

(** {2 Trailer detection} *)

val is_trailer : _ t -> bool
(** [is_trailer entry] returns [true] if the file entry has the path
    ["TRAILER!!!"], [false] otherwise.

    The trailer entry marks the end of a CPIO archive. *)

val trailer : unit t
(** A pre-defined trailer file entry with path ["TRAILER!!!"]. *)

(** {2 Checksum verification} *)

val verify_string_content : string t -> bool
(** [verify_string_content entry] verifies the checksum of the entry's content.

    If [entry.checksum] is [None], the function returns [true] (no verification
    needed). Otherwise, it computes the CRC-32 checksum of the content and
    compares it with the stored checksum.

    @return
      [true] if the checksum matches or if no checksum verification is required,
      [false] otherwise. *)

val verify_bigstring_content : Bstr.t t -> bool
(** [verify_bigstring_content entry] is similar to {!verify_string_content}, but
    operates on bigstring content.

    @return
      [true] if the checksum matches or if no checksum verification is required,
      [false] otherwise. *)
