(lang dune 3.19)

(name dashboard)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name dashboard)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends (ocaml (and (>= 4.14) (< 5.0)))
  (ppx_deriving (>= 6.0.2))
  (ppx_deriving_hash (>= 0.1.2))
  (ppx_yojson_conv (>= 0.15.1))
  (fileutils (>= 0.6.4))
  (spectrum (>= 0.7.0)))
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
