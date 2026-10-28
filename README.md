# cpio-srv4

A pure OCaml library for reading and writing [CPIO] (SVR4) archives.

**Features**

- Complete CPIO (SVR4) support, with checksum verification and all entry types;
- Type-safe file entry representation;
- Streaming reading and writing via [Bytream] (i.e. no full buffering);
- Low, predictable memory allocations: bounded by bytes read, not by declared sizes;

## Quick start

You can install `cpio-svr4` using the [OPAM] package manager or another method. If you are using [Dune], add `cpio-svr4` to your dependencies.

## In use

The `cpio-svr4` library uses the Bytream library for I/O abstraction and efficient streaming reading and writing of CPIO archives. You may use this via the provided `Reader` and `Writer` modules, and other top-level defined functions.

For example, reading a CPIO archive from an input channel and printing the filenames using top-level functions.

```ocaml
let print_filenames ic =
  Cpio_svr4.of_channel ic
  |> List.iter @@ fun Cpio_svr4.File_entry.{ path; _ } -> print_endline path
```

It's not the most effective code, but it's simple and good for one-off programs.

But if you want to make it more effective, you should use the `Reader` module and Bytream's streams directly.

```ocaml
let in_stream = Bytream.In.of_channel ic in
let reader = Cpio_svr4.Reader.make in_stream in

Cpio_svr4.Reader.iter_with
  (fun ~content_length:_ file_entry -> print_endline file_entry.path)
  reader
```

## References

- [cpio(5) man page](https://manpages.ubuntu.com/manpages/jammy/man5/cpio.5.html)
- [CPIO format specification](<https://github.com/libyal/dtformats/blob/main/documentation/Copy%20in%20and%20out%20(CPIO)%20archive%20format.asciidoc>)

**Related works**

- [ocaml-cpio](https://tangled.org/gazagnaire.org/ocaml-cpio), a CPIO archive reader and writer written in pure OCaml by [Thomas Gazagnaire](https://tangled.org/gazagnaire.org). In comparison with this library, `ocaml-cpio` uses the [Bytesrw] library for I/O abstractions and has terrible memory utilization, which increases the GC workload.

## License

The project is licensed under [the MIT License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!

[Bytream]: https://github.com/dx3mod/bytream
[CPIO]: https://en.wikipedia.org/wiki/Cpio
[Bytesrw]: https://ocaml.org/p/bytesrw/latest
[OPAM]: https://opam.ocaml.org/
[Dune]: https://dune.build
