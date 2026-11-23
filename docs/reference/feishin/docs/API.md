# Feishin Remote API — WebSocket reference

**Unofficial documentation bundle · reviewed 2026-11-23 · upstream branch: `development`**

## Protocol and endpoint

The desktop app embeds an HTTP server for its remote web UI and a **WebSocket server** for remote control. The default configured port is **4333**; the root WebSocket URL is normally `ws://HOST:4333/` when the remote feature is enabled. This is not a REST API: messages are JSON text over a WebSocket.

- Client → Feishin: JSON objects contain top-level `event` and any event-specific fields, *not* a uniform `data` wrapper.
- Feishin → client: JSON objects contain `event` and `data`.
- There is no `get-state` client command. On connection (if unauthenticated access is enabled) or on successful authentication, the server sends an initial state snapshot automatically; queue updates are then pushed.

## Authentication

If both configured username and password are empty, an open WebSocket is authenticated immediately. Otherwise, the client sends this message after connecting:

```json
{"event":"authenticate","header":"Basic <base64(username:password)>"}
```

Use real Base64 bytes in place of the example marker. The remote server checks the supplied credentials and then sends initial state. The server times out unauthenticated connections after approximately 10 seconds and closes bad credentials with WebSocket close code **4004**. A server restart/settings reset can close with **4002**.

**Security:** WebSocket Basic authentication transmits reversible credentials; only use the default `ws://` transport on networks you trust. Use a properly configured `wss://` TLS reverse proxy for remote/untrusted networks; avoid exposing the service directly to the Internet.

## Client → server events

| Event | Fields | Purpose |
|---|---|---|
| `authenticate` | `header` (string) | Authenticate an existing WebSocket connection |
| `play` | — | Resume playback |
| `pause` | — | Pause playback |
| `next` | — | Skip to next track |
| `previous` | — | Go to previous track |
| `shuffle` | — | Toggle shuffle |
| `repeat` | — | Cycle repeat setting |
| `proxy` | — | Request current song artwork as base64 |
| `volume` | `volume` (number) | Set volume (0–100) |
| `position` | `position` (number) | Seek in seconds |
| `favorite` | `id` (string), `favorite` (boolean) | Set current-song favorite status (matching current song ID) |
| `rating` | `id` (string), `rating` (number) | Set current-song rating (matching current song ID) |
| `play-radio` | `id` (string) | Play a radio station |
| `play-track` | `id` (string), `playType?` (Play), `requestId?` (string) | Start or queue a track |
| `play-album` | `id` (string), `playType?` (Play), `requestId?` (string) | Start or queue an album |
| `play-playlist` | `id` (string), `playType?` (Play), `requestId?` (string) | Start or queue a playlist |
| `play-track-radio` | `id` (string), `playType` (Play), `requestId?` (string) | Start track-generated radio using required playType |
| `clear-queue` | `requestId?` (string) | Clear queue |
| `add-to-playlist` | `playlistId` (string), `songId` (string), `requestId?` (string) | Add song to playlist |
| `queue-jump` | `uniqueId` (string) | Jump to unique queue item |
| `remove-from-queue` | `uniqueId` (string) | Remove unique queue item |
| `reorder-queue` | `edge` (bottom | top), `targetUniqueId` (string), `uniqueId` (string) | Move queue item relative to target |
| `tracks-request` | `requestId` (string), `limit?` (integer), `searchTerm?` (string), `startIndex?` (integer) | Browse/search tracks |
| `albums-request` | `requestId` (string), `limit?` (integer), `searchTerm?` (string), `startIndex?` (integer) | Browse/search albums |
| `playlists-request` | `requestId` (string), `limit?` (integer), `searchTerm?` (string), `startIndex?` (integer) | Browse/search playlists |
| `radio-request` | `requestId` (string), `limit?` (integer), `searchTerm?` (string), `startIndex?` (integer) | Browse/search radio stations |

## Server → client events

