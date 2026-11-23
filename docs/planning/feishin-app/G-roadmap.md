# G. Implementation roadmap

Each milestone below starts after explicit approval of the package. No dates or delivery estimates are assumed. Use a single vertical slice first and record tested Feishin builds and backend-dependent behavior observed through Feishin Remote in the support matrix.

## MVP

| Order | Scope and dependency | Validation and acceptance | Primary owner and fallback |
| --- | --- | --- | --- |
| 0 | Establish baseline. Verify official Feishin v1.17.0 and an agreed development build, the desktop music source configured for testing, desktop player engine, Android target and Flutter dependency resolution. Requires approval | Capture sanitized WebSocket handshakes with and without auth, wrong auth, open with no backend, bounds and close/restart. Test stable/development queue boundary, confirm behavior, duration/position units, real artwork reachability and ack order. Freeze compatibility fixtures and support claims | Protocol and Android owners. Gate unsupported features and label incomplete combinations as unverified |
| 1 | Vertical slice: connection form, profile store, TLS/LAN transport, reconnect, app shell and live play/pause | Connect and authenticate on a physical Android device over default trusted LAN and explicitly selected WSS. Check the LAN disclosure and certificate failure behavior. Observe playback in both directions. Wrong auth halts automatic retries. Android permission denial has recovery. Wi-Fi drop or desktop restart produces disabled controls and fresh state once recovered. Profile switch cannot surface old events | Flutter/transport. Keep one active profile socket and a mock transport for regression tests |
| 2 | Complete Now Playing controls, volume, repeat, shuffle, artwork, favorite and conditional rating. Requires verified identity and command behavior | Desktop changes appear without refresh. Remote volume updates do not change phone volume. Backend rating and favorite support, metadata and duration verified. Unavailable artwork shows a placeholder and fallback background while connected playback controls remain usable. Stopped and empty states have meaningful recovery | Playback. Hide unavailable actions and keep placeholder when artwork is unsuitable |
| 3 | Catalog and paged search, play/enqueue actions, playlist picker; live queue including duplicate-safe jump, reorder, remove and clear | Test 10k-track library, one final empty page, app/network error, no configured desktop music backend and generic Subsonic sampling. Stale responses never replace a newer query. Use two copies of one song, exercise external concurrent edits and show actual resulting snapshot. Clear confirmation cancel produces zero writes. Lost acks never trigger a duplicate mutation | Catalog/queue. If backend behavior is unverified, limit promises and treat unknown operation as unconfirmed |
| 4 | Standard and deterministic waveform, core style settings and preview. Artwork/device/static gradients, light/dark and reduced motion | Test fractional and end-boundary seeks, drag vs desktop progress, same-song new occurrence, paused/stopped seek behavior, skipped tracks and network loss. Standard and waveform styles send equal targets. Generated mode and preview transfer zero audio. Verify all three background modes and fallback. Validate worst-case artwork and rapid skips | Playback/visual. Turn down visual complexity on hardware where jank exceeds target |
| 5 | Global Settings, responsive layouts, diagnostics, security and accessibility release pass | Verify a clean install opens Now Playing after setup, switching Start screen to Library changes the next fresh launch, and the choice persists across restarts. Persist other preferences and multiple profiles. Redacted logs contain no credentials/auth URL. Test permission revocation, secure backup/key loss and cross-profile cleanup. TalkBack completes connection, play/pause, seek, move queue entry and change settings. Targets ≥48 dp, 200% text, contrast 4.5:1 and 3:1 as applicable, no clipped primary actions. Profile budget at ≥95% warm frames under 16.7 ms on agreed hardware | Product, QA, platform. Use static background/reduced motion or restrict compatibility based on measurements |

## Enhanced release

