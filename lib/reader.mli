(** CPIO (SVR4) archive reader. *)

type t
(** The type of reader state. *)

val make : Bytream.In.t -> t
(** [make in_stream] creates a new reader state. *)

(** {2 Reading file entries with string content} *)

val read_entry : t -> File_entry.with_string_content
(** [read_entry reader] reads a file entry with string content from the
    [reader].

    @raise Error If reading fails.
    @raise End_of_file
      If the incoming byte stream ends before the reader reads the trailer file
      entry. *)

val read_entries : t -> File_entry.with_string_content list
(** [read_entries reader] reads file entries with string contents from the
    [reader].

    @raise Error If reading fails.
    @raise End_of_file *)

val fold : ('acc -> File_entry.with_string_content -> 'acc) -> 'acc -> t -> 'acc
(** [fold f acc reader] folds over file entries read from the [reader].

    @raise Error If reading fails.
    @raise End_of_file *)

val iter : (File_entry.with_string_content -> unit) -> t -> unit
(** [iter f reader] iterates over file entries read from the [reader].

    @raise Error If reading fails.
    @raise End_of_file *)

(** {2 Manual content reading} *)

val read_entry_with :
  t -> (content_length:int -> File_entry.without_content -> 'a) -> 'a
(** [read_entry_with reader f] reads a file entry using manual content reading
    from the [reader].

    The remaining unread file content is automatically skipped. If the number of
    bytes read exceeds the file's content length, an exception will be raised.

    @raise Error If reading fails.
    @raise End_of_file *)

val fold_with :
  (content_length:int -> 'acc -> File_entry.without_content -> 'acc) ->
  'acc ->
  t ->
  'acc
(** [fold_with f acc reader] folds over file entries using manual content
    reading from the [reader].

    @raise Error If reading fails.
    @raise End_of_file *)

val iter_with :
  (content_length:int -> File_entry.without_content -> unit) -> t -> unit
(** [iter_with f reader] iterates over file entries using manual content reading
    from the [reader].

    @raise Error If reading fails.
    @raise End_of_file *)

(** {2 Errors} *)

module Error : sig
  type t =
    | Invalid_magic_code
    | Illegal_special_device
    | Checksum_mismatched
    | Too_much_read_content
    | Invalid_path_name

  exception Error of t * string
end
