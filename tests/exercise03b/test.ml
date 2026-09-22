open! Base
open! Snake_lib

let%expect_test "Exercise 03b" =
  let game = Game.create ~height:10 ~width:15 ~initial_snake_length:3 in
  let test snake_positions expectation =
    let positions =
      List.map snake_positions ~f:(fun (row, col) -> { Position.row; col })
    in
    let snake = Snake.Exercises.create_of_positions positions in
    let game_state = Game.Exercises.exercise03b game snake in
    if [%compare.equal: Game_state.t] game_state expectation
    then ()
    else
      Stdio.printf
        !"Expected %{sexp: Game_state.t}, but got %{sexp: Game_state.t}"
        expectation
        game_state
  in
  test [ 0, 0 ] In_progress;
  [%expect {| |}];
  test [ -1, 0 ] (Game_over "Out of bounds!");
  [%expect {| |}];
  test [ 0, -1 ] (Game_over "Out of bounds!");
  [%expect {| |}];
  test [ 0, 14 ] In_progress;
  [%expect {| |}];
  test [ 0, 15 ] (Game_over "Out of bounds!");
  [%expect {| |}];
  test [ 9, 0 ] In_progress;
  [%expect {| |}];
  test [ 10, 0 ] (Game_over "Out of bounds!");
  [%expect {| |}];
  test [ 9, 14 ] In_progress;
  [%expect {| |}];
  test [ 9, 15 ] (Game_over "Out of bounds!");
  [%expect {| |}];
  test [ 10, 14 ] (Game_over "Out of bounds!");
  [%expect {| |}]
;;
