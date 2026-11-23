import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/remote.dart';
import 'remote_protocol.dart';
import 'socket_channel.dart';

class FeishinRepository implements RemoteRepository {
  FeishinRepository({WebSocketChannel Function(Uri)? channel})
    : _openChannel = channel ?? openChannel;

  final WebSocketChannel Function(Uri) _openChannel;
  final _updates = StreamController<SessionState>.broadcast();
  final _clock = Stopwatch()..start();
  final _random = Random.secure();
  final _pending =
      <String, ({String expected, Completer<WireObject?> result})>{};
  final _requestPrefix = List.generate(
    4,
    (_) => Random.secure().nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
  ).join();
  var _requestSequence = 0;
  var _generation = 0;
  var _attempt = 0;
  var _foreground = true;
  var _autoReconnect = true;
  var _mutationActive = false;
  var _playback = const PlaybackSnapshot();
  var _connection = Connection.disconnected;
  String? _notice;
  RemoteProfile? _profile;
  String? _password;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _frames;
  Completer<bool>? _handshake;
  Timer? _retry;

  @override
  SessionState get state => (
    connection: _connection,
    playback: _playback,
    generation: _generation,
    notice: _notice,
  );

  @override
  Stream<SessionState> get updates => _updates.stream;

  @override
  Duration get clock => _clock.elapsed;

  void _publish() => _updates.add(state);

  @override
  Future<bool> connect(RemoteProfile profile, String password) {
    _retire();
    _profile = profile;
    _password = password;
    _attempt = 0;
    _playback = const PlaybackSnapshot();
    return _open(reconnecting: false);
  }

  @override
  Future<String?> testConnection(RemoteProfile profile, String password) async {
    final probe = FeishinRepository(channel: _openChannel)
      ..setAutoReconnect(false);
    try {
      return await probe.connect(profile, password)
          ? null
          : probe.state.notice ?? 'Feishin did not send its initial state.';
    } finally {
      await probe.dispose();
    }
  }

  @override
  void disconnect() {
    _profile = null;
    _password = null;
    _retire();
    _playback = const PlaybackSnapshot();
    _change(Connection.disconnected);
  }

