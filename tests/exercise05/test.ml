open! Base
open! Snake_lib

let height = 10
let width = 10

let test positions =
  let board = Board.create ~height ~width in
  let positions =
    List.map positions ~f:(fun (row, col) -> Position.{ row; col })
  in
  let snake = Snake.Exercises.create_of_positions positions in
  Stdio.printf
    !"%{sexp: Position.t list}\n%!"
    (List.sort
       ~compare:Position.compare
       (Apple.Exercises.exercise05 ~board ~snake))
;;

let%expect_test "simple" =
  test [ 0, 1; 0, 2; 0, 3 ];
  [%expect
    {|
    (((col 0) (row 0)) ((col 0) (row 1)) ((col 0) (row 2)) ((col 0) (row 3))
     ((col 0) (row 4)) ((col 0) (row 5)) ((col 0) (row 6)) ((col 0) (row 7))
     ((col 0) (row 8)) ((col 0) (row 9)) ((col 1) (row 1)) ((col 1) (row 2))
     ((col 1) (row 3)) ((col 1) (row 4)) ((col 1) (row 5)) ((col 1) (row 6))
     ((col 1) (row 7)) ((col 1) (row 8)) ((col 1) (row 9)) ((col 2) (row 1))
     ((col 2) (row 2)) ((col 2) (row 3)) ((col 2) (row 4)) ((col 2) (row 5))
     ((col 2) (row 6)) ((col 2) (row 7)) ((col 2) (row 8)) ((col 2) (row 9))
     ((col 3) (row 1)) ((col 3) (row 2)) ((col 3) (row 3)) ((col 3) (row 4))
     ((col 3) (row 5)) ((col 3) (row 6)) ((col 3) (row 7)) ((col 3) (row 8))
     ((col 3) (row 9)) ((col 4) (row 0)) ((col 4) (row 1)) ((col 4) (row 2))
     ((col 4) (row 3)) ((col 4) (row 4)) ((col 4) (row 5)) ((col 4) (row 6))
     ((col 4) (row 7)) ((col 4) (row 8)) ((col 4) (row 9)) ((col 5) (row 0))
     ((col 5) (row 1)) ((col 5) (row 2)) ((col 5) (row 3)) ((col 5) (row 4))
     ((col 5) (row 5)) ((col 5) (row 6)) ((col 5) (row 7)) ((col 5) (row 8))
     ((col 5) (row 9)) ((col 6) (row 0)) ((col 6) (row 1)) ((col 6) (row 2))
     ((col 6) (row 3)) ((col 6) (row 4)) ((col 6) (row 5)) ((col 6) (row 6))
     ((col 6) (row 7)) ((col 6) (row 8)) ((col 6) (row 9)) ((col 7) (row 0))
     ((col 7) (row 1)) ((col 7) (row 2)) ((col 7) (row 3)) ((col 7) (row 4))
     ((col 7) (row 5)) ((col 7) (row 6)) ((col 7) (row 7)) ((col 7) (row 8))
     ((col 7) (row 9)) ((col 8) (row 0)) ((col 8) (row 1)) ((col 8) (row 2))
     ((col 8) (row 3)) ((col 8) (row 4)) ((col 8) (row 5)) ((col 8) (row 6))
     ((col 8) (row 7)) ((col 8) (row 8)) ((col 8) (row 9)) ((col 9) (row 0))
     ((col 9) (row 1)) ((col 9) (row 2)) ((col 9) (row 3)) ((col 9) (row 4))
     ((col 9) (row 5)) ((col 9) (row 6)) ((col 9) (row 7)) ((col 9) (row 8))
     ((col 9) (row 9)))
    |}]
;;

let%expect_test "only one valid position" =
  let positions =
    List.cartesian_product (List.range 0 height) (List.range 0 width)
  in
  let snake_positions =
    List.filter positions ~f:(fun square ->
      not ([%compare.equal: int * int] (4, 5) square))
  in
  test snake_positions;
  [%expect {| (((col 5) (row 4))) |}]
;;

let%expect_test "no valid positions" =
  let snake_positions =
    List.cartesian_product (List.range 0 height) (List.range 0 width)
  in
  test snake_positions;
  [%expect {| () |}]
;;
