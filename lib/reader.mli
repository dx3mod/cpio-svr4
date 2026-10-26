type t

val make : Bytream.In.t -> t
val read_entry : t -> string File_entry.t
val read_entry_without_content : t -> unit File_entry.t
val read_entries : t -> string File_entry.t list
val read_entries_seq : t -> string File_entry.t Seq.t
val read_entry_with : t -> (int option -> int32 -> 'a) -> 'a File_entry.t

val read_entries_with :
  t -> (int option -> int32 -> 'a) -> ('a File_entry.t -> unit) -> unit
