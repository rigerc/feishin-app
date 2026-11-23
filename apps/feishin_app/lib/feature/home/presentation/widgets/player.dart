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
    required this.volume,
    required this.rating,
  });

  final SessionState session;
  final RemoteRepository repository;
  final ArtworkCache cache;
  final Uri? artwork;
  final RemotePreferences preferences;
  final VoidCallback browse;
  final VoidCallback queue;
  final VoidCallback volume;
  final VoidCallback rating;

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
      return PlayerBackground(
        scheme: scheme,
        dim: widget.preferences.dimBackground,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
        child: LayoutBuilder(
          builder: (context, size) {
            final wide = size.maxWidth >= 720;
            final insets = wide ? AppSpacing.xl6 : AppSpacing.xl4;
            final availableWidth = math.max(0.0, size.maxWidth - insets * 2);
            final widthLimit = availableWidth * (wide ? 0.43 : 1);
            final heightLimit = (size.maxHeight * (wide ? 0.87 : 0.53)).clamp(
              140.0,
              490.0,
            );
            final coverSize = math.min(widthLimit, heightLimit);
            final cover = DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.xl,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: .26),
                    blurRadius: AppSpacing.xl4,
                    offset: const Offset(0, AppSpacing.sm),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: coverSize,
                child: CoverImage(
                  key: ValueKey((widget.session.generation, widget.artwork)),
                  cache: widget.cache,
                  url: widget.artwork,
                  featured: true,
                  icon: Icons.album_rounded,
                  pixels: (coverSize * MediaQuery.devicePixelRatioOf(context))
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track?.name ?? ValueConst.noTrack,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.7,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track == null
                                  ? ValueConst.noTrackDetail
                                  : [
                                          track.artist,
                                          if (track.album
                                              case final String album)
                                            album,
                                        ]
                                        .where((text) => text.isNotEmpty)
                                        .join(' · '),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (track?.favorite case final bool favorite)
                        IconButton(
                          isSelected: favorite,
                          tooltip: favorite
                              ? 'Remove favorite'
                              : 'Add favorite',
                          onPressed: enabled
                              ? () => widget.repository.favorite(!favorite)
                              : null,
                          selectedIcon: const Icon(Icons.favorite_rounded),
                          icon: const Icon(Icons.favorite_border_rounded),
                        ),
                      if (track != null && supportsRating(track))
                        IconButton(
                          tooltip: 'Track rating',
                          onPressed: enabled ? widget.rating : null,
                          icon: Icon(
                            (track.rating ?? 0) > 0
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                          ),
                        ),
                    ],
                  ),
                  if (track == null)
                    AppButton(label: ValueConst.library, onTap: widget.browse)
                  else ...[
                    Timeline(
                      snapshot: snapshot,
                      generation: widget.session.generation,
                      clock: () => widget.repository.clock,
                      preferences: widget.preferences,
                      enabled: enabled,
                      accent: widget.preferences.artworkColors
                          ? _palette?.primary
                          : null,
                      onSeek: (value, generation, occurrence) =>
                          widget.repository.seek(
                            value,
                            generation: generation,
                            occurrence: occurrence,
                          ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _control(
                          TransportAction.shuffle,
                          Icons.shuffle_rounded,
                          enabled,
                          selected: snapshot.shuffle,
                        ),
                        _control(
                          TransportAction.previous,
                          Icons.skip_previous_rounded,
                          enabled,
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(AppSpacing.xl13),
                            iconSize: AppSpacing.xl7,
                            backgroundColor: theme.colorScheme.onSurface,
                            foregroundColor: theme.colorScheme.surface,
                          ),
                          tooltip: snapshot.status == Playback.playing
                              ? 'Pause'
                              : 'Play',
                          onPressed: enabled
                              ? () => widget.repository.transport(
                                  snapshot.status == Playback.playing
                                      ? TransportAction.pause
                                      : TransportAction.play,
                                )
                              : null,
                          icon: Icon(
                            snapshot.status == Playback.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        _control(
                          TransportAction.next,
                          Icons.skip_next_rounded,
                          enabled,
                        ),
                        _control(
                          TransportAction.repeat,
                          snapshot.repeat == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          enabled,
                          selected: snapshot.repeat != RepeatMode.none,
                          tooltip: 'Repeat: ${snapshot.repeat.name}',
                        ),
                      ],
                    ),
                    Divider(color: theme.colorScheme.outlineVariant),
                    LayoutBuilder(
                      builder: (context, layout) {
                        final largeText =
                            MediaQuery.textScalerOf(context).scale(14) > 20;
                        final itemWidth = largeText
                            ? layout.maxWidth
                            : layout.maxWidth / 2;
                        return Wrap(
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _PlayerShortcut(
                                icon: Icons.volume_up_outlined,
                                label: ValueConst.volume,
                                onTap: enabled ? widget.volume : null,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _PlayerShortcut(
                                icon: Icons.queue_music_rounded,
                                label: ValueConst.queue,
                                onTap: widget.queue,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                insets,
                AppSpacing.lg,
                insets,
                AppSpacing.xl4,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: AppSpacing.xl5,
                      children: [cover, controls],
                    ),
            );
          },
        ),
      );
    },
  );

  Widget _control(
    TransportAction action,
    IconData icon,
    bool enabled, {
    bool selected = false,
    String? tooltip,
  }) => IconButton(
    tooltip: tooltip ?? action.name,
    isSelected: selected,
    onPressed: enabled ? () => widget.repository.transport(action) : null,
    iconSize:
        action == TransportAction.previous || action == TransportAction.next
        ? AppSpacing.xl6
        : AppSpacing.xl3,
    selectedIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
    icon: Icon(icon),
  );
}

class _PlayerShortcut extends StatelessWidget {
  const _PlayerShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    variant: AppButtonVariant.text,
    state: onTap == null ? AppButtonState.disabled : AppButtonState.idle,
    leadingIcon: Icon(icon),
    onTap: onTap,
  );
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
