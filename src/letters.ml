open! Core

type t = Letter.t list [@@deriving sexp_of]

let letters = Fn.id
let board_positions = List.map ~f:Letter.position

let create' ~board ~snake ~apple ~alphabet : t option =
  let possible_positions =
    let snake_positions = Snake.all_positions snake in
    let board_positions = Board.all_positions board in
    let occupied_positions = Apple.position apple :: snake_positions in
    let is_not_occupied pos =
      not (List.mem occupied_positions pos ~equal:Position.equal)
    in
    List.filter board_positions ~f:is_not_occupied
  in
  if Int.( <= ) (List.length alphabet) (List.length possible_positions)
  then
    Some
      (let positions =
         List.take (List.permute possible_positions) (List.length alphabet)
       in
       (* this should never raise because we check that there is enough space for the
          whole alphabet, and we then define [positions] based on the length of
          [alphabet]. *)
       List.map2_exn positions alphabet ~f:(fun position char ->
         Letter.create ~position ~char))
  else None
;;

let alphabet =
  [ 'A'
  ; 'B'
  ; 'C'
  ; 'D'
  ; 'E'
  ; 'F'
  ; 'G'
  ; 'H'
  ; 'I'
  ; 'J'
  ; 'K'
  ; 'L'
  ; 'M'
  ; 'N'
  ; 'O'
  ; 'P'
  ; 'Q'
  ; 'R'
  ; 'S'
  ; 'T'
  ; 'U'
  ; 'V'
  ; 'W'
  ; 'X'
  ; 'Y'
  ; 'Z'
  ]
;;

let create = create' ~alphabet
let empty = []
