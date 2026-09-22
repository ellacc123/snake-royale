# Networked two-player snake: design notes

This document explains why the networked version of the game is built the way it is. Each
section states a decision, the alternatives that were rejected, and the trade-off
accepted. The last two sections cover known weaknesses and likely interview questions.

## Topology

```
browser A (TS)                OCaml server :8080              browser B (TS)
  join once  ────────────────→  seat 1 + token                ←──────────── join once
  poll 50ms  ────────────────→  Game.t + 100ms Async clock ←──────────────  poll 50ms
  w/a/s/d    ────────────────→  routes by token → snake 1/2 ←──────────────  w/a/s/d
```

One process holds one game. Browsers hold no game logic at all: they draw the state they
are given and forward keystrokes.

## Decisions

### 1. The server is authoritative; the client simulates nothing

The browser never advances the snake, never decides a collision, never spawns an apple. It
renders `/api/state` and posts keys.

**Why.** With two clients, any logic duplicated on both sides has to agree, forever, or the
two screens diverge. Keeping one copy of the rules removes the entire class of
desynchronisation bugs. It also means the OCaml exercise code stays the single source of
truth — the same `Game.step` that the terminal build uses.

**Rejected.** Client-side prediction with server reconciliation. That is what real-time
games do to hide latency, but it requires rollback and replay, and over localhost or a LAN
the latency it hides is a few milliseconds.

**Trade-off.** Every input costs a round trip. At 100ms per tick this is invisible locally
and would become noticeable over a slow WAN.

### 2. Seats and tokens, not connections or cookies

`POST /api/join` assigns the first caller seat 1, the second seat 2, and hands each an
opaque 32-hex-character token. Everyone after that is a spectator with no token. Every
later request carries the token; the server maps token → seat → snake.

**Why.** HTTP polling has no connection identity — each request is independent, so the
server needs something in the request to say who is asking. A token is the smallest thing
that works.

**Rejected.**
- *Cookies / sessions.* A cookie is shared by every tab in a browser profile, so two
  windows on one machine would be the same player. That breaks the stated requirement of
  testing with two windows side by side.
- *IP address.* Two windows on one machine share an IP. Two players behind one NAT share
  an IP. Not an identity.
- *Client-chosen player number.* Trivially spoofable, and two clients would both pick 1.

**Trade-off.** Tokens are bearer credentials: anyone who obtains one can drive that snake.
For a LAN game that is the right level of security. See *Weaknesses*.

### 3. The token lives in a module-level variable, never in storage

`web/src/main.ts` keeps the join response in a `let session` and deliberately does not
touch `localStorage` or `sessionStorage`.

**Why.** `localStorage` is shared across tabs of the same origin, so two windows would
reuse one token and count as one player. `sessionStorage` is per-tab and would *almost*
work, but it survives reloads, which means a reloaded tab would try to resume a seat the
server may have already given away.

**Trade-off.** A page reload loses the seat and rejoins as a new player, which is the
correct behaviour here but would be wrong for a game you expect to reconnect to. See
*What I would do next*.

### 4. Parameters travel in the query string, not a request body

`/api/key?key=w&token=…`, `/api/state?token=…`.

**Why.** The constraint is a hand-rolled JSON *writer* and no new dependencies. Accepting
a JSON body would mean also hand-rolling a JSON *parser*, which is significantly more code
and much more error-prone than the writer — the writer only has to emit a fixed shape,
while a parser has to handle anything a client sends. Query parameters are parsed for free
by `Uri.get_query_param`.

**Trade-off.** Tokens end up in URLs, which are logged by proxies, browser history and
server access logs far more readily than bodies are. With a JSON parser or a header-based
scheme the token would stay out of the URL. This is the weakest point of the design and I
would change it first if the game left the LAN.

### 5. The state poll *is* the heartbeat

There is no separate `/api/heartbeat`. Any request carrying a valid token refreshes that
seat's `last_seen`.

