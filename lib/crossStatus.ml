type t =
  | PositiveAgreement
  | NegativeAgreement
  | CoverageDisagreement
  | PrecisionAsymmetry
  | Contradiction
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = ProofObligation.Utils.string_t_of_yojson t_of_yojson "CrossStatus"
let yojson_of_t = ProofObligation.Utils.string_yojson_of_t yojson_of_t
