enum Catalog { tracks, albums, playlists }

enum Playback { paused, playing, stopped }

enum RepeatMode { none, all, one }

enum Connection {
  disconnected,
  connecting,
  connected,
  reconnecting,
  authFailed,
}

enum Placement { now, next, last }

enum Destination { playing, library, queue, settings, profiles }

enum BackgroundSource { artwork, device, theme }

enum TimelineStyle { standard, waveform }

enum ThemePreference { system, light, dark }

enum MutationResult {
  applied,
  queueChanged,
  rejected,
  unconfirmed,
  disconnected,
}

enum TransportAction { play, pause, next, previous, shuffle, repeat }

typedef Track = ({
  String id,
  String name,
  String artist,
  String? album,
  String? serverId,
  String? serverType,
  String? occurrence,
  Duration? duration,
  Uri? artwork,
  bool? favorite,
  int? rating,
  int? year,
  int? songCount,
});

typedef QueueEntry = ({String occurrence, Track track});
typedef QueueSnapshot = ({String? current, List<QueueEntry> items});
typedef CatalogPage = ({List<Track> items, int received, bool hasMore});

class RemoteProfile {
  const RemoteProfile({
    required this.id,
    required this.name,
    required this.endpoint,
    this.username = '',
    this.rememberPassword = true,
  });

  final String id;
  final String name;
  final Uri endpoint;
  final String username;
  final bool rememberPassword;
}

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.track,
    this.status = Playback.stopped,
    this.position = Duration.zero,
    this.anchorTime = Duration.zero,
    this.repeat = RepeatMode.none,
    this.shuffle = false,
    this.volume = 0,
    this.queue,
    this.confirmQueueChanges = true,
  });

  final Track? track;
  final Playback status;
  final Duration position;
  final Duration anchorTime;
  final RepeatMode repeat;
  final bool shuffle;
  final double volume;
  final QueueSnapshot? queue;
  final bool confirmQueueChanges;

  String? get occurrence => queue?.current ?? track?.occurrence;

  PlaybackSnapshot copyWith({
    Track? track,
    bool clearTrack = false,
    Playback? status,
    Duration? position,
    Duration? anchorTime,
    RepeatMode? repeat,
    bool? shuffle,
    double? volume,
    QueueSnapshot? queue,
    bool clearQueue = false,
    bool? confirmQueueChanges,
  }) => PlaybackSnapshot(
    track: clearTrack ? null : track ?? this.track,
    status: status ?? this.status,
    position: position ?? this.position,
    anchorTime: anchorTime ?? this.anchorTime,
    repeat: repeat ?? this.repeat,
    shuffle: shuffle ?? this.shuffle,
    volume: volume ?? this.volume,
    queue: clearQueue ? null : queue ?? this.queue,
    confirmQueueChanges: confirmQueueChanges ?? this.confirmQueueChanges,
  );
}

typedef SessionState = ({
  Connection connection,
  PlaybackSnapshot playback,
  int generation,
  String? notice,
});

class RemotePreferences {
  const RemotePreferences({
    this.start = Destination.playing,
    this.theme = ThemePreference.dark,
    this.background = BackgroundSource.artwork,
    this.timeline = TimelineStyle.waveform,
    this.barDensity = 72,
    this.artworkColors = true,
    this.allowArtworkHosts = false,
    this.haptics = true,
    this.reducedMotion = false,
    this.dimBackground = false,
    this.blurMiniPlayer = false,
    this.confirmReplace = true,
    this.autoReconnect = true,
  });

  final Destination start;
  final ThemePreference theme;
  final BackgroundSource background;
  final TimelineStyle timeline;
  final int barDensity;
  final bool artworkColors;
  final bool allowArtworkHosts;
  final bool haptics;
  final bool reducedMotion;
  final bool dimBackground;
  final bool blurMiniPlayer;
  final bool confirmReplace;
  final bool autoReconnect;

  RemotePreferences copyWith({
    Destination? start,
    ThemePreference? theme,
    BackgroundSource? background,
    TimelineStyle? timeline,
    int? barDensity,
    bool? artworkColors,
    bool? allowArtworkHosts,
    bool? haptics,
    bool? reducedMotion,
    bool? dimBackground,
    bool? blurMiniPlayer,
    bool? confirmReplace,
    bool? autoReconnect,
  }) => RemotePreferences(
    start: start ?? this.start,
    theme: theme ?? this.theme,
    background: background ?? this.background,
    timeline: timeline ?? this.timeline,
    barDensity: barDensity ?? this.barDensity,
    artworkColors: artworkColors ?? this.artworkColors,
    allowArtworkHosts: allowArtworkHosts ?? this.allowArtworkHosts,
    haptics: haptics ?? this.haptics,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    dimBackground: dimBackground ?? this.dimBackground,
    blurMiniPlayer: blurMiniPlayer ?? this.blurMiniPlayer,
    confirmReplace: confirmReplace ?? this.confirmReplace,
    autoReconnect: autoReconnect ?? this.autoReconnect,
  );
}

abstract interface class RemoteRepository {
  SessionState get state;
  Stream<SessionState> get updates;
  Duration get clock;

  Future<bool> connect(RemoteProfile profile, String password);
  Future<String?> testConnection(RemoteProfile profile, String password);
  void disconnect();
  void setForeground(bool foreground);
  void setAutoReconnect(bool enabled);
  void transport(TransportAction action);
  void seek(
    Duration position, {
    required int generation,
    required String? occurrence,
  });
  void setVolume(double volume);
  void favorite(bool value);
  void rate(int value);
  Future<CatalogPage?> browse(Catalog catalog, int offset, String query);
  Future<MutationResult> play(Catalog catalog, String id, Placement placement);
  Future<MutationResult> addToPlaylist(String trackId, String playlistId);
  Future<MutationResult> jump(String occurrence);
  Future<MutationResult> remove(String occurrence);
  Future<MutationResult> move(
    String occurrence,
    String target, {
    required bool before,
  });
  Future<MutationResult> clear();
}

abstract interface class RemoteConfiguration {
  Future<({List<RemoteProfile> profiles, String? active})> loadProfiles();
  Future<String> passwordFor(RemoteProfile profile);
  Future<void> saveProfile(RemoteProfile profile, String password);
  Future<void> removeProfile(String id);
  Future<void> selectProfile(String? id);
  Future<RemotePreferences> loadPreferences();
  Future<void> savePreferences(RemotePreferences preferences);
}

Duration interpolatedPosition(PlaybackSnapshot state, Duration clock) {
  final elapsed = (clock - state.anchorTime).inMicroseconds.clamp(0, 2000000);
  final micros =
      state.position.inMicroseconds +
      (state.status == Playback.playing ? elapsed : 0);
  final duration = state.track?.duration?.inMicroseconds;
  return Duration(
    microseconds: duration == null ? micros : micros.clamp(0, duration),
  );
}

bool supportsRating(Track track) =>
    track.rating != null ||
    const {'navidrome', 'subsonic'}.contains(track.serverType?.toLowerCase());

Uri? remoteEndpoint(String value, {required bool encrypted}) {
  final input = value.trim();
  final scheme = encrypted ? 'wss' : 'ws';
  final uri = Uri.tryParse(input.contains('://') ? input : '$scheme://$input');
  if (uri == null ||
      uri.scheme != scheme ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.hasQuery ||
      (uri.hasPort && (uri.port < 1 || uri.port > 65535))) {
    return null;
  }
  return uri.replace(
    port: uri.hasPort
        ? uri.port
        : encrypted
        ? 443
        : 4333,
    path: uri.path.isEmpty ? '/' : uri.path,
  );
}
