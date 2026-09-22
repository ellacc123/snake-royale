/**
 * The wire format served by the OCaml backend (`server/server.ml`).
 *
 * These types mirror the OCaml modules one-for-one:
 *   Position    <- src/position.ml
 *   Direction   <- src/direction.ml
 *   AppleColor  <- Apple.Color in src/apple.ml
 *   GameState   <- src/game_state.ml
 *
 * Nothing here carries behaviour. All game rules live in OCaml; the browser only
 * draws what it is told and forwards keystrokes.
 */

/** Note: `row` counts upwards from the bottom of the board, as it does in OCaml. */
export interface Position {
  readonly col: number;
  readonly row: number;
}

export type Direction = "Left" | "Up" | "Right" | "Down";

export type AppleColor = "Red" | "Gold";

export interface BoardDimensions {
  readonly width: number;
  readonly height: number;
}

export interface SnakeView {
  readonly head: Position;
  /** Reversed, as in OCaml: the first element is the tip of the tail. */
  readonly tail: readonly Position[];
  readonly direction: Direction;
}

export interface AppleView {
  readonly position: Position;
  readonly color: AppleColor;
}

/** Mirrors the `Game_state.t` variant, discriminated on `kind`. */
export type GameState =
  | { readonly kind: "InProgress" }
  | { readonly kind: "GameOver"; readonly reason: string }
  | { readonly kind: "Win" }
  /** Competitive mode only: `player` is 1 or 2, `reason` says how the other one lost. */
  | { readonly kind: "PlayerWins"; readonly player: number; readonly reason: string };

export type Seat = 1 | 2;

/** Who the caller is, from the point of view of the seat their token maps to. */
export interface You {
  readonly role: "player" | "spectator";
  readonly seat: Seat | null;
}

/** What the room looks like right now, regardless of who is asking. */
export interface Room {
  readonly seat1Taken: boolean;
  readonly seat2Taken: boolean;
  /** True until both seats are filled; the game does not tick while it is true. */
  readonly waitingForPlayers: boolean;
}

/** The reply to POST /api/join. The token is null for spectators, who have no seat. */
export interface JoinResponse {
  readonly role: "player" | "spectator";
  readonly seat: Seat | null;
  readonly token: string | null;
}

export interface GameView {
  readonly you: You;
  readonly room: Room;
  readonly board: BoardDimensions;
  /** Player one. */
  readonly snake: SnakeView;
  /** Player two, or null in a single-player game. */
  readonly snake2: SnakeView | null;
  readonly apple: AppleView;
  readonly score: number;
  readonly score2: number | null;
  readonly gameState: GameState;
}