| Event | Fields | Purpose |
|---|---|---|
| `accent-color` | `data` (object) | Accent color theme |
| `confirm-queue-changes-setting` | `data` (boolean) | Whether confirmation is enabled |
| `error` | `data` (string) | Error string |
| `favorite` | `data` (object) | Favorite status changed |
| `rating` | `data` (object) | Rating changed |
| `operation-ack` | `data` (object) | Ack/error for an ackable requestId |
| `playback` | `data` (PlayerStatus) | Playback status |
| `position` | `data` (number) | Playback position |
| `proxy` | `data` (string) | Base64 image data |
| `queue-state` | `data` (object) | Current queue snapshot |
| `radio-status` | `data` (union) | Active radio status |
| `repeat` | `data` (PlayerRepeat) | Repeat setting |
| `shuffle` | `data` (boolean) | Shuffle state |
| `song` | `data` (union) | Current full QueueSong or null |
| `state` | `data` (SongState) | Initial/current SongState |
| `volume` | `data` (number) | Current volume |
| `tracks-response` | `data` (object) | Tracks listing result |
| `albums-response` | `data` (object) | Albums listing result |
| `playlists-response` | `data` (object) | Playlists listing result |
| `radio-response` | `data` (object) | Radio listing result |

## Pagination and correlation

`tracks-request`, `albums-request`, `playlists-request` and `radio-request` require a `requestId` string. Optional request fields: `limit`, `startIndex`, `searchTerm`. Each matching `*-response` has `data.requestId`, `data.items`, and `data.hasMore`. Responses go only to the originating connection. Allocate distinct request IDs for concurrent requests.

For `add-to-playlist`, `clear-queue`, `play-track`, `play-album`, `play-playlist`, and `play-track-radio`, providing an optional `requestId` requests an `operation-ack` with `data.requestId`. Missing `data.error` denotes success. Acknowledgements are sent to the originating client. Other client commands do not promise this acknowledgement.

## Queue model

The server pushes `queue-state` messages with `data.currentUniqueId` and `data.items`, where each entry is a small `RemoteQueueItem` containing `id`, `uniqueId`, `name`, `artistName`, `album`, `imageUrl`, and `duration`. For queue moves, jumps, and removal use **`uniqueId`**, not the library track `id`.

## Value types

- `Play`: `index`, `last`, `lastShuffle`, `next`, `nextShuffle`, `now`, `shuffle`.
- `PlayerRepeat`: `all`, `none`, `one`.
- `PlayerStatus`: `paused`, `playing`, `stopped`.
- `volume`: percentage (0–100); remote server clamps values to that range.
- `position`: playback position in seconds. The exact scale of `duration` comes from the upstream domain model; do not assume it matches a client UI formatting unit without testing.
- `QueueSong` and `SongState.song` refer to Feishin domain types. The bundled JSON Schema validates the known stable envelope and key fields while allowing extra Song properties; it is **not an exhaustive Song validator**.

## Examples

### Simple playback control

```json
{"event":"pause"}
```

### Search tracks

```json
{"event":"tracks-request","requestId":"tracks-001","searchTerm":"Miles","startIndex":0,"limit":25}
```

Response shape:

```json
{"event":"tracks-response","data":{"requestId":"tracks-001","hasMore":false,"items":[]}}
```

### Enqueue a track and wait for acknowledgement

```json
{"event":"play-track","id":"song-id","playType":"next","requestId":"op-001"}
```

```json
{"event":"operation-ack","data":{"requestId":"op-001"}}
```

## Implementation notes and limitations

These definitions are **an unofficial, source-based reference**, not a published Feishin protocol specification. The implementation is authoritative for runtime behavior. Branch `development` changes over time, and installed releases can differ. The TypeScript source defines a wider `Song` domain type than the standalone bundled schema expresses. Although the HTTP server has UI routes and `/credentials`, the playback control protocol is WebSocket-based.

See [Schemas](SCHEMAS.md), [Sources](../sources/REFERENCES.md), and [Runnable Node.js client](../examples/client.mjs).
