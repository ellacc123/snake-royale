open! Base
open! Snake_lib

let game = Game.create ~height:10 ~width:10 ~initial_snake_length:3

let%expect_test "Exercise 02b" =
  let test key =
    Game.Exercises.exercise02b game key;
    let direction = Snake.direction (Game.snake game) in
    Stdio.printf
      !"%c pressed. Snake facing: %{sexp: Direction.t}"
      key
      direction
  in
  test 'w';
  [%expect {| w pressed. Snake facing: Up |}];
  test 'a';
  [%expect {| a pressed. Snake facing: Left |}];
  test 's';
  [%expect {| s pressed. Snake facing: Down |}];
  test 'd';
  [%expect {| d pressed. Snake facing: Right |}];
  test 'q';
  [%expect {| q pressed. Snake facing: Right |}];
  test 'e';
  [%expect {| e pressed. Snake facing: Right |}];
  test 'r';
  [%expect {| r pressed. Snake facing: Right |}]
;;
