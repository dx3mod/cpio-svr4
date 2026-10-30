(** A library for reading and writing CPIO (SVR4) archives. *)

module File_entry = File_entry

(** {1 Reading archives} *)

(** {2 Buffered reading}

    These functions read the whole archive into memory and return its entries,
    excluding the trailer. Only the first archive is consumed when several
    archives are concatenated in the input. *)

module Reader = Reader

val read : Bytream.In.t -> File_entry.with_string_content list
(** [read in_stream] reads all file entries from the archive in [in_stream], up
    to and excluding the trailer entry.

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the stream ends prematurely or the trailer is missing.
*)

val of_bigstring : Bstr.t -> File_entry.with_string_content list
(** [of_bigstring bs] reads all file entries from the archive held in [bs], up
    to and excluding the trailer entry.

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

val of_channel : in_channel -> File_entry.with_string_content list
(** [of_channel ic] reads all file entries from the archive in [ic], up to and
    excluding the trailer entry.

    @raise Reader.Error.Error on malformed input.
    @raise End_of_file if the trailer is missing. *)

(** {2 Incremental reading}

    The {!Reader} module exposes a stateful reader that can consume entries one
    by one, in either buffered ({!Reader.read_entry}) or unbuffered
    ({!Reader.read_entry_with}) mode. A single reader can consume several
    concatenated archives*)

(** {1 Writing archives}

    These functions write the given file entries as a CPIO (SVR4) archive and
    append the trailer entry automatically. *)

module Writer = Writer

(** {2 To streams and sinks} *)

val write : Bytream.Out.t -> File_entry.with_string_content list -> unit
(** [write out_stream entries] writes [entries] to [out_stream], appending a
    trailer entry at the end.

    @raise Writer.Error.Error on invalid entries or output failure. *)

val to_buffer : Buffer.t -> File_entry.with_string_content list -> unit
(** [to_buffer buf entries] writes [entries] to [buf], appending a trailer entry
    at the end.

    @raise Writer.Error.Error on invalid entries. *)

val to_channel : out_channel -> File_entry.with_string_content list -> unit
(** [to_channel oc entries] writes [entries] to [oc], appending a trailer entry
    at the end.

    @raise Writer.Error.Error on invalid entries.
    @raise Sys_error if writing to [oc] fails. *)

(** {2 To strings} *)

val to_string : File_entry.with_string_content list -> string
(** [to_string entries] returns the CPIO archive containing [entries], with a
    trailer entry appended at the end.

    @raise Writer.Error.Error on invalid entries. *)

(** {2 Incremental writing}

    Use {!Writer.make} to obtain a writer state, then write entries one by one
    with {!Writer.write_entry}, and finish the archive with
    {!Writer.write_trailer}. *)
