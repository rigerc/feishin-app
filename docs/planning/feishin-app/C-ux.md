# C. UI/UX design plan

## Direction and research

Use a quiet Material 3 shell for browsing and editing, with most of the visual character concentrated in Now Playing. The phone shows which desktop it controls and what is confirmed there. A warm cover and soft color fields can give the player a distinct identity while library titles, queue positions and controls stay high contrast. Spotify Connect demonstrates the value of an explicit playback target. Apple Music for Android documents a distinction between playing a selection and organizing Up Next. Material guidance supports navigation and content reflow based on available space. Apply those interaction patterns with original layouts and assets. [Spotify Connect](https://support.spotify.com/us/article/spotify-connect/) · [Apple Music queue](https://support.apple.com/en-ie/109336) · [Material navigation](https://m3.material.io/components/navigation-bar/overview) · [Flutter adaptive guidance](https://docs.flutter.dev/ui/adaptive-responsive/general)

### Navigation options

| Pattern | Fit for feishin-app |
| --- | --- |
| Player-first with a library button and no persistent navigation | Fast playback entry. Queue/library work becomes harder to switch between and loses visible orientation |
| Now Playing, Library, Queue and Settings as four equal tabs | Every view is visible. Player and mini-player duplicate entry, and preferences compete with frequent content actions |
| Library and Queue as peer destinations, mini-player opens full Now Playing, Settings via top bar | Two distinct working contexts preserve independent scroll/search. Persistent mini-player gives immediate playback access, and full player has room for artwork and one-handed controls. **Recommended** |

Navigation map. Linked surfaces indicate entry paths. On tablets, the pane may occupy the full-player route's role without changing saved branch state.

```text
First launch / no profile → Connect to Feishin → Test → Save and connect
Returning profile         → Start screen preference (Now Playing or Library) → Connect or show recovery

Connected or read-only shell
├─ Library → Tracks | Albums | Playlists → Search in selected category
│             └─ Item actions → Play / Queue / Existing playlist picker
├─ Queue → Current occurrence / upcoming / earlier → Row actions / Clear
├─ Mini-player → Now Playing → Queue, Volume, Track details / Rating
└─ Settings → Connections → Profiles → Add / Edit / Switch / Remove
             → Appearance, Player background, Waveform, Playback controls
             → Android integration, Storage and caching, Diagnostics and About
```

On a fresh launch with a saved profile, or after first-time connection setup, open the configured start screen. Default to Now Playing. Settings → Appearance → Start screen offers Now Playing and Library. Preserve the active route when resuming the same task. Keep Library reachable when Now Playing is empty or reconnecting. Mini-player appears when a track exists and can open Now Playing via cover/title or explicit accessibility action. Pause/play is its single quick action. Remember active branch for the session. From Now Playing, Queue opens the queue flow with back returning to the player, distinct from switching root destinations. Settings stays one top-bar action away on Library and Queue and is reachable via the player overflow. Android back dismisses the top overlay, clears search focus or exits submitted search, then pops the current route. At shell root, system back exits according to Android conventions. Re-selecting a branch may scroll to top on a second tap only after user testing. Ahead-of-time route pop state supports predictive back, with dirty-profile discard confirmation only when needed. [Predictive back](https://docs.flutter.dev/release/breaking-changes/android-predictive-back)

## Primary flows

| Job | Flow | Recovery and feedback |
| --- | --- | --- |
| Connect a desktop | Enable desktop Remote Control → enter name, host/port and transport → optionally enter credentials → Test connection → Save and connect | Preserve inputs on failure. Request Android local-network permission in context, show distinct certificate or credential error if known, support Android settings after denial. Successful test shows profile plus feedback if desktop library is unavailable. No automatic pairing |
| Resume playback from phone | Open app to Now Playing, or expand the mini-player if in Library → see desktop name and track → play/pause → observe confirmation | Button responds visually at once, pending indicator is narrow. Lost connection freezes progress and disables action. A manual Connect action restores state |
| Browse and add an album | Library → Albums → search or scroll → More → Play next / Add to queue | Show pending briefly and update action only after snapshot evidence. If unclear, provide View queue. Keyboard dismissal keeps the query and results |
| Replace queue | Choose Play now → confirmation when desktop policy requires it → send once → view new playback and queue | Copy says the queue will be replaced. Default focus is Cancel, and a stale profile or changed queue invalidates the confirmation before dispatch |
| Add a track to a playlist | Track overflow → Add to playlist → paged searchable picker → select and confirm if needed → mutation ack | Show playlist name feedback. Backend may reject editing. Keep picker context and offer another selection. Late/uncertain submission never retries automatically |
| Seek precisely | Open player → tap/drag seekbar or use increase/decrease controls → preview → release → reconcile | Preview owns the thumb while dragging. Track change cancels with a brief status if useful. Unconfirmed seek returns to fresh desktop position |
| Manage queue | Queue or player shortcut → jump by tapping a row, or use grip/menu to move/remove → snapshot reconciles | Label active and duplicate occurrences. Provide Move up/Move down and exact row semantics. Clear and active-track removal are explicit confirmations |
| Customize | Settings → Background / Waveform → interact with live preview → changes persist → Reset in subsection | Sample previews work offline. Disabled choices explain capability or permission requirements. High contrast and reduced motion always take precedence |

## Compact wireframes and specifications

Proportions and sample text are illustrative. The controls below include labels for review. The production design uses short labels and accessible names.

```text
CONNECT / PROFILES         NOW PLAYING
┌──────────────────────┐  ┌──────────────────────┐
│ Connect to Feishin   │  │ ↓  Studio desktop  ⋯ │
│ Enable Remote Control│  │ ┌──────────────────┐ │
│ on your desktop.     │  │ │                  │ │
│ Profile name         │  │ │   square cover   │ │
│ Host         Port    │  │ │                  │ │
│ Transport  [LAN ▾]   │  │ └──────────────────┘ │
│ Authentication   ▾   │  │ After the Rain    ♡  │
│ Username     ···     │  │ Mira Vale · Nocturne │
│ Password        ◉    │  │ ▂▃▅▆▃▅▆▇▃▅▅▂▃▅▃▂   │
│ [ Test connection ]  │  │ 1:24            3:48 │
│ Status / recovery    │  │ ⤨   │◀  [ Ⅱ ] ▶│  ↻  │
│ [ Save and connect ] │  │ [Volume]     [Queue] │
│ Saved profiles       │  │                      │
└──────────────────────┘  └──────────────────────┘

LIBRARY                    QUEUE
┌──────────────────────┐  ┌──────────────────────┐
│ Library    Studio ⚙  │  │ Queue      Studio ⋯  │
│ [ Search albums    ] │  │ Now playing          │
│ Tracks Albums Lists  │  │ ▣ After the Rain     │
│ ┌────┐     ┌────┐     │  │ Upcoming             │
│ │art │     │art │     │  │ ▣ Blue Hour     ⋯ ≡  │
│ └────┘     └────┘     │  │ ▣ Lumen         ⋯ ≡  │
│ Album ⋯    Album ⋯   │  │ ▣ Blue Hour     ⋯ ≡  │
│ Artist     Artist    │  │ Earlier in queue  ▾  │
│ ┌────┐     ┌────┐     │  │                      │
│ [loading next page]  │  │ [scrolling list]     │
│ ▣ After the Rain Ⅱ   │  │ ▣ After the Rain Ⅱ   │
│ [Library]    Queue   │  │ Library    [Queue]   │
└──────────────────────┘  └──────────────────────┘

SETTINGS                   WAVEFORM SETTINGS
┌──────────────────────┐  ┌──────────────────────┐
│ ← Settings           │  │ ← Waveform     Reset │
│ Connections          │  │ Live preview         │
│ Studio desktop    ›  │  │ ▃▅▃▅▇▅▆▃▁▅▅▃▁▅▃▂   │
│ Appearance        ›  │  │ 0:45            3:48 │
│   Start screen       │  │                      │
│ Player background ›  │  │ Style    Waveform ▾  │
│ Waveform          ›  │  │ Source   Generated ▾ │
│ Playback controls ›  │  │ Density      Medium  │
│ Android integration ›│  │ Colors     Theme  ›  │
│ Storage and cache ›  │  │ Haptic on release □  │
│ Diagnostics & About ›│  │ Advanced          ›  │
└──────────────────────┘  └──────────────────────┘

DISCONNECTED SHELL         PLAYLIST PICKER
┌──────────────────────┐  ┌──────────────────────┐
│ Library     Studio ⚙ │  │ Add to playlist    × │
│ Disconnected         │  │ After the Rain       │
│ [Retry] [Profiles]   │  │ [ Search playlists ] │
│ Last known results   │  │ ▣ Late Night        › │
│ [ read-only rows ]   │  │ ▣ Sunday Rotation  › │
│ ▣ Last track   ─     │  │ [page status]        │
│ [Library]    Queue   │  │ [Cancel]             │
└──────────────────────┘  └──────────────────────┘
```

- **Connection and profiles.** Focus host then port in keyboard order, show default port, support bare host/IP including IPv6 or an advanced complete endpoint for proxy paths. Preselect trusted local network for new profiles and offer encrypted WSS alongside it. Explain that local network mode uses an unencrypted connection before the first attempt. Password is obscured with reveal toggle. Retain failed input in memory while the form is open. Provide per-profile reconnect setting, Save credentials choice, status text, edit/delete and one active profile. Confirm deleting the active profile and stop its session. First-launch screen describes opening Feishin Remote Control and joining the same reachable network.
- **Now Playing.** Top remote-target label and collapse icon, centered cover, then wide metadata row with favorite. One tappable overflow contains Track details and rating where supported. Use a bottom-reachable seek zone, time labels, then one large play/pause with adjacent previous/next and small toggle accents for repeat and shuffle. Volume opens a bounded control sheet labeled Desktop volume, with current percentage and continuous local preview. Queue shortcut stays visible beside Volume. Avoid tying artwork size to text overflow. Missing cover uses the same frame with a placeholder and the safe background fallback. Playback controls keep their position and remain available if the desktop is connected. When no known track, show idle controls as unavailable and one Browse library action.
- **Library.** One scoped search with configurable keyboard actions, cancel/clear text and typed category. Tracks use artwork rows with title, artist/album, duration and menu. Albums use responsive two-up tiles on compact phones with title, artist and optional year; columns yield to larger text. Playlists use rows with cover, item count and actions. Album and playlist taps open summary/action sheets using available fields. Contents are available only through a future integration. Start with a 30-item request, debounce text, safely append with end/retry footer and retain scroll. No fake artist search or global search tab.
- **Queue.** Pin current occurrence summary when scrolling if space allows. Show ordered upcoming entries with labels and optional collapsed preceding items. If current ID is unknown, show desktop order without claiming a position. Drag handles are primary for rearranging and contextual Move up / Move down provide equivalents. Disable conflicting edit while an operation or transient drag is pending. Stable occurrence keys preserve semantics through duplicates and moves. Clear via overflow and confirm with current context. For active removal, explain the desktop may skip or stop, pending compatibility checks. Passive update feedback is brief and never steals focus.
- **Settings.** Connections manages profiles and reconnect. Appearance includes the persisted start-screen choice, System/Light/Dark, device palette or static app theme, reduce motion and readable density defaults. Player background includes source, darkening and motion defaults with preview. Waveform holds style and data source, geometry, colors, smoothing, playhead, haptics and preview. Playback controls holds confirmation behavior with desktop ask as a minimum for replacement, seek steps and volume presentation. Android integration describes supported controls and opt-in when released. Storage has artwork/peaks usage and selective deletion. Diagnostics & About includes last valid state age, connection test and redacted export, version and licenses. Expose advanced rows through subsection navigation at large text sizes. Technical settings have concise consequence text.

### State designs

| State | Presentation and recovery |
| --- | --- |
| First load | Fixed geometry placeholders and loading label; respect reduced motion. Replace the relevant region only |
| Connecting / reconnecting | Inline informative status, connection target and cancel/manual retry. Cached last view is marked read-only. Resume after accepted snapshot |
| Authentication failed | “Check the username and password in Feishin Remote Control.” Preserve edits and disable automatic retries |
| Invalid address, TLS, network or permission | Inline specific error when known. Offer Edit connection, Retry or Open Android settings. Keep secrets and raw URLs out of messages |
| Empty library, no results, no queue | No results suggests changing query. Empty library suggests refreshing or checking desktop backend. Empty queue offers Browse library. Distinguish no observed queue from known empty queue |
| Failed artwork / absent duration | Stable cover placeholder and static tonal fallback. Show elapsed where available, lock scrubber if range unknown |
| Unsupported action | Omit permanent unsupported items. For temporarily unavailable actions expose a concise explanatory row or disabled action with accessible reason |
| General error or edit conflict | Contextual retry for reads. For uncertain writes say “Check the desktop queue” and keep one inspect action. Present corrected state without focus jumps |

## High-fidelity direction

| Surface | Material and layout |
| --- | --- |
| Now Playing | Edge-to-edge atmospheric palette with anchored foreground contrast. Cover around the top middle, 16–24 dp corner radius, width responsive to available height. Track title uses 28/34 sp, weight 650–700, artist 16/24 sp. Filled 64 dp play control is the strongest focal point below the cover. Accent played bars and selected toggles. Secondary transport icons are high contrast on tonal circular targets with at least 48 dp hit areas |
| Library | Matte neutral surface with minimal elevation, 24/32 sp headline, 16/24 sp item titles and 14/20 sp secondary metadata. Art grid has consistent 1:1 crop, 16 dp radius and 12–16 dp gaps. Search is a tonal surface with visible focus and clear action. Use dividers sparingly on list rows |
| Queue | Same shell, current row on secondary container with play-state icon and “Now playing” label. Upcoming is a flat list, 56–72 dp per row before text scaling, with 40–48 dp art and visible grip. Active state includes text/icon beyond color |
| Settings | Flat rows on M3 surfaces with grouped headings, tonal regions reserved for previews and critical connection state. Use Material switches, inline summaries, 56 dp minimum row and purposeful dividers. On expanded layout, labels on left, selected subsection on right |

Use Android system typography (Roboto where available) for the initial baseline. Spacing uses 4 dp increments with 16/24 dp content insets, 8–12 dp row gaps, 16 dp standard surface radius, 24–28 dp sheets, and pill shapes only where action affordance benefits. Use M3 role names, not hardcoded operational colors. Review example graphite dark surfaces with mint foreground accent, warm off-white light surfaces with deep teal, and an amber/slate player scene. Use tonal elevation for hierarchy and real shadow for overlays or dragged rows. Light mode shifts Library, Queue and Settings to light surfaces. Player contrast chooses tokenized light or dark foreground against its own tested scrim independently of app chrome. System palette swaps M3 roles and static seed themes remain available. Detailed atmospheric palette behavior is in [F](F-backgrounds.md).

### Adaptation, motion and accessibility

- Compact width below roughly 600 dp uses bottom bar and one column. Medium width around 600–839 dp uses a rail where space allows, a wider library grid and adaptive player split. Expanded width around 840 dp and above may show library or queue alongside a pinned player detail pane. Collapse to one pane for narrow heights, significant font scaling or hinge obstruction. Maintain focus, selection and route state across resizing, rotations and split screens. Support edge-to-edge system insets with controls clear of gesture regions.
- Target 160–220 ms for menus and local confirmations and about 240–300 ms for player presentation, subject to Android back behavior. Background palette settles independently around 350 ms. Album cover remains readable during transition. Haptic only on meaningful release or reorder when enabled. System reduced motion overrides all app animation settings for decorative transitions, including background and waveform shape updates.
- Android 48 dp minimum targets, 4.5:1 normal text and 3:1 large text or meaningful graphics, and no color-only states. Test 200% text scaling, contrast at worst-case background and accessible focus order. TalkBack names include state and desktop context where useful. Throttle stale/connectivity announcements and never announce every tick. Time is adjustable through one seek control, visible elapsed/total and optional step actions. Provide keyboard focus styling and access to queue actions without drag or swipe. [Android accessibility](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility) · [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)

## Reusable components and FlutterTemplates mapping

App-owned reusable family: adaptive shell, remote target status, profile editor, art thumbnail/placeholder, mini-player, transport group, remote volume row, semantic timeline, dynamic backdrop, library row/album tile, paged search and footer, queue row, action sheet, confirmation, settings section/row, preview and recovery panel. Reuse workspace theme tokens and shared empty/loading/sheet/button components where they fit. Apply `ThemeData`, `ColorScheme`, `TextTheme` and common radius/spacing tokens at the app root, so copied pieces inherit consistent M3 roles in light and dark. Replace demo state, hardcoded colors and sample data before reuse.

| Verified FlutterTemplates entry | Planned reuse |
| --- | --- |
| [Sectioned Settings Page](https://fluttertemplates.dev/widgets/must_haves/settings_page/sectioned_settings_page/) | Reuse grouped list/navigation row structure. Replace local switches, Cupertino styling and sample callbacks with M3 controls and persisted state |
| [Search Results](https://fluttertemplates.dev/widgets/search/search_results/) | Reuse search field and results composition. Remove mock filtering/sorting and map to category, remote loading and paging |
| [Reorderable List](https://fluttertemplates.dev/widgets/layouts/reorderable_list/) | Reuse drag-handle/list structure. Replace mutable demo list with stable queue identity, relative target mapping and accessible reorder actions |
| [Bottom Sheets](https://fluttertemplates.dev/widgets/overlays/bottom_sheets/) | Reuse simple action layout and scrollable picker layout. Use existing shared dialog/sheet presentation and real callbacks |
| [Empty - No Data](https://fluttertemplates.dev/widgets/states/empty_no_data/) | Icon/message/action anatomy reusable directly as a visual pattern. Use the workspace EmptyState for implementation and contextual copy |
| [Login Screen](https://fluttertemplates.dev/widgets/auth/login_hero/) | Adapt the field validation, obscured password and focus pattern for the connection form. Remove email account assumptions and hero illustration |
| [Music Player](https://fluttertemplates.dev/widgets/media/music_player/) | Reference for compact control placement. Mock transport and fixed-color presentation require remote-specific redesign |
| [Bottom Nav](https://fluttertemplates.dev/widgets/navigation/bottom_navigation/simple_bottom/) | Source uses legacy BottomNavigationBar and sample colors. Use Material NavigationBar and NavigationRail for adaptive shell |

The verified entries currently list zero extra dependencies and MIT source. No complete demo is a drop-in screen for this product. Build the waveform, timed progress, background, mini-player, reconnect/status controls and queue reconciliation as app-specific behavior. [A. Integration evidence](A-research.md)

[Open the visual review sheet](visual-review.html) for illustrative Now Playing, Library, Queue and Settings mockups. The colors and dimensions in the sheet communicate direction. The accessibility and layout requirements in this document are the acceptance standard.
