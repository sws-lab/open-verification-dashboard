type t =
  | PositiveAgreement
  | NegativeAgreement
  | CoverageDisagreement
  | PrecisionAsymmetry
  | Contradiction
[@@deriving show { with_path = false }, yojson]

let t_of_yojson = ProofObligation.Utils.string_t_of_yojson t_of_yojson "CrossStatus"
let yojson_of_t = ProofObligation.Utils.string_yojson_of_t yojson_of_t

let of_statuses (status1: Status.t) (status2: Status.t) =
  (* Table 1 from ECOOP 2026 paper. *)
  match status1, status2 with
  | Unreached, Unreached
  | Safe, Safe -> PositiveAgreement
  | Warning, Warning
  | Error, Error -> NegativeAgreement
  | Unreached, _
  | _, Unreached -> CoverageDisagreement
  | Warning, (Safe | Error)
  | (Safe | Error), Warning -> PrecisionAsymmetry
  | Safe, Error
  | Error, Safe -> Contradiction
