import type { GameView, JoinResponse } from "./types";

/** Vite proxies /api through to the OCaml server on :8080 (see vite.config.ts). */
const BASE = "/api";

async function decode<T>(response: Response): Promise<T> {
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  return (await response.json()) as T;
}

/**
 * Claims a seat. The first two callers become players and get a token; everyone after
 * them is a spectator with no token. Called exactly once, on load.
 */
export async function join(): Promise<JoinResponse> {
  return decode<JoinResponse>(await fetch(`${BASE}/join`, { method: "POST" }));
}

/**
 * Fetches the current state. Passing a token also serves as this player's heartbeat, so
 * a player that stops polling is the same thing as a player that has left.
 */
export async function fetchState(token: string | null): Promise<GameView> {
  const query = token === null ? "" : `?token=${encodeURIComponent(token)}`;
  return decode<GameView>(await fetch(`${BASE}/state${query}`));
}

/** Forwards a keystroke. The server routes it to whichever seat the token holds. */
export async function sendKey(key: string, token: string): Promise<GameView> {
  const query = `?key=${encodeURIComponent(key)}&token=${encodeURIComponent(token)}`;
  return decode<GameView>(await fetch(`${BASE}/key${query}`, { method: "POST" }));
}
