open! Base
open! Snake_lib

let%expect_test "Exercise 06c" =
  let snake = Snake.create ~length:5 in
  Snake.set_direction snake Direction.Up;
  let move_forward_and_grow_once () =
    let head, tail = Snake.Exercises.exercise06c snake in
    Stdio.printf
      !"Head: %{Position}\nTail: %s\n%!"
      head
      (Position.list_to_string tail);
    Snake.Exercises.set_head snake head;
    Snake.Exercises.set_tail snake tail;
    ()
  in
  Snake.grow_over_next_steps snake 2;
  move_forward_and_grow_once ();
  [%expect
    {|
    Head: 4, 1
    Tail: [ 0, 0; 1, 0; 2, 0; 3, 0; 4, 0 ]
    |}];
  move_forward_and_grow_once ();
  [%expect
    {|
    Head: 4, 2
    Tail: [ 0, 0; 1, 0; 2, 0; 3, 0; 4, 0; 4, 1 ]
    |}];
  move_forward_and_grow_once ();
  [%expect
    {|
    Head: 4, 3
    Tail: [ 1, 0; 2, 0; 3, 0; 4, 0; 4, 1; 4, 2 ]
    |}]
;;
