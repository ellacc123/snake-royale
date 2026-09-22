open! Core

type t =
  | Left
  | Up
  | Right
  | Down
[@@deriving sexp_of]

(** [next_position] takes a direction and a starting position and returns the
    next position after taking one step in the specified direction. *)
val next_position : t -> Position.t -> Position.t

(** [opposite] returns the direction facing the other way. *)
val opposite : t -> t

val of_key : Char.t -> t option

(** [of_player2_key] is [of_key] for the second player in competitive mode, mapping
    'i'/'j'/'k'/'l' to Up/Left/Down/Right. *)
val of_player2_key : Char.t -> t option

module Exercises : sig
  val exercise02a : Char.t -> t option
end
