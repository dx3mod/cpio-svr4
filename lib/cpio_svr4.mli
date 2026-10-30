(** A library for reading and writing CPIO (SVR4) archives, written in pure
    OCaml. *)

module File_entry = File_entry

(** {2 Reading} *)

val read : Bytream.In.t -> File_entry.with_string_content list
(** [read in_stream] reads all entries from the archive in [in_stream], up to
    and excluding the trailer.

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

val of_bigstring : Bstr.t -> File_entry.with_string_content list
(** [of_bigstring bs] reads all entries from the archive in [bs].

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

val of_channel : in_channel -> File_entry.with_string_content list
(** [of_channel ic] reads all entries from the archive in [ic].

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

module Reader = Reader

(** {2 Writing} *)

val write : Bytream.Out.t -> File_entry.with_string_content list -> unit
(** [write out_stream entries] writes the file entries to [out_stream],
    including a trailer entry at the end. *)

val to_string : File_entry.with_string_content list -> string
(** [to_string entries] writes the file entries to a string and returns it. *)

val to_buffer : Buffer.t -> File_entry.with_string_content list -> unit
(** [to_buffer buf entries] writes the file entries to [buf]. *)

val to_channel : out_channel -> File_entry.with_string_content list -> unit
(** [to_channel oc entries] writes the file entries to [oc]. *)

module Writer = Writer
