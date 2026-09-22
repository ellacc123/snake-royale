open! Base
open! Snake_lib

let%expect_test "more than one color" =
  if List.length Apple.Color.all > 1
  then Stdio.printf "There are multiple colors implemented!"
  else
    Stdio.printf
      "There seems to only be one color implemented. Please check your \
       exercise 7 implementation. If you need help debugging, feel free to \
       ask a TA for help.";
  [%expect {| There are multiple colors implemented! |}]
;;

let%expect_test "test that we eventually generate apples of all colors" =
  (* Run test with two differently-sized boards, in case implementation of color
     generation depends on score or such. *)
  let board1 = Board.create ~height:10 ~width:10 in
  let board2 = Board.create ~height:11 ~width:11 in
  let snake =
    Snake.Exercises.create_of_positions
      (List.map
         [ 0, 1; 0, 2; 0, 3 ]
         ~f:(fun (row, col) -> Position.{ row; col }))
  in
  let generated_colors =
    List.init 10_000 ~f:(fun i ->
      (if i % 2 = 0
       then Apple.create ~board:board1 ~snake
       else Apple.create ~board:board2 ~snake)
      |> Option.value_exn
      |> Apple.color)
    |> List.dedup_and_sort ~compare:Apple.Color.compare
  in
  let colors_not_generated =
    List.filter Apple.Color.all ~f:(fun color ->
      not
        (List.mem
           generated_colors
           color
           ~equal:[%compare.equal: Apple.Color.t]))
  in
  if List.is_empty colors_not_generated
  then Stdio.printf "All colors are generated!"
  else
    Stdio.printf
      !{|Not all colors were generated! Please check that your implementation will generate apples of
all colors, and that the [color] function in apple.ml is properly implemented. Here are
the colors that were not generated:

      %{sexp: Apple.Color.t list}

Note: it is possible for this test to fail even though your implementation works properly.
If you believe this is the case, please check in with a TA, and comment out this test to continue.|}
      colors_not_generated;
  [%expect {| All colors are generated! |}]
;;
