import type { GameView, Position, Seat } from "./types";

/**
 * Canvas renderer. This is the port of `src/snake_graphics.ml` — the colours and the
 * header layout are deliberately the same as the X11 version.
 */

export const BLOCK_SIZE = 27;
export const HEADER_HEIGHT = 75;

const COLORS = {
  black: "rgb(0, 0, 0)",
  green: "rgb(0, 255, 0)",
  head: "rgb(100, 100, 125)",
  // Player two, in competitive mode.
  player2Body: "rgb(0, 200, 255)",
  player2Head: "rgb(0, 120, 160)",
  red: "rgb(255, 0, 0)",
  gold: "rgb(255, 223, 0)",
  gameInProgress: "rgb(100, 100, 200)",
  gameLost: "rgb(200, 100, 100)",
  gameWon: "rgb(100, 200, 100)",
  waiting: "rgb(170, 170, 170)",
  spectatorBadge: "rgb(60, 60, 60)",
} as const;

/** Used by the status line so a player can tell which snake is theirs. */
export function seatColorName(seat: Seat | null): string {
  return seat === 2 ? "cyan" : "green";
}

export function canvasSize(view: GameView): { width: number; height: number } {
  return {
    width: view.board.width * BLOCK_SIZE,
    height: view.board.height * BLOCK_SIZE + HEADER_HEIGHT,
  };
}

/**
 * OCaml's board has row 0 at the *bottom*, while canvas y grows downwards. This is the
 * only place that conversion happens.
 */
function blockTopLeft(
  { col, row }: Position,
  boardHeight: number,
): { x: number; y: number } {
  return { x: col * BLOCK_SIZE, y: (boardHeight - 1 - row) * BLOCK_SIZE };
}

function drawBlock(
  ctx: CanvasRenderingContext2D,
  position: Position,
  boardHeight: number,
  color: string,
): void {
  const { x, y } = blockTopLeft(position, boardHeight);
  ctx.fillStyle = color;
  // The 1px inset matches [draw_block]'s `col + 1, row + 1` in snake_graphics.ml,
  // which is what gives the snake its visible segment seams.
  ctx.fillRect(x + 1, y + 1, BLOCK_SIZE - 1, BLOCK_SIZE - 1);
}

function headerColor(view: GameView): string {
  // A room that is still filling up is neither won nor lost.
  if (view.room.waitingForPlayers) {
    return COLORS.waiting;
  }
  switch (view.gameState.kind) {
    case "InProgress":
      return COLORS.gameInProgress;
    case "GameOver":
      return COLORS.gameLost;
    case "Win":
    case "PlayerWins":
      return COLORS.gameWon;
  }
}

/** Mirrors [Game_state.to_string] plus the restart hint added for exercise 10. */
function headerText(view: GameView): string {
  if (view.room.waitingForPlayers) {
    return view.you.role === "spectator"
      ? "Waiting for players…"
      : "Waiting for another player to join…";
  }
  const state = view.gameState;
  switch (state.kind) {
    case "InProgress":
      return "";
    case "GameOver":
      return `Game over: ${state.reason}  (press 'r' to play again)`;
    case "Win":
      return "WIN!  (press 'r' to play again)";
    case "PlayerWins":
      return `Player ${state.player} wins! (${state.reason})  (press 'r' to play again)`;
  }
}

function scoreText(view: GameView): string {
  return view.score2 === null
    ? `Score: ${view.score}`
    : `P1: ${view.score}    P2: ${view.score2}`;
}

function appleColor(view: GameView): string {
  switch (view.apple.color) {
    case "Red":
      return COLORS.red;
    case "Gold":
      return COLORS.gold;
  }
}

function drawSnake(
  ctx: CanvasRenderingContext2D,
  snake: GameView["snake"],
  boardHeight: number,
  bodyColor: string,
  headColor: string,
): void {
  for (const segment of snake.tail) {
    drawBlock(ctx, segment, boardHeight, bodyColor);
  }
  drawBlock(ctx, snake.head, boardHeight, headColor);
}

export function render(ctx: CanvasRenderingContext2D, view: GameView): void {
  const { width } = canvasSize(view);
  const playAreaHeight = view.board.height * BLOCK_SIZE;

  ctx.fillStyle = headerColor(view);
  ctx.fillRect(0, 0, width, HEADER_HEIGHT);

  ctx.fillStyle = COLORS.black;
  ctx.font = "16px monospace";
  ctx.textBaseline = "top";
  ctx.fillText(scoreText(view), 8, 12);
  ctx.fillText(headerText(view), 8, 44);

  // Spectators get a corner badge so the mode is obvious without reading the status line.
  if (view.you.role === "spectator") {
    ctx.fillStyle = COLORS.spectatorBadge;
    ctx.textAlign = "right";
    ctx.fillText("SPECTATING", width - 8, 12);
    ctx.textAlign = "left";
  }

  ctx.fillStyle = COLORS.black;
  ctx.fillRect(0, HEADER_HEIGHT, width, playAreaHeight);

  // Everything below is drawn inside the play area, so shift the origin down past the
  // header once rather than offsetting every block.
  ctx.save();
  ctx.translate(0, HEADER_HEIGHT);

  drawBlock(ctx, view.apple.position, view.board.height, appleColor(view));
  drawSnake(ctx, view.snake, view.board.height, COLORS.green, COLORS.head);
  if (view.snake2 !== null) {
    drawSnake(
      ctx,
      view.snake2,
      view.board.height,
      COLORS.player2Body,
      COLORS.player2Head,
    );
  }

  ctx.restore();
}