**Why.** The client already has to poll to render. A player who is still polling is by
definition still there, so a second liveness mechanism would be redundant state that can
disagree with the first. Fewer endpoints, fewer failure modes.

**Trade-off.** Liveness is coupled to rendering. A client that paused rendering but still
"wanted" to play — a backgrounded tab, where browsers throttle timers — looks dead. For
this game that is acceptable: a player who cannot see the board is not playing.

### 6. Three seconds, and where that number comes from

The client polls every 50ms; the server drops a silent seat after 3s.

**Why that ratio.** 3s is ~60 consecutive missed polls. A dropped packet, a garbage
collection pause, or a slow frame costs one or two polls, so the timeout cannot be tripped
by ordinary jitter — it takes a genuine disconnection. Conversely 3s is short enough that
the surviving player is not left staring at a frozen board.

**Why not shorter.** At 500ms a brief stall would eject a live player, which is a much
worse failure than waiting an extra second.

**Why not longer.** The other player is blocked the whole time, since the game stops
ticking as soon as a seat empties.

The value is overridable with `SNAKE_HEARTBEAT_SECONDS` so the behaviour can be tested in
under a second instead of waiting three seconds per run. That is the only reason the knob
exists; it is not a gameplay setting.

### 7. The clock runs, but the game does not tick until both seats are filled

`start_ticking` fires every 100ms regardless. Inside, it first expires silent seats, then
steps the game only if both seats are occupied.

**Why keep the clock running while waiting.** Timeout detection has to happen even when
nobody is playing — otherwise a player who joins and immediately closes their laptop would
hold seat 1 forever. Separating "the clock ticks" from "the game advances" gives one
scheduler callback that does both jobs.

**Why not tick the game.** If the game advanced while waiting, the first player would
arrive to find their snake had already driven into a wall. Starting the simulation only
when both players are present makes the match fair.

Keys are also ignored while waiting, so a lone player cannot warm up by steering their
snake around an unstarted game.

### 8. Filling the second seat starts a fresh game

**Why.** Otherwise a joiner inherits whatever position the previous occupant of that seat
left behind — possibly a snake that is one square from a wall, or a lost game. A new match
should start from a known state.

### 9. A forfeit reuses `Game_state.Player_wins`

Dropping a player calls `Game.declare_winner ~player ~reason:"opponent disconnected -
forfeit"`.

**Why.** Exercise 09 already introduced a state meaning "player N won, and here is why the
other lost". A disconnection is just another reason. Adding a separate `Forfeit` variant
would force every `match` on game state — in `run.ml`, the renderer, the server — to grow
a case that behaves identically to `Player_wins`.

**Trade-off.** The client distinguishes a forfeit from a crash only by reading the reason
string, which is presentation logic keyed off prose. If anything ever needed to *act*
differently on a forfeit, this would need a real variant.

### 10. A finished game is never overwritten by a forfeit

`forfeit` checks that the state is `In_progress` first.

**Why.** If both snakes have already crashed and the result is a draw, a player closing
their tab afterwards should not retroactively convert that draw into a win.

**Consequence worth knowing.** A disconnected player's snake keeps moving — the server
steps both snakes regardless of who is connected. On the default board a snake travelling
in a straight line leaves the board in about 2.3s, which is *less* than the 3s timeout. So
in practice a disconnection usually resolves as an ordinary out-of-bounds loss before the
forfeit path is reached. The forfeit is the backstop for the case where the abandoned
snake happens to survive longer than the timeout. An alternative design — freezing or
removing a disconnected player's snake immediately — would make the forfeit the primary
path; I kept the simpler rule because it needs no special case in `Game.step`.

### 11. Both players press w/a/s/d; the server decides whose snake that is

`Game.handle_key` (shared keyboard: wasd + ijkl) is kept for the terminal build.
`Game.handle_key_for_player ~player` is the networked one: it applies the wasd mapping to a
named player.

**Why two functions.** They answer different questions. On one keyboard the *keystroke*
identifies the player. Over the network the *connection* identifies the player, and both
players quite reasonably want the same comfortable keys. Overloading one function with a
mode flag would hide that distinction.

