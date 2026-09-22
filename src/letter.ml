open! Core

module Color = struct
  type t = White [@@deriving compare, enumerate, sexp_of]
end

type t =
  { position : Position.t
  ; char : char
  }
[@@deriving sexp_of]

let position t = t.position
let char t = t.char

let color t =
  ignore t;
  Color.White
;;

let create ~position ~char = { position; char }
