open! Core

(** A [t] represents the entire game state, including the current snake, apple,
    and game state. *)
type t [@@deriving sexp_of]

(** Used for pretty-printing game contents for tests. *)
val to_string : t -> string

(** [create] creates a new single-player game with specified parameters. *)
val create : height:int -> width:int -> initial_snake_length:int -> t

(** [create_competitive] is [create] with a second player, whose snake starts in the
    opposite corner facing back towards player one. *)
val create_competitive
  :  height:int
  -> width:int
  -> initial_snake_length:int
  -> t

(** [snake] returns the snake that is currently in the game. In competitive mode this is
    player one's snake. *)
val snake : t -> Snake.t

(** [snake2] returns player two's snake, or [None] in a single-player game. *)
val snake2 : t -> Snake.t option

(** [score2] returns player two's score, or [None] in a single-player game. *)
val score2 : t -> int option

(** [is_competitive] reports whether the game has a second player. *)
val is_competitive : t -> bool

(** [handle_key] is called whenever the user presses a key. It takes that key and
    updates the game accordingly.

    This is the shared-keyboard mapping: 'w'/'a'/'s'/'d' steer player one and
    'i'/'j'/'k'/'l' steer player two. *)
val handle_key : t -> char -> unit

(** [handle_key_for_player] applies the 'w'/'a'/'s'/'d' mapping to a named player. Network
    play uses it because each player presses those keys at their own keyboard, and the
    server, not the keystroke, decides which snake they drive. *)
val handle_key_for_player : t -> player:int -> char -> unit

(** [declare_winner] ends the game outside the normal rules, for a forfeit. *)
val declare_winner : t -> player:int -> reason:string -> unit

(** [apple] returns the apple that is currently in the game. *)
val apple : t -> Apple.t

(** [board] returns the board the game is being played on. *)
val board : t -> Board.t

(** [game_state] returns the state of the current game. *)
val game_state : t -> Game_state.t

(** [step] is called in a loop, and the game is re-rendered after each call.
*)
val step : t -> unit

(** [score] returns the game's current score *)
val score : t -> int

(** [restart] resets the game to its starting state, keeping the same board. It is also
    reachable in-game by pressing 'r'. *)
val restart : t -> unit

(** [spelled_words] includes all valid words the player has spelled so far in the Spelling
    Game extension *)
val spelled_words : t -> string list

(** Functions in [Exercises] modules shouldn't be used.  They are only exposed so they
    can be tested *)
module Exercises : sig
  val exercise02b : t -> char -> unit
  val exercise03b : t -> Snake.t -> Game_state.t
  val exercise04b : t -> Snake.t -> Snake.t * Game_state.t
  val exercise06b : t -> unit
  val set_snake : t -> Snake.t -> unit
  val set_apple : t -> Apple.t -> unit
end
