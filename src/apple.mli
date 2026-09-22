open! Core

module Color : sig
  type t =
    | Red
    | Gold
  [@@deriving sexp_of, enumerate, compare]
end

type t [@@deriving sexp_of]

(** [create] takes in a [Board.t] representing the area in which an apple can be
    generated, as well as a [Snake.t], and creates an [Apple.t] such that it appears in
    the board's play area and does not overlap with the snake.

    [create] returns [None] if there are no valid positions for the apple. *)
val create : board:Board.t -> snake:Snake.t -> t option

(** [create_excluding] is [create] for any number of snakes: it avoids every position in
    [occupied]. Competitive mode uses it so the apple can't spawn inside either snake. *)
val create_excluding : board:Board.t -> occupied:Position.t list -> t option

(** [position] returns the position of the apple on the board. *)
val position : t -> Position.t

(** [color] returns the color of the apple *)
val color : t -> Color.t

(** [amount_to_grow] returns the number of squares the snake should grow by due to eating
    this apple *)
val amount_to_grow : t -> int

(** [points] returns how much eating this apple adds to the score. *)
val points : t -> int

module Exercises : sig
  val exercise05 : board:Board.t -> snake:Snake.t -> Position.t list
  val create_with_position : Position.t -> t
end