| Deliverable | Dependency and risk | Acceptance and fallback |
| --- | --- | --- |
| Feasibility review for one optional real-waveform source and peak cache | After the first release, decide whether to pursue real waveforms and establish backend identity and authorization. Compare precomputed service, bounded on-device extraction and generated-only. Evaluate track codecs, progressive decode, decompression and cache limits | No network audio in Generated or standard mode and no background extraction. Rapid change and cancellation release temp files. Verify reference peaks, alignment and cache invalidation. Proposed spike thresholds on baseline Android: peaks service response p95 under 1 s on test LAN after server warmup, 512 bins staying below 16 KiB including envelope, one on-device job at a time with initial 12 MiB and 10 s hard bounds. Any case over budget falls back. Review thresholds after measuring |
| Advanced styling and transitions | Build on shared theme tokens and safe MVP drawings. Risks are clutter, contrast and raster budget | Resettable grouped Settings with working background and waveform previews. Geometry and colors remain valid at extremes; rapid skips and reduced motion pass release profile and contrast checks |
| MediaSession, system/lock controls, headset and optional active background session | Pass Media3 bridge spike and Android permission/FGS lifecycle review, including Play declaration if distribution requires it. Test real OEM devices and competing playback. Persistent session may be ineligible or unreliable | System surfaces identify the desktop session and send only supported commands while fresh. Confirm lock screen/headset behavior on published support matrix, stop promptly on disconnect, no local audio decodes or capture for these features, no fake audio focus. If the background approach fails policy or device tests, limit or defer the integration |
| Improved artwork/cache handling and Android conveniences | Evidence that users need more reliable covers or built-in shortcuts. Uncorrelated proxy can display a wrong image | Add only validated origins and identities. Consider isolated, bounded single-flight proxy experiment only if direct covers fail often and stale results can be prevented. Retain placeholders otherwise. Validate cache cap, profile purge and 100 successive track changes |

## Future considerations

- Home-screen widget with a fresh-status marker and open-app shortcut. Validate action timeouts and cold-start restrictions before enabling direct remote controls.
- Wear OS companion surfaces. Prove phone session reachability, independent lifecycle and graceful unavailability before exposing actions.
- Android Auto only with a demonstrated in-car use case, appropriate category, validated playback route and policy approval. Keep this independent of MVP.
- Optional Feishin API proposals for capability/version announcements, queue revision and conditional edits, seek correlation scoped to queue occurrence, playlist/album membership and correlated artwork. Require upstream agreement and release evidence before making product guarantees.

## Test matrix

| Level | Scenarios and evidence |
| --- | --- |
| Protocol fixture tests | Both envelope directions, absent/null/extra fields, finite numeric values, duplicate current song ID with new occurrence, malformed list item, unrecognized events, wrong request generation, stale artwork/proxy result, uncorrelated error, close 4002/4004 |
| Deterministic state and timing | Fake monotonic clock and scripted fake socket. Auth before readiness, paused and out-of-order progress, gestures during disconnect, keyboard repeated seeks, jitter cap, simultaneous desktop queue edit, no-progress list, slow live artwork and actor cancellation |
| Widget and visual | All screen states, settings migrations and reset, category/search restoration, namespace separation, landscape and tablet, predictive Back, motion disabled, 200% scale, accessibility guideline matchers and visual review |
| End-to-end | Desktop official build plus chosen development commit, both playback engines where supported, and representative desktop-configured sources before making backend-specific claims. All control and catalog requests use Feishin Remote. Test multiple clients, clear/replace, duplicate reorder, playlist rights, empty backend, malformed/unreachable artwork, trusted WSS and trusted private LAN |
| Native and field quality | Physical baseline and low-tier device, a Material You capable device, Android versions with and without relevant permission behavior, at least two OEMs before enhanced media claims, process death/Doze, notification and headset, remote metadata privacy, Android profiler/DevTools traces, memory and bandwidth |

## Risk register

| Risk | Mitigation and release consequence |
| --- | --- |
| Remote protocol is source-derived and lacks runtime capability negotiation | Establish tested desktop/backend matrix, strict outbound and tolerant inbound parser, no unsupported UI actions. Gate advanced behavior by evidence |
| Position and queue edits have no track-scoped transaction | Occurrence-aware local guards, reconcile authoritative state, single pending destructive intent, no automatic retry. Document the irreducible concurrent race |
| Album/playlist ack races fetch completion | Observe queue, acknowledge uncertainty, avoid repeat writes. Capture slow/failing backend and empty collection scenarios |
| Some covers inaccessible or credential-bearing | Constrain origins, redirects and cache metadata. Use neutral placeholder. Treat fallback as a product state |
| Cleartext and Android LAN permission create onboarding friction | Make WSS and explicit LAN choices legible, request permission in context and preserve inputs. Re-test exact distribution target |
| Real audio analysis is expensive or mismatched | Default Generated, benchmark on-device, prefer precomputed peaks where recurring. Fail cleanly and isolate credentials |
| Foreground service or Bluetooth behavior varies | Defer, test OEM/system arbitration and verify permitted lifecycle before shipping an opt-in surface |
| Visual flourishes cause jank or weak contrast | Bounded pure paint, isolate palette generation, static style fallback, contrast and performance budgets |

Support ownership: product approves scope and the first-release Feishin/device test matrix, Flutter and protocol owners publish tested behavior and release gates, Android owner validates platform integrations, and design/QA sign off on usability and offline states. Feature-level rollback for optional native or real peaks is to disable that provider/bridge while preserving in-app connection, standard timeline and generated waveform.
