open! Core

(** Exercise 09: a player is a snake plus the score it has earned. Single-player games
    have one; competitive games have two. *)
type player =
  { mutable snake : Snake.t
  ; mutable score : int
  }
[@@deriving sexp_of]

type t =
  { mutable player1 : player
  ; (* [None] in a single-player game. *)
    mutable player2 : player option
  ; mutable game_state : Game_state.t
  ; mutable apple : Apple.t
  ; board : Board.t
  ; (* [initial_snake_length] is kept so that [restart] can rebuild the starting snakes. *)
    initial_snake_length : int
  }
[@@deriving sexp_of]

(** Where player two starts: the opposite corner, facing back towards player one. *)
let player2_start ~board ~initial_snake_length =
  let head =
    { Position.row = Board.height board - 1
    ; col = Board.width board - initial_snake_length
    }
  in
  Snake.create_at ~head ~direction:Left ~length:initial_snake_length
;;

let players t =
  match t.player2 with
  | None -> [ t.player1 ]
  | Some player2 -> [ t.player1; player2 ]
;;

let occupied_positions t =
  List.concat_map (players t) ~f:(fun player -> Snake.all_positions player.snake)
;;

(* Only used by the spelling extension. It's lazy so that we don't read the dictionary
   (or fail on a machine that doesn't have one) every time the game starts. *)
let trie =
  lazy
    (let dictionary = In_channel.read_lines "/usr/share/dict/words" in
     ignore dictionary;
     Trie.create ())
;;

(* The single-player rendering is unchanged; a second player simply appends two more
   lines, so existing single-player tests keep their expected output. *)
let to_string { player1; player2; game_state; apple; board; _ } =
  let base =
    Core.sprintf
      !{|Game state: %{sexp:Game_state.t}
Apple: %{sexp:Apple.t}
Board: %{sexp:Board.t}
Score : %s
Snake: %s |}
      game_state
      apple
      board
      (Int.to_string player1.score)
      (Snake.to_string ~indent:2 player1.snake)
  in
  match player2 with
  | None -> base
  | Some player2 ->
    Core.sprintf
      !{|%s
Player 2 score : %s
Player 2 snake: %s |}
      base
      (Int.to_string player2.score)
      (Snake.to_string ~indent:2 player2.snake)
;;

let create_with_players ~players ~height ~width ~initial_snake_length =
  let board = Board.create ~height ~width in
  let player1 = { snake = Snake.create ~length:initial_snake_length; score = 0 } in
  let player2 =
    match players with
    | 1 -> None
    | 2 ->
      Some { snake = player2_start ~board ~initial_snake_length; score = 0 }
    | n -> raise_s [%message "unsupported number of players" (n : int)]
  in
  let snakes =
    player1.snake :: (match player2 with None -> [] | Some p -> [ p.snake ])
  in
  let occupied = List.concat_map snakes ~f:Snake.all_positions in
  match Apple.create_excluding ~board ~occupied with
  | None -> failwith "unable to create initial apple"
  | Some apple ->
    let t =
      { player1
      ; player2
      ; apple
      ; game_state = In_progress
      ; board
      ; initial_snake_length
      }
    in
    if List.exists occupied ~f:(fun pos -> not (Board.in_bounds t.board pos))
    then failwith "unable to create initial snake"
    else t
;;

let create ~height ~width ~initial_snake_length =
  create_with_players ~players:1 ~height ~width ~initial_snake_length
;;

(** Exercise 09: the same game with a second snake in the opposite corner. *)
let create_competitive ~height ~width ~initial_snake_length =
  create_with_players ~players:2 ~height ~width ~initial_snake_length
;;

(* let current_snake = Game.snake game in ... *)
let snake t = t.player1.snake
let apple t = t.apple
let game_state t = t.game_state
let board t = t.board
let score t = t.player1.score

(** Exercise 09: [None] unless the game is in competitive mode. *)
let snake2 t = Option.map t.player2 ~f:(fun player -> player.snake)

let score2 t = Option.map t.player2 ~f:(fun player -> player.score)
let is_competitive t = Option.is_some t.player2

let spelled_words t =
  ignore t;
  (* Hardcode an empty list for now. This may be changed when we implement the Spelling
     Game extension. *)
  []
;;

(** Exercise 02b:

    Now, we're going to write a function that will be called whenever the user presses a
    key. For now, the only keys we care about are the ones that should cause the snake to
    change direction.

    To start, let's explore this module a little.

    This module represents the game state. Take a look at the type [t] at the top of this
    file. This is a record definition.

    A record is a data structure that allows you to group several pieces of data together.
    The names of the fields are on the left side of the ':' and the types of those fields
    are on the right side. By default record fields are immutable. The "mutable" keyword
    allows us to modify the value of that field.

    This record has 4 elements: a [snake], a [game_state], an [apple], and a [board]. We'll
    explain each field when it's needed.

    Take a note of the [set_direction] function provided in snake.ml. Given a snake and a
    direction, this function will update the direction stored in the snake.

    Note the signature of this function:
    {[
      val set_direction : Snake.t -> Direction.t -> unit
    ]}

    The "unit" type is a special type that is returned by all side-effecting
    functions. This includes behaviors like printing or, as in this function, setting a
    mutable value.

    Recall that we can refer to functions defined in other files by prepending the filename
    (with capitalized first letter) to the function name.

    Let's use the [of_key] function we just wrote in direction.ml to get the direction the
    user intended and set it in the snake.

    The way that you reference the snake field in the record is with a '.' :
    {[
      t.snake
    ]}

    If the key wasn't a valid input key, our [of_key] function will return[None] . In that
    case, we have no action to take. Because we will use a match we will still need to
    specify what action to take in that case. To implement this, we once again use the
    "unit" type. You will probably need the following case in your match statement:
    {[
      | None -> ()
    ]}

    Once you've implemented [handle_key], run

    $ dune runtest ./tests/exercise02b

    You should see no more failures.

    Now if you build and run the game again, you should be able to use the 'w', 'a', 's',
    and 'd' keys to control the snake.

    You may notice weird behavior if you run the snake off the game board. We'll handle
    collision behavior in the next exercise.

    Once you're done, go back to README.mkd for the next exercise. *)
(** Exercise 10:

    [restart] puts the game back into its starting state: a fresh snake of the length the
    game was created with, a fresh apple, a score of zero, and an [In_progress] state. The
    board never changes, so it's reused as is. *)
let restart t =
  let snake = Snake.create ~length:t.initial_snake_length in
  (* Competitive games come back as competitive games. *)
  let player2 =
    Option.map t.player2 ~f:(fun _ ->
      { snake =
          player2_start
            ~board:t.board
            ~initial_snake_length:t.initial_snake_length
      ; score = 0
      })
  in
  let occupied =
    List.concat_map
      (snake :: (match player2 with None -> [] | Some p -> [ p.snake ]))
      ~f:Snake.all_positions
  in
  match Apple.create_excluding ~board:t.board ~occupied with
  | None -> failwith "unable to create apple when restarting"
  | Some apple ->
    t.player1 <- { snake; score = 0 };
    t.player2 <- player2;
    t.apple <- apple;
    t.game_state <- In_progress
;;

(** Exercise 09: 'w'/'a'/'s'/'d' steer player one and 'i'/'j'/'k'/'l' steer player two.
    Player two's keys do nothing in a single-player game. *)
let handle_key t key =
  match key with
  | 'r' -> restart t
  | _ ->
    (match Direction.of_key key with
     | Some direction -> Snake.set_direction t.player1.snake direction
     | None ->
       (match t.player2, Direction.of_player2_key key with
        | Some player2, Some direction -> Snake.set_direction player2.snake direction
        | (Some _ | None), (Some _ | None) -> ()))
;;

(** Networked play: both players press 'w'/'a'/'s'/'d' at their own keyboard, and the
    server decides whose snake those keys belong to from the seat the request's token maps
    to. That is why this takes the player explicitly rather than reading it off the key,
    the way [handle_key] does for a shared keyboard. *)
let handle_key_for_player t ~player key =
  match key with
  | 'r' -> restart t
  | _ ->
    (match Direction.of_key key with
     | None -> ()
     | Some direction ->
       (match player, t.player2 with
        | 1, _ -> Snake.set_direction t.player1.snake direction
        | 2, Some player2 -> Snake.set_direction player2.snake direction
        | _, _ -> ()))
;;

(** Ends the game from outside the normal rules. The server uses this when a player stops
    sending heartbeats, so the one still playing wins by forfeit. *)
let declare_winner t ~player ~reason =
  t.game_state <- Player_wins (player, reason)
;;

(** Exercise 03b:

    Take a look at the definition of the [Game_state.t] type in game_state.mli. Do the
    three variants make sense?

    [check_for_collisions] will be called after the snake has been updated to move forward
    one space. It should check to make sure the snake is still inside the bounds of
    the game board. If the snake is now out of bounds we want to update the game_state
    to note the fact that the game is now over.

    The in_bounds function you wrote in 03a was in the board module, so you can access it
    with [Board.in_bounds].

    If there is a collision we should set the [game_state] of [t] to be
    {[
      Game_over "Out of bounds!"
    ]}

    The way that you set a mutable record value is with the "<-" operator. For example:

    {[
      type t = { mutable counter : int }

      let increment_counter t = t.counter <- t.counter + 1
    ]}

    [Snake.head] is a function we've provided for you that returns a [Position.t]
    representing the head of the snake.
    {[
      val head : Snake.t -> Position.t
    ]}

    Once you have implemented [check_for_collisions],

    $ dune runtest ./tests/exercise03b

    should have no output.

    Return to README.mkd for instructions on exercise 04. *)
let check_for_collisions t =
  match Board.in_bounds t.board (Snake.head t.player1.snake) with
  | false -> t.game_state <- Game_over "Out of bounds!"
  | true  -> ()

(** Exercise 06b:

    Every time the snake steps forward, [maybe_consume_apple] should be called.
    It should check if the snake head is at the current position of the apple
    stored in the game.

    Hint: We've given you some functions to help with this. Take a look at snake.mli and
    apple.mli to find functions to get the positions you need to consider

    If it is, we should call the [grow_over_next_steps] function in snake.ml that we just
    implemented to update the snake so that it can grow over the next few time steps. The
    amount it should grow is based on the value of [Apple.amount_to_grow].

    If the apple is consumed, we should also spawn a new apple on the board using the
    function we encountered in exercise 05, [Apple.create].

    Recall that if [Apple.create] returns [None], that means that we have won the game, so
    we should update the [game_state] to reflect that.

    When you've implemented this, make sure the tests for exercise 06b pass:

    $ dune runtest ./tests/exercise06b

    Once the test passes, return to snake.ml for exercise 06c. *)
let maybe_consume_apple t =
  (* Remember to remove `ignore t` when implemented. *)
  if Position.equal (Snake.head t.player1.snake) (Apple.position t.apple)
  then (
    Snake.grow_over_next_steps t.player1.snake (Apple.amount_to_grow t.apple);
    (* Read the points off the apple we just ate, before it gets replaced below. *)
    t.player1.score <- t.player1.score + Apple.points t.apple;
    match Apple.create ~board:t.board ~snake:t.player1.snake with
    | None -> t.game_state <- Win
    | Some apple -> t.apple <- apple)
;;

let maybe_consume_letter t = ignore t

(** Exercise 09: one step of a competitive game.

    Both snakes move before either is judged, so a head-on crash kills both rather than
    depending on which snake we happened to step first. A player loses by running into
    itself, leaving the board, or hitting the other snake; the survivor wins. *)
let step_competitive t player1 player2 =
  let survived1 = Snake.step player1.snake in
  let survived2 = Snake.step player2.snake in
  let death_of player ~survived_self_collision ~opponent =
    if not survived_self_collision
    then Some "ran into itself"
    else if not (Board.in_bounds t.board (Snake.head player.snake))
    then Some "went out of bounds"
    else if
      List.mem
        (Snake.all_positions opponent.snake)
        (Snake.head player.snake)
        ~equal:Position.equal
    then Some "ran into the other snake"
    else None
  in
  let death1 =
    death_of player1 ~survived_self_collision:survived1 ~opponent:player2
  in
  let death2 =
    death_of player2 ~survived_self_collision:survived2 ~opponent:player1
  in
  match death1, death2 with
  | Some reason1, Some reason2 ->
    t.game_state
    <- Game_over
         (sprintf "draw - player 1 %s, player 2 %s" reason1 reason2)
  | Some reason, None ->
    t.game_state <- Player_wins (2, sprintf "player 1 %s" reason)
  | None, Some reason ->
    t.game_state <- Player_wins (1, sprintf "player 2 %s" reason)
  | None, None ->
    let eat player =
      if Position.equal (Snake.head player.snake) (Apple.position t.apple)
      then (
        Snake.grow_over_next_steps player.snake (Apple.amount_to_grow t.apple);
        player.score <- player.score + Apple.points t.apple;
        true)
      else false
    in
    let eaten1 = eat player1 in
    let eaten2 = eat player2 in
    if eaten1 || eaten2
    then (
      match
        Apple.create_excluding ~board:t.board ~occupied:(occupied_positions t)
      with
      | Some apple -> t.apple <- apple
      (* Nowhere left to put an apple means the board is full, so the game ends on
         points rather than on a crash. *)
      | None ->
        t.game_state
        <- (if player1.score > player2.score
            then Player_wins (1, "board is full and player 1 scored more")
            else if player2.score > player1.score
            then Player_wins (2, "board is full and player 2 scored more")
            else Game_over "draw - board is full and the scores are level"))
;;

(** Exercise 04b:

    [step] is the function that is called in a loop to make the game progress. As you can
    see, we have provided part of this for you.

    [Snake.step] returns false if the snake collided with itself, and true if the game can
    continue.

    We've already handled the case where the value is true, but when the value is false, we
    currently do nothing.

    Modify this function to set the [game_state] field of the game with the message
    "Self collision!".

    When all the tests for exercise 04 pass, return to README.mkd for exercise 05.
*)
let step t =
  ignore trie;
  match t.player2 with
  | Some player2 -> step_competitive t t.player1 player2
  | None ->
    if Snake.step t.player1.snake
    then (
      check_for_collisions t;
      maybe_consume_apple t;
      maybe_consume_letter t)
    else t.game_state <- Game_over "Self collision!"
;;

module Exercises = struct
  let exercise02b = handle_key

  (* These copy the game so a test can drop in its own snake without disturbing the
     original. The copy needs a fresh [player1] too, since players are mutable. *)
  let with_snake t snake = { t with player1 = { t.player1 with snake } }

  let exercise03b t snake =
    let t = with_snake t snake in
    check_for_collisions t;
    t.game_state
  ;;

  let exercise04b t snake =
    let t = with_snake t snake in
    step t;
    t.player1.snake, t.game_state
  ;;

  let exercise06b = maybe_consume_apple
  let set_apple t apple = t.apple <- apple
  let set_snake t snake = t.player1.snake <- snake
end
