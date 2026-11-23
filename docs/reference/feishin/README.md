# Feishin Remote API: documentation + schemas

**Offline documentation package** · compiled 2026-11-23

Feishin's embedded remote feature exposes a **WebSocket** event protocol at the remote server (default `ws://HOST:4333/`). This package makes its message shapes easy to read, inspect, and validate.

## Contents

- `docs/API.md` — connection, authentication, complete client/server event tables, request IDs, queue, examples and caveats
- `docs/SCHEMAS.md` — schema usage notes and validation example
- `schemas/client-events.schema.json` — standalone JSON Schema for commands
- `schemas/server-events.schema.json` — standalone JSON Schema for responses/push messages
- `schemas/remote-protocol.schema.json` — combined protocol JSON Schema
- `schemas/remote-protocol.d.ts` — self-contained TypeScript type declarations
- `examples/client.mjs` — runnable Node 22+ WebSocket example
- `sources/REFERENCES.md` — official GitHub sources and discussion links
- `MANIFEST.json` — SHA-256 hashes for files in the bundle

Start at `docs/API.md` for the event reference. TypeScript users can consume `schemas/remote-protocol.d.ts`; JSON Schema tools can use `schemas/client-events.schema.json` and `schemas/server-events.schema.json`.

**Provenance:** These are newly authored, **unofficial** documentation and schema derivatives based on Feishin's **development branch**, inspected 2026-11-23. They are not a verbatim copy of the repo and are not guaranteed compatible with every released Feishin version. The `QueueSong`/`Song` payload validation is deliberately partial; inspect the linked upstream source for its complete domain shape.
