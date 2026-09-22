open! Base
open! Snake_lib

let%expect_test "Exercise 06c2" =
  let snake = Snake.create ~length:5 in
  Snake.set_direction snake Direction.Up;
  let step_once () =
    let result = Snake.Exercises.exercise06c2 snake in
    Stdio.printf !"Snake valid? %b\n%{Snake}\n%!" result snake
  in
  Snake.grow_over_next_steps snake 2;
  step_once ();
  [%expect
    {|
    Snake valid? true
    Head position: 4, 1
    Tail positions: [ 0, 0; 1, 0; 2, 0; 3, 0; 4, 0 ]
    Direction: Up
    Extensions remaining: 1
    |}];
  step_once ();
  [%expect
    {|
    Snake valid? true
    Head position: 4, 2
    Tail positions: [ 0, 0; 1, 0; 2, 0; 3, 0; 4, 0; 4, 1 ]
    Direction: Up
    Extensions remaining: 0
    |}];
  step_once ();
  [%expect
    {|
    Snake valid? true
    Head position: 4, 3
    Tail positions: [ 1, 0; 2, 0; 3, 0; 4, 0; 4, 1; 4, 2 ]
    Direction: Up
    Extensions remaining: 0
    |}]
;;
