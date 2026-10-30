# cpio-svr4

A library for reading and writing [CPIO] (SVR4) archives, written in OCaml.

**Features**

- Complete SVR4 support: handles both `newc` and `crc` formats, including all file entry types and CRC-32 checksum verification.
- Type-safe representation: polymorphic file entries supporting buffered and unbuffered content types.
- Incremental reading and writing without full in-memory buffering, powered by the [Bytream] library.
- Low GC pressure: parsing uses fixed-size, reusable scratch buffers. Memory allocation is bounded by the actual data processed, not by declared (and potentially malicious) file sizes.

## Quick start

You can install the library using the [OPAM] package manager. And if you are using [Dune], add `cpio-svr4` to the `(libraries ...)` stanza in your `dune` file.

### Usage

The library provides both convenience functions for simple tasks and incremental `Reader`/`Writer` modules for memory-efficient streaming of large archives.

For small archives or quick scripts, you can read the entire archive into a list of entries at once:

```ocaml
let print_filenames ic =
  Cpio_svr4.of_channel ic
  |> List.iter @@ fun entry -> 
      print_endline entry.Cpio_svr4.File_entry.path
```

But for large archives, use the `Reader` module to process entries one by one without loading all contents into memory:

```ocaml
let in_stream = Bytream.In.of_channel ic in
let reader = Cpio_svr4.Reader.make in_stream in

(* Iterate over headers without buffering the file contents *)
Cpio_svr4.Reader.iter_with
  (fun ~content_length file_entry ->
     Printf.printf "Found: %s (%d bytes)\n" file_entry.path content_length)
  reader
```
*Note: To actually read the content incrementally, use `Reader.read_entry_with` and consume the bytes from the stream inside the callback.*

Besides reading, you can also create an archive from a list of entries already in memory:

```ocaml
let hello_txt =
  Cpio_svr4.File_entry.
    {
      path = "hello.txt";
      kind = `Regular;
      content = "Hello, World!\n";
      checksum = None;
      metadata =
        {
          owner = { user_id = 1000; group_id = 1000 };
          permission = 0o644;
          modification_time = 0l;
          device = { major = 0; minor = 0 };
          special_device = None;
          inode = { inode = 1l; hard_link_count = 1 };
        };
    }

let () = Cpio_svr4.to_channel stdout [ hello_txt ]
```

Also for writing large files without holding their content in memory, use `Writer.write_entry_with`:

```ocaml
(* Write the file entry header and stream its content directly to the
   outgoing byte stream. *)
Writer.write_entry_with ~content_length writer file_entry @@ fun out_stream ->
  (* Stream the file content to the output sink. *)
  ()

(* Finalize the archive. *)
Writer.write_trailer writer
```

## References

- [cpio(5) man page](https://manpages.ubuntu.com/manpages/jammy/en/man5/cpio.5.html)
- [CPIO format specification (libyal)](https://github.com/libyal/dtformats/blob/main/documentation/Copy%20in%20and%20out%20(CPIO)%20archive%20format.asciidoc)

**Related works**

- [ocaml-cpio](https://opam.ocaml.org/packages/cpio/): an older CPIO archive reader/written in pure OCaml. In contrast to `cpio-svr4`, it relies on the `bytesrw` library for I/O abstractions and tends to have higher memory usage, which increases GC pressure when processing large archives.

## License

The project is licensed under [the MIT License](./LICENSE). 
Feel free to use it without fear. We are always open to issues and pull requests!

[Bytream]: https://github.com/dx3mod/bytream
[CPIO]: https://en.wikipedia.org/wiki/Cpio
[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build