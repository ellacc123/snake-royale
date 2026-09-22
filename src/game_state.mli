open! Core

(** A [t] represents the current state of the game. *)
type t =
  | In_progress
  | Game_over of string (* The string is the reason the game ended. *)
  | Win
  | Player_wins of int * string
  (* Competitive mode only: which player won, and why the other one lost. A game that
     ends with both snakes dying is a [Game_over] rather than a win for either. *)
[@@deriving sexp_of, compare]

(** [to_string] pretty-prints the current game state into a string. *)
val to_string : t -> string
