import { fetchState, join, sendKey } from "./api";
import { canvasSize, render, seatColorName } from "./render";
import type { GameView, JoinResponse } from "./types";

/**
 * Entry point. This is the browser's answer to `src/run.ml`, with two differences:
 * the 100ms game clock runs on the server, so there is no step loop here; and this
 * client has to claim a seat before it can play.
 *
 * Both players press w/a/s/d at their own keyboard. The server decides whose snake that
 * means from the token we send, so there is no per-seat key mapping in the browser.
 */

const CONTROL_KEYS = new Set(["w", "a", "s", "d", "r"]);

/**
 * How often we poll. The server ticks every 100ms and drops silent players after 3s, so
 * 50ms both keeps the board current and leaves ~60 missed polls of slack before a real
 * network problem looks like a disconnection.
 */
const POLL_INTERVAL_MS = 50;

/**
 * The session lives in a module-level variable and deliberately never touches
 * localStorage or sessionStorage: two windows on one machine have to count as two
 * different players, and storage would make them share a seat.
 */
let session: JoinResponse | null = null;

function required<T>(value: T | null, what: string): T {
  if (value === null) {
    throw new Error(`snake: expected ${what}`);
  }
  return value;
}

const canvas = required(
  document.querySelector<HTMLCanvasElement>("#game"),
  "a #game canvas",
);
const status = required(
  document.querySelector<HTMLParagraphElement>("#status"),
  "a #status element",
);
const ctx = required(canvas.getContext("2d"), "a 2d canvas context");

function statusText(view: GameView): string {
  if (view.you.role === "spectator") {
    return "Spectating — both seats are taken. Reload once a seat frees up.";
  }
  const seat = view.you.seat;
  const who = `You are Player ${seat} (${seatColorName(seat)})`;
  if (view.room.waitingForPlayers) {
    return `${who} — waiting for another player to join…`;
  }
  if (view.gameState.kind === "InProgress") {
    return `${who} — w/a/s/d to steer · r to restart`;
  }
  return `${who} — press r to play again`;
}

function draw(view: GameView): void {
  const { width, height } = canvasSize(view);
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
  render(ctx, view);
  status.textContent = statusText(view);
  status.classList.remove("error");
}

function showError(error: unknown): void {
  status.textContent =
    "Can't reach the OCaml server on :8080 — is `dune exec server/server.exe` running? " +
    `(${String(error)})`;
  status.classList.add("error");
}

window.addEventListener("keydown", (event) => {
  const key = event.key.toLowerCase();
  if (!CONTROL_KEYS.has(key)) {
    return;
  }
  event.preventDefault();
  // Spectators have no token, so there is nothing to send on their behalf.
  const token = session?.token ?? null;
  if (token === null) {
    return;
  }
  sendKey(key, token).then(draw).catch(showError);
});

// One request in flight at a time: if a tick comes round while we're still waiting, skip
// it rather than queueing up requests the server would answer with stale-by-then state.
let inFlight = false;

function poll(): void {
  if (inFlight) {
    return;
  }
  inFlight = true;
  fetchState(session?.token ?? null)
    .then(draw)
    .catch(showError)
    .finally(() => {
      inFlight = false;
    });
}

async function start(): Promise<void> {
  session = await join();
  poll();
  window.setInterval(poll, POLL_INTERVAL_MS);
}

start().catch(showError);
