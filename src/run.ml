open! Core

(* This is the core logic that actually runs the game. We have implemented all of this for
   you, but feel free to read this file as a reference. *)
let every seconds ~f ~stop =
  let open Async in
  let rec loop () =
    if !stop
    then return ()
    else
      Clock.after (Time_float.Span.of_sec seconds)
      >>= fun () ->
      f ();
      loop ()
  in
  don't_wait_for (loop ())
;;

let handle_keys (game : Game.t) ~quit =
  every ~stop:quit 0.001 ~f:(fun () ->
    match Snake_graphics.read_key () with
    | None -> ()
    | Some 'q' ->
      quit := true;
      Stdlib.exit 0
    | Some key ->
      Game.handle_key game key;
      Snake_graphics.render game)
;;

let handle_steps (game : Game.t) ~quit =
  (* The argument of 0.1 passed to [every] means that every 0.1 seconds, we will call
     [Game.step] and re-render the game. Changing this timespan will allow us to change
     the speed of the game. *)
  every ~stop:quit 0.1 ~f:(fun () ->
    match Game.game_state game with
    (* A finished game no longer steps, but the loop stays alive so that pressing 'r'
       (handled in [Game.handle_key]) can start a new one. *)
    | Game_over _ | Win | Player_wins _ -> ()
    | In_progress ->
      Game.step game;
      Snake_graphics.render game)
;;

let run ?(players = 1) () =
  let game = Snake_graphics.init_exn ~players () in
  Snake_graphics.render game;
  (* [quit] stops both loops. Unlike before, finishing a game doesn't set it: only
     pressing 'q' does, since a game over is now recoverable. *)
  let quit = ref false in
  handle_keys game ~quit;
  handle_steps game ~quit
;;
