# JSON Schema and TypeScript usage

This folder provides a **source-derived but unofficial** machine-readable description of Feishin's remote-control protocol.

| File | Purpose |
|---|---|
| `client-events.schema.json` | Standalone Draft 2020-12 JSON Schema for client → Feishin messages |
| `server-events.schema.json` | Standalone Draft 2020-12 JSON Schema for Feishin → client messages |
| `remote-protocol.schema.json` | Union schema of both message directions |
| `remote-protocol.d.ts` | Standalone, dependency-free TypeScript event and item declarations |

Each JSON Schema uses a `oneOf` discriminated union and local `$defs`, with no remote `$ref` dependencies. Validate using Draft 2020-12 support, for example Python `jsonschema` or AJV 2020.

**Partial domain typing**: `QueueSong` is only checked for `id` and `_uniqueId` and permits extra properties. This is intentional; the upstream type is the full `Song` interface plus queue fields, and the full model includes many server-specific and playback metadata fields. `SongState` has optional properties as in the upstream source. The stand-alone declarations accordingly use an index signature for `QueueSong`. Do not call these complete, generated-from-TypeScript fidelity schemas.

**Strict events**: top-level objects disallow unknown properties, matching the documented message shapes, though Feishin runtime itself is not guaranteed to reject extra fields. No numeric constraints are added for ratings because the source remote types do not define them. Volume is restricted to the effective 0–100 range after clamping; outgoing values outside this range may still be accepted at runtime and clamped.

## Example validation (Python)

```python
import json
from jsonschema import Draft202012Validator

schema = json.load(open('schemas/client-events.schema.json'))
message = {'event': 'tracks-request', 'requestId': 'q-1', 'limit': 25}
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(message)
```

## TypeScript

```ts
import type { ClientEvent, ServerEvent } from './schemas/remote-protocol';
const command: ClientEvent = { event: 'volume', volume: 50 };
const onEvent = (msg: ServerEvent) => console.log(msg.event);
```
