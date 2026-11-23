# feishin-app planning package

**Review status:** Product direction confirmed and implementation approved. Validation is in progress. Research snapshot 23 November 2026.

feishin-app is a Material 3 Flutter remote for Feishin desktop on Android. The first release connects through Feishin Remote using trusted LAN by default, with WSS available. Now Playing is the default start screen, and Settings can switch it to Library. The first release covers in-app playback controls, browsing, queue editing, standard and generated seeking, and artwork, device and static backgrounds. Playback stays usable with placeholder artwork. Feishin v1.17.0 is the initial desktop compatibility candidate. Real waveforms and Android system media controls are later investigations.

| Document | Contents |
| --- | --- |
| [A. Research report](A-research.md) | Local reference audit, pinned upstream comparison, exact wire fields, dependencies, FlutterTemplates and Android findings |
| [B. Feature specification](B-features.md) | API/implementation support and acceptance by capability |
| [C. UI/UX plan](C-ux.md) | Navigation, flows, wireframes, screen specs, accessibility and verified template mapping |
| [D. Technical architecture](D-architecture.md) | Responsibilities, state ownership, protocol, data flow, security and performance |
| [E. Waveform report](E-waveform.md) | Data availability, opt-in waveform sources, settings and accurate seeking |
| [F. Dynamic background specification](F-backgrounds.md) | Artwork, device and static palette pipeline, transitions and contrast |
| [G. Roadmap and verification](G-roadmap.md) | MVP, enhanced and future phases, acceptance criteria, evidence and risk register |
| [H. Confirmed decisions](H-decisions.md) | Interview outcomes and implementation approval checkpoint |

[Visual review sheet](visual-review.html) shows illustrative Now Playing, Library, Queue and Settings layouts. The [UX plan](C-ux.md) includes compact wireframes for connection, recovery, waveform settings and the playlist picker.

The source review establishes wire behavior for the pinned code. Live desktop/backend traces, real Android hardware checks, dependency resolution and performance measurements are implementation-entry or release gates in the roadmap.
