# Upstream sources

Reviewed on 2026-11-23. Source branch: `development` (rolling branch, not a pinned release). All URLs are from the Feishin public GitHub repository.

- **Primary protocol types:** https://github.com/jeffvli/feishin/blob/development/src/shared/types/remote-types.ts
- **WebSocket server and event handling:** https://github.com/jeffvli/feishin/blob/development/src/main/features/core/remote/index.ts
- **Playback enums and SongState:** https://github.com/jeffvli/feishin/blob/development/src/shared/types/types.ts
- **QueueSong and full Song domain types:** https://github.com/jeffvli/feishin/blob/development/src/shared/types/domain-types.ts
- **Discussion on WebSocket API and auth:** https://github.com/jeffvli/feishin/discussions/967
- **API documentation request:** https://github.com/jeffvli/feishin/issues/763

**Note:** The package contains newly authored documentation and TypeScript/JSON Schema descriptions, NOT a verbatim archive of the Feishin source repository. Fetch the linked upstream files to obtain the complete original TypeScript and implementation. An OpenAPI file was not provided because this is a WebSocket protocol.
