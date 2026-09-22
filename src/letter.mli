open! Core

module Color : sig
  type t = White [@@deriving compare, enumerate, sexp_of]
end

type t [@@deriving sexp_of]

val create : position:Position.t -> char:char -> t
val position : t -> Position.t
val char : t -> char
val color : t -> Color.t
