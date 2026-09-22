open! Base
open! Snake_lib

let%expect_test "Exercise 04b" =
  let game = Game.create ~height:10 ~width:10 ~initial_snake_length:3 in
  let test ~direction positions =
    let snake =
      Snake.Exercises.create_of_positions
        (Position.of_col_major_coords positions)
    in
    Snake.set_direction snake direction;
    let snake, game_state = Game.Exercises.exercise04b game snake in
    Stdio.printf
      !{|Game state: %{sexp: Game_state.t}
Snake:
%s
|}
      game_state
      (Snake.to_string ~indent:2 snake)
  in
  test [ 0, 1; 0, 2; 0, 3 ] ~direction:Direction.Right;
  [%expect
    {|
    Game state: In_progress
    Snake:
      Head position: 1, 1
      Tail positions: [ 0, 2; 0, 1 ]
      Direction: Right
      Extensions remaining: 0
    |}];
  test [ 0, 1; 0, 2; 0, 3 ] ~direction:Direction.Left;
  [%expect
    {|
    Game state: (Game_over "Out of bounds!")
    Snake:
      Head position: -1, 1
      Tail positions: [ 0, 2; 0, 1 ]
      Direction: Left
      Extensions remaining: 0
    |}];
  test [ 0, 1; 0, 2; 0, 3 ] ~direction:Direction.Up;
  [%expect
    {|
    Game state: (Game_over "Self collision!")
    Snake:
      Head position: 0, 2
      Tail positions: [ 0, 2; 0, 1 ]
      Direction: Up
      Extensions remaining: 0
    |}];
  test [ 0, 1; 0, 2; 0, 3 ] ~direction:Direction.Down;
  [%expect
    {|
    Game state: In_progress
    Snake:
      Head position: 0, 0
      Tail positions: [ 0, 2; 0, 1 ]
      Direction: Down
      Extensions remaining: 0
    |}]
;;
