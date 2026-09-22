open! Core

module Colors = struct
  let black = Graphics.rgb 000 000 000
  let green = Graphics.rgb 000 255 000
  let head_color = Graphics.rgb 100 100 125

  (* Exercise 09: player two is drawn in cyan so the two snakes are easy to tell apart. *)
  let player2_body = Graphics.rgb 000 200 255
  let player2_head = Graphics.rgb 000 120 160
  let red = Graphics.rgb 255 000 000
  let gold = Graphics.rgb 255 223 000
  let white = Graphics.rgb 255 255 255
  let game_in_progress = Graphics.rgb 100 100 200
  let game_lost = Graphics.rgb 200 100 100
  let game_won = Graphics.rgb 100 200 100

  let apple_color apple =
    match Apple.color apple with
    | Red -> red
    | Gold -> gold
  ;;

  let letter_color letter = match Letter.color letter with White -> white
end

(* These constants are optimized for running on a low-resolution screen. Feel free to
   increase the scaling factor to tweak! *)
module Constants = struct
  let scaling_factor = 1.
  let play_area_height = 600. *. scaling_factor |> Float.iround_down_exn
  let header_height = 75. *. scaling_factor |> Float.iround_down_exn
  let play_area_width = 675. *. scaling_factor |> Float.iround_down_exn
  let block_size = 27. *. scaling_factor |> Float.iround_down_exn
end

let only_one : bool ref = ref false

let init_exn ?(players = 1) () =
  let open Constants in
  (* Should raise if called twice *)
  if !only_one
  then failwith "Can only call init_exn once"
  else only_one := true;
  Graphics.open_graph
    (Printf.sprintf
       " %dx%d"
       (play_area_height + header_height)
       play_area_width);
  let height = play_area_height / block_size in
  let width = play_area_width / block_size in
  match players with
  | 2 -> Game.create_competitive ~height ~width ~initial_snake_length:3
  | _ -> Game.create ~height ~width ~initial_snake_length:3
;;

let draw_block { Position.row; col } ~color ~outline =
  let open Constants in
  let col = col * block_size in
  let row = row * block_size in
  Graphics.set_color color;
  let x1, y1, x2, y2 = col + 1, row + 1, block_size - 1, block_size - 1 in
  Graphics.fill_rect x1 y1 x2 y2;
  if outline
  then (
    Graphics.set_color Graphics.cyan;
    Graphics.draw_rect x1 y1 x2 y2)
;;

let draw_header ~game_state ~score ~score2 ~spelled_words =
  let open Constants in
  let header_color =
    match (game_state : Game_state.t) with
    | In_progress -> Colors.game_in_progress
    | Game_over _ -> Colors.game_lost
    | Win | Player_wins _ -> Colors.game_won
  in
  Graphics.set_color header_color;
  Graphics.fill_rect 0 play_area_height play_area_width header_height;
  let header_text =
    match (game_state : Game_state.t) with
    | In_progress -> Game_state.to_string game_state
    | Game_over _ | Win | Player_wins _ ->
      Game_state.to_string game_state ^ "  (press 'r' to play again)"
  in
  let score_text =
    match score2 with
    | None -> Printf.sprintf "Score: %d" score
    | Some score2 -> Printf.sprintf "P1: %d    P2: %d" score score2
  in
  Graphics.set_color Colors.black;
  Graphics.moveto 0 play_area_height;
  Graphics.draw_string header_text;
  Graphics.moveto 0 (play_area_height + 50);
  Graphics.draw_string score_text;
  Graphics.moveto 0 (play_area_height + 25);
  match spelled_words with
  | [] -> ()
  | hd :: tl ->
    Graphics.draw_string "Spelled words: ";
    Graphics.set_color Colors.red;
    Graphics.draw_string (hd ^ " ");
    Graphics.set_color Colors.black;
    Graphics.draw_string (String.concat tl ~sep:" ")
;;

let draw_play_area () =
  let open Constants in
  Graphics.set_color Colors.black;
  Graphics.fill_rect 0 0 play_area_width play_area_height
;;

let draw_apple apple =
  let apple_position = Apple.position apple in
  draw_block apple_position ~color:(Colors.apple_color apple) ~outline:false
;;

let draw_letter letter ~color =
  let open Constants in
  let ({ col; row } : Position.t) = Letter.position letter in
  let char_width, char_height =
    Letter.char letter |> String.of_char |> Graphics.text_size
  in
  let col = (col * block_size) + ((block_size - char_width) / 2) in
  let row = (row * block_size) + ((block_size - char_height) / 2) in
  Graphics.moveto col row;
  Graphics.set_color color;
  Graphics.draw_char (Letter.char letter)
;;

let draw_letters (letters : Letters.t) =
  Letters.letters letters
  |> List.iter ~f:(fun letter ->
    draw_letter letter ~color:(Colors.letter_color letter))
;;

(* Exercise 09 made the colours arguments so that the two players can be told apart. *)
let draw_snake
      ?(body_color = Colors.green)
      ?(head_color = Colors.head_color)
      snake_head
      snake_tail
      eaten_letters
  =
  let () =
    match eaten_letters with
    | None ->
      List.iter snake_tail ~f:(draw_block ~color:body_color ~outline:false)
    | Some eaten_letters ->
      let pos_and_chars, _ =
        List.zip_with_remainder (List.rev snake_tail) eaten_letters
      in
      List.iter pos_and_chars ~f:(fun (position, char) ->
        draw_block position ~color:body_color ~outline:true;
        Letter.create ~position ~char |> draw_letter ~color:Colors.black)
  in
  (* Snake head is a different color *)
  draw_block ~color:head_color snake_head ~outline:false
;;

let render game =
  (* We want double-buffering. See
     https://v2.ocaml.org/releases/4.03/htmlman/libref/Graphics.html
     for more info!

     So, we set [display_mode] to false, draw to the background buffer,
     set [display_mode] to true and then synchronize. This guarantees
     that there won't be flickering! *)
  Graphics.display_mode false;
  let snake = Game.snake game in
  let apple = Game.apple game in
  let game_state = Game.game_state game in
  let spelled_words = Game.spelled_words game in
  let score = Game.score game in
  let score2 = Game.score2 game in
  (* For the spelling extension only: if you'd like to make the letters bigger and you are on
     mac or linux, you can add the following line here:

     Graphics.set_font  "lucidasanstypewriter-bold-18";
  *)
  draw_header ~game_state ~score ~score2 ~spelled_words;
  draw_play_area ();
  draw_apple apple;
  (* delete this ignore statement and call the function in the Spelling Extension *)
  ignore draw_letters;
  (* update this eaten_letters variable in the Spelling Extension *)
  let eaten_letters = None in
  draw_snake (Snake.head snake) (Snake.tail snake) eaten_letters;
  (* Exercise 09: player two, when there is one. *)
  Option.iter (Game.snake2 game) ~f:(fun snake2 ->
    draw_snake
      ~body_color:Colors.player2_body
      ~head_color:Colors.player2_head
      (Snake.head snake2)
      (Snake.tail snake2)
      eaten_letters);
  Graphics.display_mode true;
  Graphics.synchronize ()
;;

let read_key () =
  if Graphics.key_pressed () then Some (Graphics.read_key ()) else None
;;
