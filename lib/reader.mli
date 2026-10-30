(** CPIO (SVR4) archive reader.

    A reader can consume one or more archives sequentially from an incoming byte
    stream. *)

type t
(** The type for reader state. *)

val make : Bytream.In.t -> t
(** [make in_stream] creates a reader from the incoming byte stream. *)

(** {2 Buffered reading}

    These functions read file entries and buffer their content in memory. Use
    these for small to medium-sized files. For large files or memory-constrained
    environments, consider the unbuffered reading functions in "Unbuffered
    reading" section. *)

val read_entry : t -> File_entry.with_string_content
(** [read_entry reader] reads the next file entry from the incoming byte stream.

    The trailer entry is returned like any other entry; use
    {!File_entry.is_trailer} to detect it and stop, or to continue into the next
    archive.

    @raise Error.Error on malformed input.
    @raise End_of_file if the stream ends prematurely. *)

val read_entries : t -> File_entry.with_string_content list
(** [read_entries reader] reads all file entries from the incoming byte stream,
    excluding the trailer entry.

    @raise Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

(** {3 Traverse} *)

val fold : ('acc -> File_entry.with_string_content -> 'acc) -> 'acc -> t -> 'acc
(** [fold f acc reader] applies [f] to each file entry read from the incoming
    byte stream, excluding the trailer entry.

    @raise Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

val iter : (File_entry.with_string_content -> unit) -> t -> unit
(** [iter f reader] iterates over file entries from the incoming byte stream.

    @raise Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

(** {2 Unbuffered reading}

    These functions allow streaming access to file contents without buffering
    them entirely in memory. Useful for large files or when you want to process
    entry's content incrementally. *)

val read_entry_with :
  t -> (content_length:int -> File_entry.without_content -> 'a) -> 'a
(** [read_entry_with reader f] reads the next file entry header and lets [f]
    consume its content directly from the incoming byte stream.

    [f] receives the declared content length and an entry without content. It
    may read up to [content_length] bytes; any unread bytes and padding are
    skipped automatically.

    @raise Error.Error
      on malformed input or if [f] reads more than [content_length] bytes.
    @raise End_of_file if the stream ends prematurely. *)

val read_entry_without_content : t -> File_entry.without_content
(** [read_entry_without_content reader] reads the next file entry header without
    consuming its content from the incoming byte stream.

    @raise Error.Error on malformed input.
    @raise End_of_file if the stream ends prematurely. *)

(** {3 Traverse} *)

val fold_with :
  (content_length:int -> 'acc -> File_entry.without_content -> 'acc) ->
  'acc ->
  t ->
  'acc
(** [fold_with f acc reader] folds over file entries without buffering their
    content from the incoming byte stream.

    [f] consumes (or leaves unread) each file entry's content; see
    {!read_entry_with}. The trailer entry terminates the [fold] and is not
    passed to [f].

    @raise Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

val iter_with :
  (content_length:int -> File_entry.without_content -> unit) -> t -> unit
(** [iter_with f reader] iterates over file entries without buffering their
    content from the incoming byte stream.

    @raise Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

(** {2 Errors} *)

module Error : sig
  type t =
    | Invalid_magic_code  (** The magic number is not "070701" or "070702". *)
    | Invalid_header_hexadecimal  (** Header contains non-hex characters. *)
    | Invalid_content_length  (** Content length is negative or invalid. *)
    | Invalid_path_name  (** Path name is invalid or not null-terminated. *)
    | Invalid_mode  (** File mode bits are invalid. *)
    | Checksum_mismatch  (** CRC checksum verification failed. *)
    | Too_much_read_content  (** Callback read more bytes than declared. *)

  exception Error of t * string
end
