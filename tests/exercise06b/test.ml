open! Base
open! Snake_lib

let%expect_test "Exercise 06b" =
  Random.init 42;
  let game = Game.create ~height:10 ~width:10 ~initial_snake_length:1 in
  let snake =
    Snake.Exercises.create_of_positions
      (Position.of_col_major_coords [ 1, 0; 2, 0; 3, 0 ])
  in
  Game.Exercises.set_snake game snake;
  let test (apple_col, apple_row) =
    let apple =
      Apple.Exercises.create_with_position
        Position.{ col = apple_col; row = apple_row }
    in
    Game.Exercises.set_apple game apple;
    Game.Exercises.exercise06b game;
    Stdio.printf !"%{Game}\n%!" game
  in
  test (0, 0);
  [%expect
    {|
    Game state: In_progress
    Apple: ((position ((col 0) (row 0))) (color Red))
    Board: ((height 10) (width 10))
    Score : 0
    Snake:   Head position: 1, 0
      Tail positions: [ 3, 0; 2, 0 ]
      Direction: Right
      Extensions remaining: 0
    |}];
  test (1, 0);
  [%expect
    {|
    Game state: In_progress
    Apple: ((position ((col 6) (row 9))) (color Red))
    Board: ((height 10) (width 10))
    Score : 1
    Snake:   Head position: 1, 0
      Tail positions: [ 3, 0; 2, 0 ]
      Direction: Right
      Extensions remaining: 2
    |}];
  (* Eating another apple will further increase the number of extensions. *)
  test (1, 0);
  [%expect
    {|
    Game state: In_progress
    Apple: ((position ((col 8) (row 3))) (color Red))
    Board: ((height 10) (width 10))
    Score : 2
    Snake:   Head position: 1, 0
      Tail positions: [ 3, 0; 2, 0 ]
      Direction: Right
      Extensions remaining: 4
    |}]
;;
