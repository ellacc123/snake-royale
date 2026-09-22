open! Base
open! Snake_lib

let%expect_test "Exercise 04a" =
  let test positions ~expect =
    let positions = Position.of_col_major_coords positions in
    let snake = Snake.Exercises.create_of_positions positions in
    let result = Snake.Exercises.exercise04a snake in
    if Bool.(result = expect)
    then ()
    else
      Stdio.printf
        "Error in test of self collision! Expected %b but got %b.\n%!"
        expect
        result
  in
  test [ 0, 1; 0, 2; 0, 3; 0, 4 ] ~expect:false;
  [%expect {| |}];
  test [ 0, 1; 0, 1; 0, 2; 0, 3 ] ~expect:true;
  [%expect {| |}];
  test [ 1, 1; 0, 1; 0, 0; 1, 0; 1, 1 ] ~expect:true;
  [%expect {| |}];
  test
    [ 1, 4; 1, 3; 1, 2; 1, 1; 0, 1; 0, 2; 0, 3; 0, 4; 0, 5; 0, 6; 0, 7 ]
    ~expect:false;
  [%expect {| |}];
  test
    [ 0, 3; 1, 3; 1, 2; 1, 1; 0, 1; 0, 2; 0, 3; 0, 4; 0, 5; 0, 6; 0, 7 ]
    ~expect:true;
  [%expect {| |}]
;;
