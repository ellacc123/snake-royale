open! Core

type t =
  { (* [direction] represents the orientation of the snake's head. *)
    mutable direction : Direction.t
  ; (* [extensions_remaining] represents how many more times we should extend the
       snake. *)
    mutable extensions_remaining : int
  ; (* [head] represents the current squares the snake head occupies. *)
    mutable head : Position.t
  ; (* [tail] represents the set of squares that the snake occupies excluding the head,
       sorted in reverse order (i.e. the first element in the list represents the tip of
       the tail) *)
    mutable tail : Position.t list
  }
[@@deriving sexp_of, fields ~getters]

let to_string ?(indent = 0) { direction; extensions_remaining; head; tail } =
  Core.sprintf
    !{|Head position: %{Position}
Tail positions: [ %s ]
Direction: %{sexp: Direction.t}
Extensions remaining: %d|}
    head
    (List.map tail ~f:Position.to_string |> String.concat ~sep:"; ")
    direction
    extensions_remaining
  |> String.split_lines
  |> List.map ~f:(fun s -> String.init indent ~f:(fun _ -> ' ') ^ s)
  |> String.concat ~sep:"\n"
;;

(** Exercise 09 generalised this: a snake can now start anywhere, facing any direction, so
    that player two can begin in the opposite corner. The defaults reproduce the original
    behaviour exactly — head at (length - 1, 0), facing right — so existing callers are
    unaffected.

    The body is laid out by walking backwards from the head, against [direction]. Since
    [tail] is stored tip-first, the position furthest from the head ends up at the front of
    the list. *)
let create_at ~head ~direction ~length =
  let behind = Direction.opposite direction in
  let rec body_behind position remaining acc =
    if remaining = 0
    then acc
    else (
      let position = Direction.next_position behind position in
      body_behind position (remaining - 1) (position :: acc))
  in
  { direction
  ; extensions_remaining = 0
  ; head
  ; tail = body_behind head (length - 1) []
  }
;;

let create ~length =
  create_at
    ~head:{ Position.row = 0; col = length - 1 }
    ~direction:Right
    ~length
;;

let head t = t.head
let all_positions t = t.head :: t.tail
let set_direction t direction = t.direction <- direction

(** Exercise 01:

    The goal of this function is to take a snake and move it forward one square.

    The signature of this function is
    {[
      val move_forward
        :  Position.t
        -> Position.t list
        -> Direction.t
        -> Position.t * Position.t list
    ]}

    A function signature describes the arguments to a function and its return type. The
    final value is the return type of the function. All values before it are arguments to
    the function. In this case they are as follows:

    The first argument, which has a type of [Position.t], represents the current head of
    the snake.

    The next argument, a [Position.t list], represents the current body of the snake. This
    is stored in reverse order, so the first element of the list is the very end of the
    snake's tail.

    The third argument, a [Direction.t], represents the direction in which the snake is
    moving.

    The thing we will return is a tuple that represent the new head of the snake along with
    the new body of the snake.

    When the snake moves forward, its head will occupy a new space, and it will vacate the
    space that the end of its tail used to take up. In order to implement this, we want to:
    1. remove the very end of the snake's tail (recall that we store the snake's body in
    reverse order),
    2. add the position of the snake's current head to the snake's body, and
    3. determine the new position of the snake's head.

    We've provided you with the following functions that will help:

    [Direction.next_position] is a function defined in direction.ml which takes a
    direction and a position, and returns the position which is one square farther in the
    given direction. (Feel free to check out the function's definition in direction.ml
    and signature in direction.mli.)

    As you may have inferred from this, we can refer to functions defined in other files by
    prepending them with the name of the file after capitalizing its first letter.

    [List.tl_exn] is a function that, given a list, returns the list with the first element
    removed. It has signature:
    {[
      List.tl_exn : 'a list -> 'a list
    ]}

    To declare a list of elements, you can use the following syntax:
    {[
      [ 1; 2; 3 ]
    ]}

    To concatenate two lists together, you can use the "@" operator. For example:
    {[
      let a = [ 1; 2; 3 ] in
      let b = [ 4; 5; 6 ] in
      a @ b
    ]}
    would construct the list [ 1; 2; 3; 4; 5; 6]

    To see if your function works, run

    $ dune runtest ./tests/exercise01

    which will run a series of tests on your function.

    If it doesn't print any output, your tests pass! If it prints output, it means your
    function's behavior differs from what is expected. The red output is what the test
    expected, and the green output is what the test printed with your function.

    Once you have this test passing, go back to the README to move on. *)

let move_forward head tail direction =
  (* We have `ignore direction` here so that the compiler does not complain that we aren't
     using the [direction] variable passed into this function. When you have finished
     implementing this function, feel free to remove `ignore direction`. *)
  
  let new_tail =
    match tail with 
    | [] -> []
    | tail -> List.tl_exn tail
  in

  let new_head = Direction.next_position direction head in

  (*add original head to list*)
  let added_to_tail = 
    new_tail @ [head] 
  in

  new_head, added_to_tail
;;

