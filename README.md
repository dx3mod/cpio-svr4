# cpio-srv4

A pure OCaml library for reading and writing CPIO (SVR4) archives.

**Features**

- Complete CPIO (SVR4) support for newc and crc, with checksum verification and all entry types;
- Streaming reading and writing via Bytream — no full-archive buffering;
- Low, predictable allocations: bounded by bytes read, not by declared sizes;

## License

The project is licensed under [the MIT License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!
