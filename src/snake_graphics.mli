open! Core

(** This module handles the graphics for the game. We have implemented this for
    you so you don't need to change anything here, but feel free to look around
    and once you have the game, feel free to alter this file to make things
    fancier! *)

(** [init_exn] fails if called twice. [players] is 1 (the default) for the classic game
    or 2 for competitive mode. *)
val init_exn : ?players:int -> unit -> Game.t

(** [render] renders the entire playing area along with snakes and apples. *)
val render : Game.t -> unit

(** [read_key] returns a keyboard input, if it's available. *)
val read_key : unit -> char option
