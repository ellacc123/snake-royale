open! Core

type t [@@deriving sexp_of]

val create : board:Board.t -> snake:Snake.t -> apple:Apple.t -> t option

(** like [create] but allows you to pass in your own set of characters to use for the
    letters dispersed on the board. *)
val create'
  :  board:Board.t
  -> snake:Snake.t
  -> apple:Apple.t
  -> alphabet:char list
  -> t option

val board_positions : t -> Position.t list
val letters : t -> Letter.t list
val empty : t
