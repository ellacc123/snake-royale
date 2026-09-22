open! Base
open! Snake_lib

let%expect_test "score changes when apple is consumed" =
  Random.init 42;
  let game = Game.create ~height:10 ~width:10 ~initial_snake_length:1 in
  let snake =
    Snake.Exercises.create_of_positions
      (Position.of_col_major_coords [ 3, 0; 2, 0; 1, 0 ])
  in
  Game.Exercises.set_snake game snake;
  let apple =
    Apple.Exercises.create_with_position Position.{ row = 0; col = 4 }
  in
  Game.Exercises.set_apple game apple;
  let score_before = Game.score game in
  Game.step game;
  let score_after = Game.score game in
  if score_before <> score_after
  then Stdio.printf "Score changed after consuming apple"
  else
    Stdio.printf
      {|Score did not change after consuming apple!

Note: it is possible for this test to fail even though your implementation works properly.
If you believe this is the case, please check in with a TA, and comment out this test to continue.|};
  [%expect {| Score changed after consuming apple |}]
;;
