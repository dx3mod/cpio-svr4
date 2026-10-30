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
