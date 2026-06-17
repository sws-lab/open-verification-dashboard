open Ovd_checks

module CategoryFile =
struct
  type t = Category.t * string [@@deriving ord]
end

module CategoryFileMap =
struct
  include Map.Make (CategoryFile)

  let of_checks checks =
    List.fold_left (fun acc (check: Check.t) ->
        let category_file = (check.category, check.range.file) in
        let group = Option.value (find_opt category_file acc) ~default:[] in
        add category_file (check :: group) acc (* reverses checks *)
      ) empty checks
end


