open! Core

(** [run] starts the game. [players] is 1 (the default) for the classic game, or 2 for
    competitive mode, where player two steers with 'i', 'j', 'k' and 'l'. *)
val run : ?players:int -> unit -> unit
