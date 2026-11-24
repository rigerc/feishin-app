import 'dart:math' as math;

import 'package:core/core/theme/app_radius.dart';
import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/button.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart' hide RepeatMode;

import '../../../../constants/value_const.dart';
import '../../domain/remote.dart';
import 'artwork.dart';
import 'timeline.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({
    super.key,
    required this.session,
    required this.repository,
    required this.cache,
    required this.artwork,
    required this.preferences,
    required this.browse,
    required this.queue,
    required this.rating,
    this.header,
  });

  final SessionState session;
  final RemoteRepository repository;
  final ArtworkCache cache;
  final Uri? artwork;
  final RemotePreferences preferences;
  final VoidCallback browse;
  final VoidCallback queue;
  final VoidCallback rating;
  final Widget? header;

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  ColorScheme? _palette;
  MemoryImage? _image;

  @override
  void didUpdateWidget(NowPlaying oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork != widget.artwork ||
        oldWidget.session.generation != widget.session.generation) {
      _image = null;
      _palette = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_image case final MemoryImage image) _loaded(image);
  }

  Future<void> _loaded(MemoryImage? image) async {
    _image = image;
    if (image == null) return;
    final brightness = Theme.of(context).brightness;
    final palette = await widget.cache.palette(image, brightness);
    if (mounted &&
        identical(_image, image) &&
        Theme.of(context).brightness == brightness) {
      setState(() => _palette = palette);
    }
  }

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (light, dark) {
      final theme = Theme.of(context);
      final device = theme.brightness == Brightness.dark ? dark : light;
      final scheme = switch (widget.preferences.background) {
        BackgroundSource.artwork => _palette ?? theme.colorScheme,
        BackgroundSource.device =>
          device == null
              ? theme.colorScheme
              : theme.colorScheme.copyWith(
                  primary: device.primary,
                  secondary: device.secondary,
                  tertiary: device.tertiary,
                ),
        BackgroundSource.theme => theme.colorScheme,
      };
      final snapshot = widget.session.playback;
      final track = snapshot.track;
      final enabled =
          widget.session.connection == Connection.connected && track != null;
      final reduce =
          widget.preferences.reducedMotion ||
          MediaQuery.disableAnimationsOf(context);
      final accent = widget.preferences.artworkColors
          ? _palette?.primary
          : null;
      return PlayerBackground(
        scheme: scheme,
        dim: widget.preferences.dimBackground,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
        child: Column(
          children: [
            ?widget.header,
            Expanded(
              child: LayoutBuilder(
                builder: (context, size) {
                  final wide = size.maxWidth >= 720;
                  final insets = wide ? AppSpacing.xl6 : AppSpacing.xl4;
                  final availableWidth = math.max(
                    0.0,
                    size.maxWidth - insets * 2,
                  );
                  final widthLimit = availableWidth * (wide ? 0.43 : 1);
                  // Stacked layouts reserve room for the controls so the whole
                  // player fits without scrolling on typical phones.
                  final heightLimit =
                      (wide
                              ? size.maxHeight * 0.87
                              : size.maxHeight -
                                    (track == null
                                        ? _emptyReserve
                                        : _controlsReserve))
                          .clamp(140.0, 490.0);
                  final coverSize = math.min(widthLimit, heightLimit);
                  final cover = DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.xl,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: .26,
                          ),
                          blurRadius: AppSpacing.xl4,
                          offset: const Offset(0, AppSpacing.sm),
                        ),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: coverSize,
                      child: CoverImage(
                        key: ValueKey((
                          widget.session.generation,
                          widget.artwork,
                        )),
                        cache: widget.cache,
                        url: widget.artwork,
                        featured: true,
                        icon: Icons.album_rounded,
                        pixels:
                            (coverSize * MediaQuery.devicePixelRatioOf(context))
                                .round()
                                .clamp(120, 960),
                        loaded: _loaded,
                      ),
                    ),
                  );
                  final controls = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.base,
                      children: [
                        _details(theme, track, enabled),
                        if (track == null)
                          AppButton(
                            label: ValueConst.browseLibrary,
                            leadingIcon: const Icon(
                              Icons.library_music_outlined,
                            ),
                            onTap: widget.browse,
                          )
                        else ...[
                          Timeline(
                            snapshot: snapshot,
                            generation: widget.session.generation,
                            clock: () => widget.repository.clock,
                            preferences: widget.preferences,
                            enabled: enabled,
                            accent: accent,
                            onSeek: (value, generation, occurrence) =>
                                widget.repository.seek(
                                  value,
                                  generation: generation,
                                  occurrence: occurrence,
                                ),
                          ),
                          _transport(theme, snapshot, enabled),
                          Row(
                            children: [
                              Expanded(
                                child: VolumeSlider(
                                  volume: snapshot.volume,
                                  enabled: enabled,
                                  accent: accent,
                                  change: (value) {
                                    final generation =
                                        widget.session.generation;
                                    if (generation ==
                                        widget.repository.state.generation) {
                                      widget.repository.setVolume(value);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: ValueConst.queue,
                                onPressed: widget.queue,
                                icon: const Icon(Icons.queue_music_rounded),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      insets,
                      AppSpacing.xs,
                      insets,
                      AppSpacing.xl4,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          size.maxHeight - AppSpacing.xs - AppSpacing.xl4,
                        ),
                      ),
                      child: wide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              spacing: AppSpacing.xl4,
                              children: [
                                cover,
                                Flexible(child: controls),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                cover,
                                const SizedBox(height: AppSpacing.xl4),
                                controls,
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  static const _controlsReserve = 380.0;
  static const _emptyReserve = 220.0;

  Widget _details(ThemeData theme, Track? track, bool enabled) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xs3,
          children: [
            Text(
              track?.name ?? ValueConst.noTrack,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              track == null
                  ? ValueConst.noTrackDetail
                  : [
                      track.artist,
                      if (track.album case final String album) album,
                    ].where((text) => text.isNotEmpty).join(' · '),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (track?.favorite case final bool favorite)
        IconButton(
          isSelected: favorite,
          tooltip: favorite
              ? ValueConst.removeFavorite
              : ValueConst.addFavorite,
          onPressed: enabled
              ? () => widget.repository.favorite(!favorite)
              : null,
          selectedIcon: Icon(
            Icons.favorite_rounded,
            color: theme.colorScheme.error,
          ),
          icon: const Icon(Icons.favorite_border_rounded),
        ),
      if (track != null && supportsRating(track))
        IconButton(
          tooltip: ValueConst.trackRating,
          onPressed: enabled ? widget.rating : null,
          icon: Icon(
            (track.rating ?? 0) > 0
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: (track.rating ?? 0) > 0 ? theme.colorScheme.primary : null,
          ),
        ),
    ],
  );

  Widget _transport(ThemeData theme, PlaybackSnapshot snapshot, bool enabled) {
    final playing = snapshot.status == Playback.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _control(
          TransportAction.shuffle,
          Icons.shuffle_rounded,
          enabled,
          selected: snapshot.shuffle,
          tooltip: ValueConst.shuffle,
        ),
        _control(
          TransportAction.previous,
          Icons.skip_previous_rounded,
          enabled,
          tooltip: ValueConst.previous,
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            minimumSize: const Size.square(AppSpacing.xl13),
            iconSize: AppSpacing.xl7,
            backgroundColor: theme.colorScheme.onSurface,
            foregroundColor: theme.colorScheme.surface,
          ),
          tooltip: playing ? ValueConst.pause : ValueConst.play,
          onPressed: enabled
              ? () => widget.repository.transport(
                  playing ? TransportAction.pause : TransportAction.play,
                )
              : null,
          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
        ),
        _control(
          TransportAction.next,
          Icons.skip_next_rounded,
          enabled,
          tooltip: ValueConst.next,
        ),
        _control(
          TransportAction.repeat,
          snapshot.repeat == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          enabled,
          selected: snapshot.repeat != RepeatMode.none,
          tooltip: ValueConst.repeat(snapshot.repeat.name),
        ),
      ],
    );
  }

  Widget _control(
    TransportAction action,
    IconData icon,
    bool enabled, {
    required String tooltip,
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final skip =
        action == TransportAction.previous || action == TransportAction.next;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: enabled ? () => widget.repository.transport(action) : null,
      iconSize: skip ? AppSpacing.xl6 : AppSpacing.xl3,
      style:
          IconButton.styleFrom(
            minimumSize: const Size.square(AppSpacing.xl10),
          ).copyWith(
            // A tonal disc makes the active shuffle/repeat state readable at a
            // glance, not just through a colour shift of the glyph.
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? scheme.primary.withValues(alpha: .16)
                  : null,
            ),
          ),
      selectedIcon: Icon(icon, color: scheme.primary),
      icon: Icon(icon),
    );
  }
}

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({
    super.key,
    required this.volume,
    required this.enabled,
    required this.change,
    this.accent,
  });

  final double volume;
  final bool enabled;
  final ValueChanged<double> change;
  final Color? accent;

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  // Holds the thumb at the user's value until the desktop echoes a new
  // volume, so the slider doesn't snap back while the change round-trips.
  double? _local;
  bool _dragging = false;

  @override
  void didUpdateWidget(VolumeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || !_dragging && oldWidget.volume != widget.volume) {
      _local = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = (_local ?? widget.volume).clamp(0.0, 100.0);
    final icon = switch (value) {
      0 => Icons.volume_off_rounded,
      < 50 => Icons.volume_down_rounded,
      _ => Icons.volume_up_rounded,
    };
    return Row(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.base),
          child: Icon(
            icon,
            size: AppSpacing.xl3,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Semantics(
            label: ValueConst.volume,
            child: Slider(
              value: value,
              max: 100,
              activeColor: widget.accent,
              semanticFormatterCallback: ValueConst.volumePercent,
              onChangeStart: widget.enabled
                  ? (value) => setState(() {
                      _dragging = true;
                      _local = value;
                    })
                  : null,
              onChanged: widget.enabled
                  ? (value) => setState(() => _local = value)
                  : null,
              onChangeEnd: widget.enabled
                  ? (value) {
                      setState(() => _dragging = false);
                      widget.change(value.roundToDouble());
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class PlayerBackground extends StatelessWidget {
  const PlayerBackground({
    super.key,
    required this.scheme,
    required this.dim,
    required this.duration,
    required this.child,
  });

  final ColorScheme scheme;
  final bool dim;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.surface,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 0.95,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: dim ? 0.16 : 0.37),
              theme.surface,
            ),
            theme.surface,
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.68,
            colors: [
              scheme.tertiary.withValues(alpha: dim ? 0.08 : 0.18),
              theme.surface.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
