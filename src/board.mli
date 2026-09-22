open! Core

(** A [Board.t] contains metadata about the size of the playing area of the game.
*)
type t [@@deriving sexp_of]

val create : height:int -> width:int -> t
val create_unlabeled : int -> int -> t

(** [height] and [width] return the board's dimensions in squares. *)
val height : t -> int

val width : t -> int

(** [in_bounds] returns whether a position is within the playing area of the board.
*)
val in_bounds : t -> Position.t -> bool

(** [all_positions] returns a list of positions representing every square in the playing
    area of the board. *)
val all_positions : t -> Position.t list

(** Functions in [Exercises] modules shouldn't be used.  They are only exposed so they
    can be tested *)
module Exercises : sig
  val exercise03a : t -> Position.t -> bool
end
