import 'dart:async';
import 'dart:math' as math;

import 'package:core/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../domain/remote.dart';

String timeLabel(Duration duration) {
  final seconds = duration.inSeconds;
  final minutes = (seconds ~/ 60).remainder(60);
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  final hours = seconds ~/ 3600;
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$remainder'
      : '$minutes:$remainder';
}

List<double> generatedPeaks(String identity, int count) {
  var hash = 0x811c9dc5;
  for (final code in identity.codeUnits) {
    hash = ((hash ^ code) * 0x01000193) & 0xffffffff;
  }
  final random = math.Random(hash);
  final source = List.generate(120, (_) => random.nextDouble());
  return List.generate(count, (index) {
    final x = (index * (source.length - 1) / (count - 1)).round();
    final next = source[math.min(x + 1, source.length - 1)];
    final wave = 0.65 + 0.35 * math.sin((x / source.length) * math.pi);
    return (0.12 + 0.88 * (source[x] * 0.7 + next * 0.3)) * wave;
  }, growable: false);
}

class Timeline extends StatefulWidget {
  const Timeline({
    super.key,
    required this.snapshot,
    required this.generation,
    required this.clock,
    required this.preferences,
    required this.enabled,
    required this.onSeek,
    this.accent,
  });

  final PlaybackSnapshot snapshot;
  final int generation;
  final Duration Function() clock;
  final RemotePreferences preferences;
  final bool enabled;
  final void Function(Duration, int, String?) onSeek;
  final Color? accent;

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _tick = ValueNotifier<int>(0);
  double? _drag;
  ({int generation, String? occurrence})? _dragScope;
  double? _pending;
  Timer? _settle;
  String? _peakKey;
  List<double> _peaks = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      _tick.value++;
      if (widget.clock() - widget.snapshot.anchorTime >=
          const Duration(seconds: 2)) {
        _ticker.stop();
      }
    });
    _sync();
  }

  @override
  void didUpdateWidget(Timeline old) {
    super.didUpdateWidget(old);
    if (old.generation != widget.generation ||
        old.snapshot.occurrence != widget.snapshot.occurrence ||
        old.snapshot.track?.id != widget.snapshot.track?.id ||
        !widget.enabled) {
      _cancel();
    } else if (_pending case final double pending) {
      final observed = widget.snapshot.position.inMilliseconds / 1000;
      if ((observed - pending).abs() < 0.65) {
        _settle?.cancel();
        _pending = null;
      }
    }
    _sync();
  }

  void _sync() {
    final wantsTicks =
        widget.enabled &&
        widget.snapshot.status == Playback.playing &&
        widget.clock() - widget.snapshot.anchorTime <
            const Duration(seconds: 2);
    if (wantsTicks && !_ticker.isActive) _ticker.start();
    if (!wantsTicks && _ticker.isActive) _ticker.stop();
    final identity =
        '${widget.snapshot.track?.serverId}:${widget.snapshot.track?.id}';
    final key = '$identity:${widget.preferences.barDensity}';
    if (_peakKey != key) {
      _peakKey = key;
      _peaks = generatedPeaks(identity, widget.preferences.barDensity);
    }
  }

  void _cancel() {
    _settle?.cancel();
    _drag = null;
    _dragScope = null;
    _pending = null;
  }

  void _start(double value) {
    _settle?.cancel();
    _pending = null;
    _dragScope = (
      generation: widget.generation,
      occurrence: widget.snapshot.occurrence,
    );
    setState(() => _drag = value);
  }

  void _finish(double value) {
    final scope = _dragScope;
    if (scope == null) return;
    _dragScope = null;
    setState(() {
      _drag = null;
      _pending = value;
    });
    _settle = Timer(
      const Duration(milliseconds: 1500),
      () => setState(() => _pending = null),
    );
    if (widget.preferences.haptics) unawaited(HapticFeedback.selectionClick());
    widget.onSeek(
      Duration(microseconds: (value * Duration.microsecondsPerSecond).round()),
      scope.generation,
      scope.occurrence,
    );
  }

  @override
  void dispose() {
    _settle?.cancel();
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _tick,
    builder: (context, _) {
      final trackDuration = widget.snapshot.track?.duration;
      final estimated = widget.enabled
          ? interpolatedPosition(widget.snapshot, widget.clock())
          : widget.snapshot.position;
      final maximum =
          (trackDuration?.inMicroseconds ?? 0) / Duration.microsecondsPerSecond;
      final value =
          (_drag ??
                  _pending ??
                  estimated.inMicroseconds / Duration.microsecondsPerSecond)
              .clamp(0.0, maximum > 0 ? maximum : 1.0)
              .toDouble();
      final enabled = widget.enabled && maximum > 0;
      final scheme = Theme.of(context).colorScheme;
      final waveform = widget.preferences.timeline == TimelineStyle.waveform;
      final timeStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      final slider = Slider(
        value: value,
        max: maximum > 0 ? maximum : 1.0,
        onChangeStart: enabled ? _start : null,
        onChanged: enabled
            ? (value) {
                if (_dragScope != null) setState(() => _drag = value);
              }
            : null,
        onChangeEnd: enabled ? _finish : null,
        semanticFormatterCallback: (seconds) =>
            timeLabel(Duration(seconds: seconds.round())),
      );
      final controls = waveform
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  left: AppSpacing.xl4,
                  right: AppSpacing.xl4,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WavePaint(
                        peaks: _peaks,
                        progress: maximum > 0 ? value / maximum : 0,
                        played: widget.accent ?? scheme.primary,
                        unplayed: scheme.outline,
                        reversed:
                            Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    disabledActiveTrackColor: Colors.transparent,
                    disabledInactiveTrackColor: Colors.transparent,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                    thumbSize: const WidgetStatePropertyAll(
                      Size.square(AppSpacing.xs),
                    ),
                    thumbColor: widget.accent ?? scheme.primary,
                  ),
                  child: slider,
                ),
              ],
            )
          : slider;
      return Column(
        children: [
          Semantics(
            label: waveform
                ? 'Playback position, generated waveform'
                : 'Playback position',
            child: controls,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeLabel(
                    Duration(
                      seconds: (maximum > 0 ? value : estimated.inSeconds)
                          .floor(),
                    ),
                  ),
                  style: timeStyle,
                ),
                Text(
                  trackDuration == null ? '—' : timeLabel(trackDuration),
                  style: timeStyle,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _WavePaint extends CustomPainter {
  const _WavePaint({
    required this.peaks,
    required this.progress,
    required this.played,
    required this.unplayed,
    required this.reversed,
  });

  final List<double> peaks;
  final double progress;
  final Color played;
  final Color unplayed;
  final bool reversed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || peaks.isEmpty) return;
    final count = math.min(peaks.length, math.max(1, (size.width / 3).floor()));
    final step = size.width / count;
    final width = (step * 0.62).clamp(1.0, 5.0);
    final maximum = math.min(size.height, AppSpacing.xl6);
    final done = Paint()..color = played;
    final remaining = Paint()..color = unplayed;
    for (var index = 0; index < count; index++) {
      final peak = peaks[index * peaks.length ~/ count];
      final height = math.max(AppSpacing.xs3, maximum * peak);
      final x = ((reversed ? count - index - 1 : index) + 0.5) * step;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, size.height / 2),
            width: width,
            height: height,
          ),
          Radius.circular(width / 2),
        ),
        index / count < progress ? done : remaining,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePaint oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.progress != progress ||
      oldDelegate.played != played ||
      oldDelegate.unplayed != unplayed ||
      oldDelegate.reversed != reversed;
}
