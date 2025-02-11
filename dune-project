(lang dune 3.17)

(name minichat)

(generate_opam_files true)

(source
 (github jalsol/minichat))

(authors "Nguyen Quang Truong <nqtruong.1002@gmail.com>")

(maintainers "Nguyen Quang Truong <nqtruong.1002@gmail.com>")

(license Unlicense)

(package
 (name minichat)
 (synopsis "Minichat")
 (description "A mini-chat application in OCaml")
 (depends ocaml lwt logs))

