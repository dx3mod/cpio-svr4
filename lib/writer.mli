(** Incremental CPIO (SVR4) archive writer.

    A writer can produce one or more archives sequentially to an outgoing byte
    stream. Each archive must be terminated with a trailer entry. *)

type t
(** The type of writer state. *)

val make : Bytream.Out.t -> t
(** [make out_stream] creates a new writer state from the outgoing byte stream.
*)

(** {1 Writing file entries with string content} *)

val write_entry : t -> File_entry.with_string_content -> unit
(** [write_entry writer entry] writes the file [entry] with string content to
    the [writer].

    The entry's content is written as-is, followed by appropriate padding to
    maintain 4-byte alignment. *)

val write_entries : t -> File_entry.with_string_content list -> unit
(** [write_entries writer entries] writes the file [entries] with string content
    to the [writer] without appending a trailer entry.

    Use {!write_trailer} to finalize the archive after writing all entries. *)

val write_entries_with_trailer :
  t -> File_entry.with_string_content list -> unit
(** [write_entries_with_trailer writer entries] writes the file [entries] with
    string content to the [writer], followed by a trailer entry.

    This is equivalent to calling {!write_entries} then {!write_trailer}. *)

(** {1 Writing file entries with streaming content} *)

val write_entry_with :
  content_length:int ->
  t ->
  File_entry.without_content ->
  (Bytream.Out.t -> unit) ->
  unit
(** [write_entry_with ~content_length writer entry f] writes the file [entry]
    with content produced by [f] to the [writer].

    [f] must write exactly [content_length] bytes to the outgoing byte stream.
    The writer will automatically add padding after [f] returns to maintain
    4-byte alignment.

    @param content_length The exact number of bytes that [f] will write

    @raise Error.Error
      [Invalid_content_length] if [f] writes a number of bytes that differs from
      [content_length]. *)

(** {1 Trailer writing} *)

val write_trailer : t -> unit
(** [write_trailer writer] writes the trailer entry to the [writer], marking the
    end of the current archive.

    After calling this function, you can either start writing a new archive (by
    calling {!write_entry} again) or close the stream. *)

(** {1 Errors} *)

module Error : sig
  type t = Invalid_content_length

  exception Error of t * string
end
