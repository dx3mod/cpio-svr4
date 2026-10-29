(** CPIO (SVR4) archive writer. *)

type t
(** The type of writer state. *)

val make : Bytream.Out.t -> t
(** [make out_stream] creates a new writer state. *)

(** {2 Writing file entries with string content} *)

val write_entry : t -> File_entry.with_string_content -> unit
(** [write_entry writer entry] writes the file [entry] with string content to
    the [writer]. *)

val write_entries : t -> File_entry.with_string_content list -> unit
(** [write_entries writer entries] writes the file [entries] with string
    contents to the [writer] without a trailer entry at the end. *)

val write_entries_with_trailer :
  t -> File_entry.with_string_content list -> unit
(** [write_entries_with_trailer writer entries] writes the file [entries] with
    string contents to the [writer] with a trailer entry at the end. *)

(** {2 Manual file entry writing} *)

val write_entry_with :
  content_length:int -> t -> _ File_entry.t -> (Bytream.Out.t -> unit) -> unit
(** [write_entry_with ~content_length writer entry f] writes the file [entry]
    with content produced by [f] to the [writer]. *)

(** {2 Trailer writing} *)

val write_trailer : t -> unit
(** [write_trailer writer] writes the trailer entry to the [writer]. *)
