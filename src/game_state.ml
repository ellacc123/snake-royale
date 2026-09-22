open! Core

type t =
  | In_progress
  | Game_over of string
  | Win
  | Player_wins of int * string
[@@deriving sexp_of, compare]

let to_string t =
  match t with
  | In_progress -> ""
  | Game_over x -> "Game over: " ^ x
  | Win -> "WIN!"
  | Player_wins (player, reason) ->
    Core.sprintf "Player %d wins! (%s)" player reason
;;
