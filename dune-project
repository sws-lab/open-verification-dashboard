(lang dune 3.19)

(name open-verification-dashboard)

(generate_opam_files true)

(source (github sws-lab/open-verification-dashboard))
(authors "Tom Goalard")
(maintainers "Simmo Saan <simmo.saan@gmail.com>")
(license MIT)

(package
 (name open-verification-dashboard)
 (synopsis "Dashboard for Tracking Verification Progress")
 (depends
  (ocaml (and (>= 4.14) (< 5.0)))
  (ppx_deriving (>= 6.0.2))
  (ppx_deriving_hash (>= 0.1.2))
  (ppx_yojson_conv (>= 0.15.1))
  (spectrum (>= 0.7.0))))