(** Exercise 04a:

    Just like we needed to check if the head of the snake went out of bounds, we also need
    to check if the snake collides with itself. [collides_with_self] should return true if
    the head of the snake overlaps with any of the rest of its body.

    Two functions that you might find handy are [List.for_all] and [List.exists].

    Here are their signatures:

    {[
      val for_all : 'a list -> f:('a -> bool) -> bool
      val exists : 'a list -> f:('a -> bool) -> bool
    ]}

    [List.for_all] takes a list and a function, [f], and applies [f] to the each of the
    list elements. If [f] returns true for *all* of them, [List.for_all] returns true,
    otherwise it returns false.

    [List.exists] takes a list and a function, [f], and applies [f] to the each of the
    list elements. If [f] returns true for *any* of them, [List.exists] returns true,
    otherwise it returns false.

    (A function like [f] that takes a single argument and returns true or false is often
    called a "predicate".)

    The syntax "f:('a -> bool)" in the signatures above is used to indicate a labeled
    argument. Labeled arguments are a handy tool for preventing mistakes. For example,
    consider this function, which appears in board.ml(i):

    {[
      val create_unlabeled : int -> int -> t

      let create_unlabeled height width = { height; width }
    ]}

    [create_unlabeled] takes two ints, and makes a board with those dimensions. You would
    call this function like so:

    {[
      create_unlabeled 10 12
    ]}

    At the call site (i.e., where the function is called), it's ambiguous which int is the
    height and which int is the width, so it's very easy to supply arguments in the wrong
    order.

    We can rewrite this function using labeled arguments:
    {[
      val create : height:int -> width:int -> t

      let create ~height ~width = { height; width }
    ]}

    To call this function, we would instead write:
    {[
      create_board ~height:10 ~width:12
    ]}

    This syntax makes it very clear which argument is intended to be which.

    You'll see that throughout the game, any function that is taking two arguments of the
    same type probably uses labelled arguments to distinguish them.

    Note that the labeled argument [f] in [List.for_all] and [List.exists] is itself is a
    function. This is pretty cool!

    In OCaml, functions are values and can be passed to other functions as arguments. You
    can also declare a function inside another function:

    {[
      let neither_is_0 x y =
        let not_zero n = not (n = 0) in
        not_zero x && not_zero y
      ;;
    ]}

    Creating "sub" functions like this allows us to simplify our code and prevent mistakes
    from copying and pasting.

    One hint before you get started: we have provided the function [Position.equal], which
    has the following signature:

    {[
      val equal : Position.t -> Position.t -> bool
    ]}

    Let's put these all together to write [collides_with_self].

    To test this function, run:

    $ dune runtest ./tests/exercise04a

    You should see no output for exercise04a. Once the test passes, proceed to exercise 04b
    in game.ml *)

let collides_with_self t =
  List.exists t.tail ~f:(fun pos -> Position.equal t.head pos)
;;

(** Exercise 06a:

    When the snake consumes an apple, we want the snake to grow over the next few time
    steps. To implement this, we store [extensions_remaining] in the snake.

    This function takes in an amount the snake should grow and increments the current value
    of [extensions_remaining] in the snake record.

    When you've implemented this, make sure the tests for exercise 06a pass:

    $ dune runtest ./tests/exercise06a

    Once the test passes, proceed to exercise 06b in game.ml. *)
let grow_over_next_steps t by_how_much =
  t.extensions_remaining <- t.extensions_remaining + by_how_much
;;

(** Exercise 06c:

    Now, let's write a modified version of [move_forward] that handles the snake growing.

    If [extensions_remaining] is greater than 0, then the snake should move forward without
    removing the end of its tail, so that its overall length increases. We should also make
    sure to update [extensions_remaining].

    Like [move_forward] we should return the new head and tail of the snake.

    At this point, running

    $ dune runtest ./tests/exercise06c

    should produce no output.

    Once you've implemented [move_forward_and_grow], let's update the [step] function below
    to use [move_forward_and_grow] rather than [move_forward].

    At this point, running

    $ dune runtest ./tests/exercise06c2

    should also produce no output.

    You should now have a complete playable game! Make sure to build and run the game to
    try it out. Once you're ready, return to README.mkd for exercise extensions.
*)
let move_forward_and_grow
      ({ direction; extensions_remaining; head; tail } as t)
  =
  if extensions_remaining > 0
  then (
    t.extensions_remaining <- extensions_remaining - 1;
    Direction.next_position direction head, tail @ [ head ])
  else move_forward head tail direction
;;



let step t =
  let head, tail = move_forward_and_grow t in
  t.head <- head;
  t.tail <- tail;
  not (collides_with_self t)
;;

let add_letter t char =
  (* this function is only used in the spelling extension *)
  ignore t;
  ignore char
;;

let clear_spelled_word t ~spelled_word =
  (* this function is only used in the spelling extension *)
  ignore t;
  ignore spelled_word
;;

module Exercises = struct
  let exercise01 = move_forward

  let create_of_positions positions =
    let head = List.hd_exn positions in
    let tail = List.tl_exn positions |> List.rev in
    { direction = Right; head; tail; extensions_remaining = 0 }
  ;;

  let set_head snake head = snake.head <- head
  let set_tail snake tail = snake.tail <- tail
  let exercise04a = collides_with_self
  let exercise06a = grow_over_next_steps
  let exercise06c = move_forward_and_grow
  let exercise06c2 = step
end
