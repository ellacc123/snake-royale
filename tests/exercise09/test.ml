open! Base
open! Snake_lib

let competitive () =
  Game.create_competitive ~height:10 ~width:10 ~initial_snake_length:3
;;

let%expect_test "a competitive game starts with two snakes in opposite corners" =
  let game = competitive () in
  Stdio.printf !"player 1: %{Position}\n" (Snake.head (Game.snake game));
  let snake2 = Option.value_exn (Game.snake2 game) in
  Stdio.printf !"player 2: %{Position}\n" (Snake.head snake2);
  Stdio.printf
    !"player 2 body: %s\n"
    (Position.list_to_string (Snake.tail snake2));
  Stdio.printf !"player 2 facing: %{sexp: Direction.t}\n" (Snake.direction snake2);
  [%expect
    {|
    player 1: 2, 0
    player 2: 7, 9
    player 2 body: [ 9, 9; 8, 9 ]
    player 2 facing: Left
    |}]
;;

let%expect_test "a single-player game has no second snake" =
  let game = Game.create ~height:10 ~width:10 ~initial_snake_length:3 in
  Stdio.printf
    "competitive: %b, snake2: %b\n"
    (Game.is_competitive game)
    (Option.is_some (Game.snake2 game));
  [%expect {| competitive: false, snake2: false |}]
;;

let%expect_test "'ijkl' steer player two and leave player one alone" =
  let game = competitive () in
  let directions () =
    ( Snake.direction (Game.snake game)
    , Snake.direction (Option.value_exn (Game.snake2 game)) )
  in
  Stdio.printf !"start:      %{sexp: Direction.t * Direction.t}\n" (directions ());
  Game.handle_key game 'i';
  Stdio.printf !"after 'i':  %{sexp: Direction.t * Direction.t}\n" (directions ());
  Game.handle_key game 'w';
  Stdio.printf !"after 'w':  %{sexp: Direction.t * Direction.t}\n" (directions ());
  Game.handle_key game 'k';
  Stdio.printf !"after 'k':  %{sexp: Direction.t * Direction.t}\n" (directions ());
  [%expect
    {|
    start:      (Right Left)
    after 'i':  (Right Up)
    after 'w':  (Up Up)
    after 'k':  (Up Down)
    |}]
;;

let%expect_test "player two's keys do nothing in a single-player game" =
  let game = Game.create ~height:10 ~width:10 ~initial_snake_length:3 in
  Game.handle_key game 'i';
  Stdio.printf !"%{sexp: Direction.t}\n" (Snake.direction (Game.snake game));
  [%expect {| Right |}]
;;

(* Drive player one into a wall: player two should be declared the winner. *)
let%expect_test "running out of bounds loses the game for that player" =
  let game = competitive () in
  (* Player one starts at the left edge facing right, so send it left instead. *)
  Game.handle_key game 'a';
  Game.step game;
  Game.step game;
  Game.step game;
  Stdio.printf !"%{sexp: Game_state.t}\n" (Game.game_state game);
  [%expect {| (Player_wins 2 "player 1 went out of bounds") |}]
;;

let%expect_test "restarting a competitive game keeps both players" =
  let game = competitive () in
  Game.handle_key game 'a';
  Game.step game;
  Game.step game;
  Game.step game;
  Game.handle_key game 'r';
  Stdio.printf
    !"state: %{sexp: Game_state.t}, competitive: %b, scores: %{sexp: int * int option}\n"
    (Game.game_state game)
    (Game.is_competitive game)
    (Game.score game, Game.score2 game);
  [%expect {| state: In_progress, competitive: true, scores: (0 (0)) |}]
;;

(* Both snakes are aimed at the same square, so neither should be declared the winner. *)
let%expect_test "a head-on collision is a draw" =
  let game = competitive () in
  let snake1 =
    Snake.Exercises.create_of_positions
      (Position.of_col_major_coords [ 4, 5; 3, 5; 2, 5 ])
  in
  Game.Exercises.set_snake game snake1;
  let snake2 = Option.value_exn (Game.snake2 game) in
  Snake.Exercises.set_head snake2 { Position.col = 6; row = 5 };
  Snake.Exercises.set_tail snake2 (Position.of_col_major_coords [ 8, 5; 7, 5 ]);
  Snake.set_direction snake2 Left;
  Game.step game;
  Stdio.printf !"%{sexp: Game_state.t}\n" (Game.game_state game);
  [%expect
    {|
    (Game_over
     "draw - player 1 ran into the other snake, player 2 ran into the other snake")
    |}]
;;
