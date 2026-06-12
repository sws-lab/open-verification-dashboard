(** This module defines the report structure and provides functions to create
    and export the final json report. *)

open Ovd_checks
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module Meta_status =
struct
  include JointMatrix

  let yojson_of_t joint_matrix =
    `Assoc [
      ("optimistic_status", [%yojson_of: Status.t option] (JointMatrix.optimistic_status joint_matrix));
      ("pessimistic_status", [%yojson_of: Status.t option] (JointMatrix.pessimistic_status joint_matrix));
      ("joint_matrix", JointMatrix.yojson_of_t joint_matrix);
      ("selectivity1", [%yojson_of: float option] (JointMatrix.selectivity1 joint_matrix));
      ("selectivity2", [%yojson_of: float option] (JointMatrix.selectivity2 joint_matrix));
      ("joint_selectivity", [%yojson_of: float option] (JointMatrix.joint_selectivity joint_matrix));
      ("alignment", [%yojson_of: float option] (JointMatrix.alignment joint_matrix));
    ]

  let t_of_yojson j =
    JointMatrix.t_of_yojson (Yojson.Safe.Util.member "joint_matrix" j)
end

include Meta_status


module Category =
struct
  include Ovd_checks.Category
  let of_string k = t_of_yojson (`String k) (* TODO: less roundabout way *)
  let of_conflict conflict = conflict.Conflict.category
end

module CategoryMap = ConflictAggregator.MakeGrouped (Category) (Meta_status)