  @override
  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (!foreground) {
      final authFailed = _connection == Connection.authFailed;
      _retire();
      if (!authFailed) _change(Connection.disconnected);
    } else if (_profile != null && _connection != Connection.authFailed) {
      unawaited(_open(reconnecting: true));
    }
  }

  @override
  void setAutoReconnect(bool enabled) {
    _autoReconnect = enabled;
    if (!enabled && _retry != null) {
      _retry?.cancel();
      _retry = null;
      _change(Connection.disconnected, _notice);
    }
  }

  void _change(Connection value, [String? notice]) {
    _connection = value;
    _notice = notice;
    _publish();
  }

  void _retire() {
    _generation++;
    _retry?.cancel();
    _retry = null;
    _mutationActive = false;
    final channel = _channel;
    final frames = _frames;
    _channel = null;
    _frames = null;
    if (frames != null) unawaited(frames.cancel());
    if (channel != null) {
      unawaited(
        Future<void>.sync(() async {
          await channel.sink.close();
        }).catchError((Object _) {}),
      );
    }
    final handshake = _handshake;
    if (handshake != null && !handshake.isCompleted) handshake.complete(false);
    _handshake = null;
    for (final request in _pending.values) {
      request.result.complete(null);
    }
    _pending.clear();
  }

  Future<bool> _open({required bool reconnecting}) async {
    final profile = _profile;
    if (!_foreground || profile == null) return false;
    _retry = null;
    final generation = ++_generation;
    final handshake = _handshake = Completer<bool>();
    _change(reconnecting ? Connection.reconnecting : Connection.connecting);
    try {
      final channel = _channel = _openChannel(profile.endpoint);
      await channel.ready.timeout(const Duration(seconds: 6));
      if (generation != _generation) return false;
      _frames = channel.stream.listen(
        (raw) {
          if (generation == _generation) _receive(raw);
        },
        onDone: () => _lost(generation, channel.closeCode),
        onError: (Object _) => _lost(generation, channel.closeCode),
      );
      final password = _password ?? '';
      if (profile.username.isNotEmpty || password.isNotEmpty) {
        final token = base64Encode(
          utf8.encode('${profile.username}:$password'),
        );
        _send('authenticate', {'header': 'Basic $token'}, true);
      }
      return await handshake.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          _lost(generation, null, 'Feishin did not send its initial state.');
          return false;
        },
      );
    } catch (_) {
      _lost(
        generation,
        null,
        'Could not reach Feishin. Check the address, network, and TLS certificate.',
      );
      return false;
    }
  }

  void _lost(int generation, int? closeCode, [String? message]) {
    if (_generation != generation) return;
    final authFailed = closeCode == 4004;
    _retire();
    if (authFailed) {
      _change(
        Connection.authFailed,
        'Check the credentials in Feishin Remote Control.',
      );
      return;
    }
    final reason = message ?? 'Connection to Feishin lost.';
    if (!_autoReconnect || !_foreground || _profile == null) {
      _change(Connection.disconnected, reason);
      return;
    }
    final delay = min(24, 1 << min(_attempt++, 5));
    _change(Connection.reconnecting, reason);
    _retry = Timer(
      Duration(milliseconds: delay * 1000 + _random.nextInt(650)),
      () => unawaited(_open(reconnecting: true)),
    );
  }

  bool _send(
    String event, [
    WireObject fields = const {},
    bool duringHandshake = false,
  ]) {
    if (!duringHandshake && _connection != Connection.connected) return false;
    final channel = _channel;
    if (channel == null) return false;
    try {
      channel.sink.add(jsonEncode({'event': event, ...fields}));
      return true;
    } catch (_) {
      _lost(_generation, channel.closeCode);
      return false;
    }
  }

  void _receive(Object? raw) {
    if (raw is! String || raw.length > 8 * 1024 * 1024) return;
    final Object? frame;
    try {
      frame = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (frame is! WireObject || frame['event'] is! String) return;
    final event = frame['event'] as String;
    final data = frame['data'];
    if (event == 'state' && data is WireObject) {
      final handshaking = _connection != Connection.connected;
      _playback = (handshaking ? const PlaybackSnapshot() : _playback).copyWith(
        track: data['song'] is WireObject
            ? RemoteTrackModel(data['song'] as WireObject).toEntity()
            : null,
        clearTrack: data.containsKey('song') && data['song'] == null,
        status: enumValue(Playback.values, data['status'], _playback.status),
        position: positionDuration(data['position']),
        anchorTime: clock,
        repeat: enumValue(RepeatMode.values, data['repeat'], _playback.repeat),
        shuffle: data['shuffle'] is bool ? data['shuffle'] as bool : null,
        volume: finiteNumber(data['volume'])?.clamp(0, 100).toDouble(),
      );
      _attempt = 0;
      _change(Connection.connected);
      final handshake = _handshake;
      if (handshake != null && !handshake.isCompleted) handshake.complete(true);
      return;
    }
    if (_connection != Connection.connected) return;
    if (data is WireObject && data['requestId'] is String) {
      final id = data['requestId'] as String;
      final request = _pending[id];
      if (request != null && event == request.expected) {
        _pending.remove(id);
        request.result.complete(data);
      }
      return;
    }
    final updated = _reduce(event, data);
    if (updated == null) return;
    _playback = updated;
    _publish();
  }

  PlaybackSnapshot? _reduce(String event, Object? data) {
    final current = _playback;
    switch ((event, data)) {
      case ('song', null):
        return current.copyWith(
          clearTrack: true,
          position: Duration.zero,
          anchorTime: clock,
        );
      case ('song', final WireObject data):
        final track = RemoteTrackModel(data).toEntity();
        if (track == null) return null;
        return current.copyWith(
          track: track,
          position: Duration.zero,
          anchorTime: clock,
        );
      case ('position', final num value):
        final position = positionDuration(value);
        return position == null
            ? null
            : current.copyWith(position: position, anchorTime: clock);
      case ('playback', final String status):
        final playback = enumValue(Playback.values, status, current.status);
        return current.copyWith(
          status: playback,
          position: interpolatedPosition(current, clock),
          anchorTime: clock,
        );
      case ('volume', final num value) when value.isFinite:
        return current.copyWith(volume: value.clamp(0, 100).toDouble());
      case ('repeat', final String repeat):
        return current.copyWith(
          repeat: enumValue(RepeatMode.values, repeat, current.repeat),
        );
      case ('shuffle', final bool shuffle):
        return current.copyWith(shuffle: shuffle);
      case ('confirm-queue-changes-setting', final bool enabled):
        return current.copyWith(confirmQueueChanges: enabled);
      case ('queue-state', final WireObject data):
        final queue = decodeQueue(data);
        if (queue == null) return current.copyWith(clearQueue: true);
        final changed =
            current.queue?.current != null &&
            queue.current != current.queue?.current;
        final followsSong = queue.current == current.track?.occurrence;
        return current.copyWith(
          queue: queue,
          position: changed && !followsSong ? Duration.zero : null,
          anchorTime: changed && !followsSong ? clock : null,
        );
      case ('favorite' || 'rating', final WireObject data):
        final track = current.track;
        if (track == null || data['id'] != track.id) return null;
        return current.copyWith(
          track: RemoteTrackModel({
            ...RemoteTrackModel.fromEntity(track).value,
            if (event == 'favorite') 'userFavorite': data['favorite'],
            if (event == 'rating') 'userRating': data['rating'],
          }).toEntity(),
        );
      default:
        return null;
    }
  }

  @override
  void transport(TransportAction action) => _send(action.name);

  @override
  void seek(
    Duration position, {
    required int generation,
    required String? occurrence,
  }) {
    final duration = _playback.track?.duration;
    if (generation != _generation ||
        occurrence != _playback.occurrence ||
        duration == null) {
      return;
    }
    final micros = position.inMicroseconds.clamp(0, duration.inMicroseconds);
    _send('position', {'position': micros / Duration.microsecondsPerSecond});
  }

  @override
  void setVolume(double volume) {
    if (volume.isFinite) _send('volume', {'volume': volume.clamp(0, 100)});
  }

  @override
  void favorite(bool value) {
    final track = _playback.track;
    if (track?.favorite != null) {
      _send('favorite', {'id': track!.id, 'favorite': value});
    }
  }

  @override
  void rate(int value) {
    final track = _playback.track;
    if (track == null || !supportsRating(track) || value < 0 || value > 5) {
      return;
    }
    _send('rating', {'id': track.id, 'rating': value});
  }

  Future<WireObject?> _request(
    String event,
    String expected,
    WireObject fields,
  ) async {
    if (_pending.length >= 16) return null;
    final id = '$_requestPrefix-${_requestSequence++}';
    final result = Completer<WireObject?>();
    _pending[id] = (expected: expected, result: result);
    try {
      if (!_send(event, {...fields, 'requestId': id})) return null;
      return await result.future.timeout(
        const Duration(seconds: 16),
        onTimeout: () => null,
      );
    } finally {
      _pending.remove(id);
    }
  }

  @override
  Future<CatalogPage?> browse(Catalog catalog, int offset, String query) async {
    final result = await _request(
      '${catalog.name}-request',
      '${catalog.name}-response',
      {
        'limit': 30,
        'startIndex': offset,
        if (query.isNotEmpty) 'searchTerm': query,
      },
    );
    final items = result?['items'];
    final hasMore = result?['hasMore'];
    if (items is! List || hasMore is! bool || items.length > 2000) return null;
    return (
      items: List<Track>.unmodifiable(
        items
            .whereType<WireObject>()
            .map((item) => RemoteTrackModel(item).toEntity())
            .whereType<Track>(),
      ),
      received: items.length,
      hasMore: hasMore,
    );
  }

  Future<MutationResult> _mutate(
    String event,
    WireObject fields, {
    bool ack = false,
    bool collection = false,
    bool Function(QueueSnapshot)? verify,
  }) async {
    if (_connection != Connection.connected) return MutationResult.disconnected;
    if (_mutationActive) return MutationResult.rejected;
    final previous = _playback.queue;
    if (verify != null && previous == null) return MutationResult.rejected;
    final generation = _generation;
    _mutationActive = true;
    final observed = Completer<bool>();
    StreamSubscription<SessionState>? subscription;
    if (verify != null) {
      subscription = updates.listen((state) {
        if (observed.isCompleted) return;
        final queue = state.playback.queue;
        if (state.generation != generation) {
          observed.complete(false);
        } else if (queue != null &&
            !identical(queue, previous) &&
            verify(queue)) {
          observed.complete(true);
        }
      });
    }
    try {
      if (ack) {
        final response = await _request(event, 'operation-ack', fields);
        if (generation != _generation) return MutationResult.disconnected;
        if (response?['error'] is String) return MutationResult.rejected;
        if (response == null && !observed.isCompleted) {
          return MutationResult.unconfirmed;
        }
        if (verify == null) return MutationResult.applied;
      } else if (!_send(event, fields)) {
        return MutationResult.disconnected;
      }
      final success = await observed.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (generation != _generation) return MutationResult.disconnected;

      return switch ((success, collection)) {
        (true, true) => MutationResult.queueChanged,
        (true, false) => MutationResult.applied,
        _ => MutationResult.unconfirmed,
      };
    } finally {
      await subscription?.cancel();
      if (generation == _generation) _mutationActive = false;
    }
  }

  @override
  Future<MutationResult> play(Catalog catalog, String id, Placement placement) {
    final before =
        _playback.queue?.items.map((item) => item.occurrence).toSet() ?? {};
    final event = switch (catalog) {
      Catalog.tracks => 'play-track',
      Catalog.albums => 'play-album',
      Catalog.playlists => 'play-playlist',
    };
    return _mutate(
      event,
      {'id': id, 'playType': placement.name},
      ack: true,
      collection: catalog != Catalog.tracks,
      verify: (queue) {
        return queue.items.any(
          (entry) =>
              (catalog != Catalog.tracks || entry.track.id == id) &&
              !before.contains(entry.occurrence) &&
              (placement != Placement.now || queue.current == entry.occurrence),
        );
      },
    );
  }

  @override
  Future<MutationResult> addToPlaylist(String trackId, String playlistId) =>
      _mutate('add-to-playlist', {
        'songId': trackId,
        'playlistId': playlistId,
      }, ack: true);

  @override
  Future<MutationResult> jump(String occurrence) =>
      _playback.queue?.current == occurrence
      ? Future.value(MutationResult.applied)
      : _mutate('queue-jump', {
          'uniqueId': occurrence,
        }, verify: (queue) => queue.current == occurrence);

  @override
  Future<MutationResult> remove(String occurrence) => _mutate(
    'remove-from-queue',
    {'uniqueId': occurrence},
    verify: (queue) =>
        queue.items.every((item) => item.occurrence != occurrence),
  );

  @override
  Future<MutationResult> move(
    String occurrence,
    String target, {
    required bool before,
  }) => _mutate(
    'reorder-queue',
    {
      'uniqueId': occurrence,
      'targetUniqueId': target,
      'edge': before ? 'top' : 'bottom',
    },
    verify: (queue) {
      final from = queue.items.indexWhere(
        (item) => item.occurrence == occurrence,
      );
      final to = queue.items.indexWhere((item) => item.occurrence == target);
      return from >= 0 && to >= 0 && from == to + (before ? -1 : 1);
    },
  );

  @override
  Future<MutationResult> clear() => _mutate(
    'clear-queue',
    const {},
    ack: true,
    verify: (queue) => queue.items.isEmpty,
  );

  Future<void> dispose() async {
    _retire();
    await _updates.close();
  }
}
