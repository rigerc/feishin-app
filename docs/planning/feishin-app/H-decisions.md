# H. Confirmed decisions and approval checkpoint

The product direction below was confirmed in the planning interview. The user subsequently approved implementation. Beads records this decision in feishin-app-ag3.1.

| Decision | Confirmed direction and implications |
| --- | --- |
| Product and compatibility | **Android only, through Feishin Remote.** Feishin desktop plays the audio and manages its music backend. Verify the desktop Remote API on the agreed release and test backend-dependent capabilities through Feishin. The Android app needs only a Feishin connection profile for setup. |
| Transport | **Trusted local network by default, with encrypted WSS available.** Preselect the local-network option for new profiles and disclose that it uses an unencrypted connection before connecting. WSS uses normal certificate and hostname verification and stays selected until the user changes it. |
| Startup and navigation | **Now Playing by default, with Library as a selectable start screen.** Persist the choice in Settings. Library and Queue remain peer destinations with a mini-player. |
| Waveform scope | **Standard and generated seeking in the first release.** Revisit real waveforms later, after deciding whether an optional data source is worth adding. |
| Android integration | **In-app controls for the first release.** Revisit Android media notifications, lock-screen controls and headset buttons later, after device and lifecycle validation. |
| Artwork | **Show a placeholder when the cover is unavailable and keep controls usable.** Load eligible artwork URLs returned by Feishin. Apply the fallback background when needed. Desktop artwork proxy remains a research option for later. |

Desktop playback and the live queue remain authoritative. Radio is excluded.

## Implementation review

The approved implementation starts with validation of Feishin Remote and Android, alongside the connection and playback slice. [Feature spec](B-features.md) · [UX](C-ux.md) · [Architecture](D-architecture.md) · [Roadmap](G-roadmap.md)
