(** A library for reading and writing CPIO (SVR4) archives, written in pure
    OCaml. *)

module File_entry = File_entry

(** {2 Archive reading} *)

(** {3 From incoming byte stream} *)

val read : Bytream.In.t -> File_entry.with_string_content list
(** [read in_stream] reads a CPIO (SVR4) archive from the incoming byte stream
    and returns the file entries.

    @raise Error.Error If reading fails.
    @raise End_of_file
      If the incoming byte stream ends before the reader reads the trailer file
      entry. *)

(** {3 From pre-allocated buffers or channels} *)

val of_bigstring : Bstr.t -> File_entry.with_string_content list
(** [of_bigstring bs] reads a CPIO (SVR4) archive from the bigstring [bs].

    @raise Error.Error If reading fails.
    @raise End_of_file *)

val of_channel : in_channel -> File_entry.with_string_content list
(** [of_channel oc] reads a CPIO (SVR4) archive from the channel [oc].

    @raise Error.Error If reading fails.
    @raise End_of_file *)

(** {3 Via manual control} *)

module Reader = Reader

(** {2 Archive writing} *)

(** {3 To outgoing byte stream} *)

val write : Bytream.Out.t -> File_entry.with_string_content list -> unit
(** [write out_stream entries] writes the file entries to the [out_stream],
    including a trailer entry at the end. *)

(** {3 To pre-allocated buffers, strings, or channels} *)

val to_string : File_entry.with_string_content list -> string
(** [to_string entries] writes the file entries to a string and returns it. *)

val to_buffer : Buffer.t -> File_entry.with_string_content list -> unit
(** [to_buffer buf entries] writes the file entries to the buffer [buf]. *)

val to_channel : out_channel -> File_entry.with_string_content list -> unit
(** [to_channel oc entries] writes the file entries to the channel [oc]. *)

(** {3 Via manual control} *)

module Writer = Writer
