open! Core
open! Snake_lib

(* Pass -2p (or --two-player) to start in competitive mode:

   $ dune exec bin/snake.exe -- -2p *)
let () =
  let two_player =
    Sys.get_argv ()
    |> Array.exists ~f:(fun arg ->
      String.equal arg "-2p" || String.equal arg "--two-player")
  in
  Run.run ~players:(if two_player then 2 else 1) ();
  Core.never_returns (Async.Scheduler.go ())
;;
