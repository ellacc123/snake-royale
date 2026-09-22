open! Base
open! Snake_lib

let%expect_test "Exercise 06a" =
  let test snake how_much =
    Snake.Exercises.exercise06a snake how_much;
    Stdio.printf !"%{Snake}\n%!" snake
  in
  let snake = Snake.create ~length:5 in
  test snake 2;
  [%expect
    {|
    Head position: 4, 0
    Tail positions: [ 0, 0; 1, 0; 2, 0; 3, 0 ]
    Direction: Right
    Extensions remaining: 2
    |}];
  test snake 3;
  [%expect
    {|
    Head position: 4, 0
    Tail positions: [ 0, 0; 1, 0; 2, 0; 3, 0 ]
    Direction: Right
    Extensions remaining: 5
    |}]
;;