### 12. Global mutable state with no locking

`room` is a single mutable record at module scope. There are no mutexes.

**Why that is safe.** Async is cooperative and single-threaded: a callback runs to
completion and can only be interrupted where it yields, at a bind on a deferred. Every
mutation of `room` in the handler happens synchronously, before the response deferred is
constructed, so no two requests can interleave inside a read-modify-write. The tick
callback runs on the same scheduler for the same reason.

**Where this would break.** Any `let%bind` inserted in the middle of a
read-modify-write sequence — reading the seats, awaiting something, then writing them —
would introduce exactly the race the single-threaded model otherwise rules out. That is
the thing to watch for when extending the handler, and it is why the mutations are grouped
at the top of `handler` rather than scattered through it.

### 13. One room, not a lobby

**Why.** The requirement is two computers playing one game. Rooms, matchmaking and
per-room lifecycles are a different feature, and `room` being a single global is the
honest expression of "this server hosts one match". Making it a `Hashtbl` of rooms keyed
by id is a contained change — the state is already grouped in one record — but it would
add a lifecycle problem (when is an empty room collected?) that nothing currently needs.

## Weaknesses I would raise before an interviewer does

- **Tokens in URLs.** Logged by proxies and history. A header or body would be better; the
  no-JSON-parser constraint pushed them into the query string.
- **Token comparison is not constant time.** `String.equal` short-circuits, so it leaks
  timing information. Irrelevant against a LAN opponent, wrong for anything public.
- **Tokens come from `Random`, not a CSPRNG.** `Random.self_init` seeds from the clock, so
  tokens are unguessable by a casual observer but not cryptographically strong. 128 bits of
  hex is the right *shape*; the entropy behind it is not.
- **Wall-clock timeouts.** `Time_float.now` is wall clock, so an NTP step could expire a
  live player or reprieve a dead one. A monotonic clock is the correct source for
  durations.
- **No reconnection.** A reload is a new identity; the old seat lingers until it times out,
  so reloading inside 3s can leave you spectating your own game.
- **Spectators cannot be promoted.** When a seat frees, a watching client stays a spectator
  until it reloads. The client knows the seat is free — `room.seat1Taken` is in every state
  response — so auto-rejoining would be a small change.
- **No back pressure.** Two clients polling at 20Hz is nothing, but nothing stops a
  thousand.

## What I would do next, in order

1. **Server-sent events or WebSockets** to replace polling. The state document is already
   the unit of transfer, so this is a transport swap, not a redesign: push the same JSON on
   each tick, keep the POST for keys. Liveness then comes from the connection itself and
   the heartbeat logic disappears.
2. **Reconnection.** Let a client present its old token after a reload and reclaim the seat
   if it has not been reassigned.
3. **Multiple rooms**, keyed by an id in the path, with empty-room collection.
4. **Move the token out of the URL**, which at that point costs only a small JSON reader or
   a header lookup.

## Running it

```
dune exec server/server.exe        # terminal 1
cd web && npm run dev              # terminal 2
```

Open <http://localhost:5173> in two windows. The first two get seats, anyone else
spectates. Both players steer with w/a/s/d; `r` restarts. Player 1 is green, player 2 cyan,
and the status line tells each client which one it is.

To exercise the timeout quickly:

```
SNAKE_HEARTBEAT_SECONDS=0.5 dune exec server/server.exe
```

## API

| Method | Path | Parameters | Returns |
| --- | --- | --- | --- |
| `POST` | `/api/join` | — | `{role, seat, token}`; `role` is `player` or `spectator` |
| `GET` | `/api/state` | `token` (optional) | full state document; also a heartbeat |
| `POST` | `/api/key` | `key`, `token` | full state document |

The state document carries `you` (this caller's role and seat), `room` (which seats are
taken, whether the game is waiting), the board, both snakes, both scores and the game
state. `web/src/types.ts` is the authoritative description of that shape.
