# F. Dynamic Now Playing backgrounds

Use three softly feathered color fields over a tonal base with a protected foreground. Derive colors from artwork, Android palette or static theme according to Settings. The cover stays sharp and retains visual priority.

| Technique | Appearance and cost | Use |
| --- | --- | --- |
| Single dominant color | Stable and inexpensive. Misses visual relationships in multi-color covers | Fallback when only one useful color is present, derive tonal variants |
| Multi-color quantization with radial layers | Captures cover accents, lets the design place brightness away from controls, predictable render cost | Recommended. Sample small input and render two to three radial lobes with a base and scrim |
| Oversized blurred cover | Preserves image structure and produces stronger luminance extremes. Large textures and filtering increase raster cost and text contrast variability | Do not use as baseline |
| Hybrid artwork plus gradient | Can lend texture, but creates two background sources and more cache/contrast work | Evaluate if approved as an enhanced style. Keep image texture optional, low-resolution and confined to one child |
| Mesh or shader | Flexible blending and organic motion. More GPU tuning, fallbacks and renderer testing | Revisit only if measured benefits justify it |

## Palette and rendering pipeline

1. Resolve trusted artwork for the current track and decode to at most 64×64 sampled pixels for color analysis. Keep display decode sized to its own target, capped by device budget. Filter transparent pixels, reduce noise, and use quantization on a bounded worker/isolate. Rank by population, usable chroma and tonal separation. Keep dark and light artwork meaningful with tonal normalization and two accent fallbacks. Cache palette keyed by profile/origin, artwork ID or opaque URL digest, validator and algorithm version. Reuse across albums and invalidate on image revision or settings affecting the algorithm. Apply async result only if profile, track and artwork generation match.
2. Artwork mode uses that ranked palette. Device mode selects primary/secondary/tertiary tones from the supported Android color scheme and blends into the M3 on-screen base, keeping foreground role choices separate. On Android without a system palette, use the selected static M3 preset. Static mode defines three balanced seeds for the scene and one optional enhanced custom palette. Custom choices run through the same tonal clamp and contrast rules.
3. Paint a solid base and radial lobes from upper-left primary, upper-right secondary, and lower peripheral accent with decreasing opacity. Add a vertical scrim or opaque tonal container where controls need it. “Blur strength” tunes radial falloff and edge softness. Optional real filtering is confined to a low-resolution background child and measured on budget devices. Disable filters explicitly when unused. Avoid full-screen BackdropFilter. [Flutter performance](https://docs.flutter.dev/perf/best-practices) · [ImageFiltered](https://api.flutter.dev/flutter/widgets/ImageFiltered-class.html) · [BackdropFilter](https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html) · [dynamic_color](https://pub.dev/packages/dynamic_color)
4. Prefer interpolating resolved tonal/lobe parameters on one painter, testing intermediate contrast. Compare a bounded crossfade of two cached fields if interpolation is visually unstable. Start about 350 ms with an ease-out curve. Use the currently visible palette as the start on rapid skips. Coalesce stale tasks, retain at most two active scene states, and stop animation when route is hidden, app inactive, or reduced motion is on. Avoid per-frame palette extraction, decoder churn and per-frame shader blur. For missing art show a stable device/static fallback behind the artwork placeholder. Keep playback controls in place and usable when the remote session is ready. If loading new art, use neutral theme state and prevent late image colors reviving the previous track.

## Settings and safeguards

| Preference | Proposed behavior |
| --- | --- |
| Source | Artwork default, Device palette, Static theme. Device mode visibly falls back when Android lacks dynamic color |
| Theme and custom color | Independent System/Light/Dark application theme. Choose static preset or enhanced custom seeds. Preview strength against both app modes |
| Softness, saturation and intensity | Softness broadens falloff, saturation changes chroma within bounds, intensity scales lobe contribution. Start with three presets and expose individual sliders in Enhanced |
| Darkness and contrast protection | Adjustable darkening changes the player atmosphere. Contrast guard remains enforced at control/text regions. Sample worst-case background under each control across crossfade and at both extremes. Increase scrim or use a tonal fill if minimum is missed |
| Animation and duration | Animate track color transitions on/off, bounded 0–600 ms tuning in Enhanced. Reduced motion respects the Android setting, with app control to reduce further. No idle moving background required |
| Preview | Live sample card shares the production palette/gradient painter. Reset per subsection. Changing a setting applies immediately without touching desktop state |

Review with monochrome, transparent, neon, white and black art plus quick track switching. Profile UI and raster frame durations, allocation plateau during covers cycling and memory cost against [G](G-roadmap.md). Also verify fallback on an older device and on a device where system colors change.
