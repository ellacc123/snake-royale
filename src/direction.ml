open! Core

type t =
  | Left
  | Up
  | Right
  | Down
[@@deriving sexp_of]

let next_position t { Position.row; col } : Position.t =
  match t with
  | Left -> { row; col = col - 1 }
  | Right -> { row; col = col + 1 }
  | Up -> { row = row + 1; col }
  | Down -> { row = row - 1; col }
;;

(** [opposite] is used to lay a new snake's body out behind its head. *)
let opposite t =
  match t with
  | Left -> Right
  | Right -> Left
  | Up -> Down
  | Down -> Up
;;

(** Exercise 02a:

    OCaml has a very useful tool called a match statement. It allows you to handle
    different cases in a very concise way and it can help the compiler prevent you from
    making some common mistakes.

    You can write a match statement like:
    {[
      match THING_TO_MATCH with
      | CASE1 -> THING_TO_DO1
      | CASE2 -> THING_TO_DO2
        ...
    ]}

    More concretely, consider the following function
    {[
      let is_prime_less_than_10 x =
        if x = 2
        then true
        else if x = 3
        then true
        else if x = 5
        then true
        else if x = 7
        then true
        else false
    ]}

    This is a bit contrived, but this function checks if the passed in variable x is 2 or 3
    or 5 or 7. The implementation is quite verbose, but it is a common enough pattern in
    code. In OCaml, a match statement allows us to express each of these cases in a way
    that is much easier to read:

    {[
      let is_prime_less_than_10 x =
        match x with
        | 2 -> true
        | 3 -> true
        | 5 -> true
        | 7 -> true
        | _ -> false
    ]}

    _ is a special catch-all that will match all things. This is the equivalent to the
    final else above. Note that ordering is important, because each case is evaluated in
    order. If the _ was not put last, every case after it would never get used, because _
    matches everything.

    For example,
    {[
      let is_prime_less_than_10 x =
        match x with
        | _ -> false
        | 2 -> true
        | 3 -> true
        | 5 -> true
        | 7 -> true
    ]}
    would always return false.

    We can simplify this function further because if multiple cases do the same thing, we
    combine them like this:

    {[
      let is_prime_less_than_10 x =
        match x with
        | 2
        | 3
        | 5
        | 7 -> true
        | _ -> false
    ]}

    The first 4 cases all use the same arrow, so we don't need to write "-> true" for each
    of the cases.

    In OCaml, white space doesn't matter, so you would be more likely to see the previous
    example written as:

    {[
      let is_prime_less_than_10 x =
        match x with
        | 2 | 3 | 5 | 7 -> true
        | _ -> false
    ]}

    Alright, on to exercise 02.

    First, check out the definition of type [t] at the top of this file.

    (By the way, all modules and ml files will have a type [t]. This isn't a requirement,
    but it considered good style at Jane Street, so it is what we will use.)

    A [Direction.t] is defined as a variant. This is a type that expresses different
    possible cases. It's similar to an enum, which you may have seen in another
    language, but more powerful (as we'll soon see).

    In our case here, a [Direction.t] can be one of Left, Up, Right or Down.

    We want to write a function, [of_key], which takes a character (representing a key that
    the player of the game just pressed) and returns a [Direction.t] representing what
    direction the snake should be going after the player presses that key.

    Our game is meant to be played with the "w", "a", "s", and "d" keys, we'll want to
    match on each of the characters and return the direction that it corresponds to. (For
    example, "w" should correspond to "Up".)

    However, there are lots of possible characters, not just those 4, so we'll need to
    define what we want to do in those cases as well.

    There is a special variant we use in OCaml which is an option. The option type is
    defined:
    {[
      type 'a t =
        | Some of 'a
        | None
    ]}

    The ['a] means that this type can be parametrized by any other type. For example, we
    can have {[ Some 5 ]}, which has type "int option", and {[ Some "hello" ]}, which has
    type "string option".

    In the case of [of_key], we would like to return a "Direction.t option". It should be
    Some if the key we got was one of the valid keys ('w', 'a', 's', or 'd'), and
    it should be None for all other characters.

    One last thing: in OCaml the way you refer to a character is with single quotes:
    {[ 'a' ]}

    When you are done with on_key,

    $ dune runtest ./tests/exercise02a

    should no longer have errors.

    Once you're done, let's go to game.ml to work on exercise 02b.
*)
let of_key key = 
  match key with 
  | 'w' -> Some Up
  | 'a' -> Some Left
  | 's' -> Some Down
  | 'd' ->  Some Right
  | _ -> None

(** Exercise 09: player two steers with 'i', 'j', 'k' and 'l', which sit under the right
    hand the same way 'w', 'a', 's' and 'd' sit under the left. *)
let of_player2_key key =
  match key with
  | 'i' -> Some Up
  | 'j' -> Some Left
  | 'k' -> Some Down
  | 'l' -> Some Right
  | _ -> None
;;

module Exercises = struct
  let exercise02a = of_key
end
