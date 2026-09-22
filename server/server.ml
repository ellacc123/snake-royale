open! Core
open! Async
open! Snake_lib
open Cohttp
open Cohttp_async

(* A one-room competitive snake server.
 *
 * The game lives here and the browser never simulates anything: it draws whatever
 * /api/state reports and forwards keystrokes. Two players can sit down, from two
 * different machines; everyone after them watches.
 *
 * See NETWORK_PLAY.md for why this is built the way it is. *)

let board_height = 22
let board_width = 25
let initial_snake_length = 3
let step_every = 0.1

(* How long a seated player can go without polling before they forfeit. At the client's
   50ms poll interval that is roughly 60 missed polls, so it takes a real disconnection
   rather than a slow frame to trigger it.

   Overridable with SNAKE_HEARTBEAT_SECONDS, which exists so the timeout can be tested
   without waiting three seconds per run. *)
let heartbeat_timeout =
  match Sys.getenv "SNAKE_HEARTBEAT_SECONDS" with
  | Some seconds ->
    (match Float.of_string_opt seconds with
     | Some seconds when Float.is_positive seconds -> Time_float.Span.of_sec seconds
     | Some _ | None -> Time_float.Span.of_sec 3.)
  | None -> Time_float.Span.of_sec 3.
;;

type seat =
  { token : string
  ; (* Refreshed by every request that carries this seat's token. *)
    mutable last_seen : Time_float.t
  }

type room =
  { mutable game : Game.t
  ; mutable seat1 : seat option
  ; mutable seat2 : seat option
  }

let new_game () =
  Game.create_competitive
    ~height:board_height
    ~width:board_width
    ~initial_snake_length
;;

let room = { game = new_game (); seat1 = None; seat2 = None }
let both_seats_filled () = Option.is_some room.seat1 && Option.is_some room.seat2

(* Tokens only have to be unguessable by the other browser window on the same screen, not
   cryptographically strong; [Random] is seeded from the clock at startup. *)
let random_token () =
  let alphabet = "0123456789abcdef" in
  String.init 32 ~f:(fun _ -> alphabet.[Random.int (String.length alphabet)])
;;

let seat_of_token token =
  match room.seat1, room.seat2 with
  | Some seat, _ when String.equal seat.token token -> Some 1
  | _, Some seat when String.equal seat.token token -> Some 2
  | _, _ -> None
;;

(* Every request carrying a valid token counts as a heartbeat. *)
let touch_seat token =
  let now = Time_float.now () in
  match seat_of_token token with
  | Some 1 -> Option.iter room.seat1 ~f:(fun seat -> seat.last_seen <- now)
  | Some 2 -> Option.iter room.seat2 ~f:(fun seat -> seat.last_seen <- now)
  | Some _ | None -> ()
;;

let join () =
  let seat token = { token; last_seen = Time_float.now () } in
  match room.seat1, room.seat2 with
  | None, _ ->
    let token = random_token () in
    room.seat1 <- Some (seat token);
    (* Filling the second seat starts a fresh game, so nobody joins midway through
       someone else's. *)
    if both_seats_filled () then room.game <- new_game ();
    `Player (1, token)
  | _, None ->
    let token = random_token () in
    room.seat2 <- Some (seat token);
    if both_seats_filled () then room.game <- new_game ();
    `Player (2, token)
  | Some _, Some _ -> `Spectator
;;

let forfeit ~winner =
  match Game.game_state room.game with
  | In_progress ->
    Game.declare_winner
      room.game
      ~player:winner
      ~reason:"opponent disconnected - forfeit"
  | Game_over _ | Win | Player_wins _ -> ()
;;

(* Frees any seat whose player has gone quiet, handing the game to whoever is left. *)
let drop_silent_players () =
  let now = Time_float.now () in
  let is_silent seat =
    Time_float.Span.( > ) (Time_float.diff now seat.last_seen) heartbeat_timeout
  in
  let silent1 = Option.exists room.seat1 ~f:is_silent in
  let silent2 = Option.exists room.seat2 ~f:is_silent in
  match silent1, silent2 with
  | false, false -> ()
  | true, true ->
    (* Both gone: no one to award the game to, so just empty the room. *)
    room.seat1 <- None;
    room.seat2 <- None
  | true, false ->
    room.seat1 <- None;
    if Option.is_some room.seat2 then forfeit ~winner:2
  | false, true ->
    room.seat2 <- None;
    if Option.is_some room.seat1 then forfeit ~winner:1
;;

(* This mirrors [handle_steps] in run.ml, with two additions: the clock keeps running but
   the game only advances once both seats are filled, and every tick is also a chance to
   notice that someone has stopped talking to us. *)
let start_ticking () =
  Clock.every (Time_float.Span.of_sec step_every) (fun () ->
    drop_silent_players ();
    if both_seats_filled ()
    then (
      match Game.game_state room.game with
      | In_progress -> Game.step room.game
      | Game_over _ | Win | Player_wins _ -> ()))
;;

(* Small hand-rolled JSON writer. The payload shape is fixed and tiny, so this avoids
   taking a dependency on a JSON library. *)
let escape_string s =
  String.concat_map s ~f:(fun c ->
    match c with
    | '"' -> {|\"|}
    | '\\' -> {|\\|}
    | '\n' -> {|\n|}
    | c -> String.of_char c)
;;

let json_string s = sprintf {|"%s"|} (escape_string s)

(* [Direction.t] and [Apple.Color.t] both derive [sexp_of], and their constructors are
   single atoms, so the sexp is exactly the constructor name. *)
let json_of_sexp_atom sexp = json_string (Sexp.to_string sexp)
let json_of_position ({ col; row } : Position.t) = sprintf {|{"col":%d,"row":%d}|} col row

let json_of_game_state (state : Game_state.t) =
  match state with
  | In_progress -> {|{"kind":"InProgress"}|}
  | Win -> {|{"kind":"Win"}|}
  | Game_over reason ->
    sprintf {|{"kind":"GameOver","reason":%s}|} (json_string reason)
  | Player_wins (player, reason) ->
    sprintf
      {|{"kind":"PlayerWins","player":%d,"reason":%s}|}
      player
      (json_string reason)
;;

let json_of_snake snake =
  sprintf
    {|{"head":%s,"tail":[%s],"direction":%s}|}
    (json_of_position (Snake.head snake))
    (Snake.tail snake |> List.map ~f:json_of_position |> String.concat ~sep:",")
    (json_of_sexp_atom (Direction.sexp_of_t (Snake.direction snake)))
;;

(* The state document is rendered per requester: [seat] is which chair this particular
   caller is sitting in, so the client can say "you are player 2". *)
let json_of_state ~seat =
  let game = room.game in
  let apple = Game.apple game in
  let board = Game.board game in
  let json_or_null f = function
    | None -> "null"
    | Some value -> f value
  in
  let you =
    match seat with
    | Some n -> sprintf {|{"role":"player","seat":%d}|} n
    | None -> {|{"role":"spectator","seat":null}|}
  in
  let room_json =
    sprintf
      {|{"seat1Taken":%b,"seat2Taken":%b,"waitingForPlayers":%b}|}
      (Option.is_some room.seat1)
      (Option.is_some room.seat2)
      (not (both_seats_filled ()))
  in
  sprintf
    {|{"you":%s,"room":%s,"board":{"width":%d,"height":%d},"snake":%s,"snake2":%s,"apple":{"position":%s,"color":%s},"score":%d,"score2":%s,"gameState":%s}|}
    you
    room_json
    (Board.width board)
    (Board.height board)
    (json_of_snake (Game.snake game))
    (json_or_null json_of_snake (Game.snake2 game))
    (json_of_position (Apple.position apple))
    (json_of_sexp_atom (Apple.Color.sexp_of_t (Apple.color apple)))
    (Game.score game)
    (json_or_null Int.to_string (Game.score2 game))
    (json_of_game_state (Game.game_state game))
;;

let cors_headers =
  Header.of_list
    [ "access-control-allow-origin", "*"
    ; "access-control-allow-methods", "GET, POST, OPTIONS"
    ; "access-control-allow-headers", "content-type"
    ]
;;

let respond_json body =
  let headers = Header.add cors_headers "content-type" "application/json" in
  Server.respond_string ~headers body
;;

let handler ~body:_ _client request =
  let uri = Cohttp.Request.uri request in
  (* Tokens and keys travel as query parameters so the server never has to parse a
     request body, which would mean writing a JSON reader as well as a writer. *)
  let token = Uri.get_query_param uri "token" in
  Option.iter token ~f:touch_seat;
  let seat = Option.bind token ~f:seat_of_token in
  match Cohttp.Request.meth request, Uri.path uri with
  | `OPTIONS, _ -> Server.respond_string ~headers:cors_headers ""
  | `POST, "/api/join" ->
    (match join () with
     | `Player (seat, token) ->
       respond_json
         (sprintf
            {|{"role":"player","seat":%d,"token":%s}|}
            seat
            (json_string token))
     | `Spectator ->
       respond_json {|{"role":"spectator","seat":null,"token":null}|})
  | `GET, "/api/state" -> respond_json (json_of_state ~seat)
  | `POST, "/api/key" ->
    (match seat, Uri.get_query_param uri "key" with
     | Some player, Some key when String.length key = 1 ->
       (* Keys are ignored until the game is actually running, so a lone player can't
          drive their snake around while waiting for an opponent. *)
       if both_seats_filled ()
       then Game.handle_key_for_player room.game ~player key.[0]
     | (Some _ | None), (Some _ | None) -> ());
    respond_json (json_of_state ~seat)
  | _ ->
    Server.respond_string ~headers:cors_headers ~status:`Not_found "not found"
;;

let main ~port =
  Random.self_init ();
  start_ticking ();
  Server.create ~on_handler_error:`Raise (Tcp.Where_to_listen.of_port port) handler
  >>= fun _server ->
  printf "snake server listening on http://localhost:%d\n%!" port;
  Deferred.never ()
;;

let () =
  don't_wait_for (main ~port:8080);
  never_returns (Scheduler.go ())
;;
