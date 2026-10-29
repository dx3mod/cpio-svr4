(lang dune 3.22)

(name cpio-svr4)

(generate_opam_files true)

(source
 (github dx3mod/cpio-svr4))

(authors "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Mikhail Lopatin <dx3mod@bk.ru>")

(license MIT)

(package
 (name cpio-svr4)
 (synopsis "A library for reading and writing CPIO (SVR4) archives")
 (depends
  ocaml
  (bytream
   (>= 0.4))
  (hexen
   (>= 0.2)))
 (tags
  (archive cpio streaming)))
