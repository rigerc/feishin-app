import 'dart:async';
import 'dart:convert';

import 'package:feishin_app/feature/home/data/feishin_repository.dart';
import 'package:feishin_app/feature/home/domain/remote.dart';
import 'package:feishin_app/feature/home/presentation/widgets/timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late _Socket socket;
  late FeishinRepository repository;

  final profile = RemoteProfile(
    id: 'desktop',
    name: 'Studio',
    endpoint: Uri.parse('ws://192.0.2.1:4333/'),
    username: 'tester',
  );
  const song = {
    'id': 'track',
    '_uniqueId': 'occurrence-1',
    'name': 'After Rain',
    'duration': 180000,
  };
  const queue = {
    'currentUniqueId': 'occurrence-1',
    'items': [
      {
        'id': 'track',
        'uniqueId': 'occurrence-1',
        'name': 'After Rain',
        'duration': 180000,
      },
      {
        'id': 'track',
        'uniqueId': 'occurrence-2',
        'name': 'After Rain',
        'duration': 180000,
      },
    ],
  };

  setUp(() {
    socket = _Socket();
    repository = FeishinRepository(channel: (_) => socket)
      ..setAutoReconnect(false);
  });
  tearDown(() => repository.dispose());

  Future<void> ready() async {
    final connecting = repository.connect(profile, 'fixture-secret');
    await _flush();
    socket.receive('state', {
      'song': song,
      'position': 12.25,
      'status': 'paused',
    });
    socket.receive('queue-state', queue);
    expect(await connecting, isTrue);
    await _flush();
  }

  test(
    'authenticates inside the socket and converts duration and position units',
    () async {
      await ready();
      expect(socket.sent.first, {
        'event': 'authenticate',
        'header': 'Basic ${base64Encode(utf8.encode('tester:fixture-secret'))}',
      });
      expect(
        repository.state.playback.track?.duration,
        const Duration(minutes: 3),
      );
      expect(
        repository.state.playback.position,
        const Duration(milliseconds: 12250),
      );
      repository.seek(
        const Duration(milliseconds: 60550),
        generation: repository.state.generation,
        occurrence: 'occurrence-1',
      );
      expect(socket.sent.last, {'event': 'position', 'position': 60.55});
    },
  );

  test('does not send a seek commit for a stale queue occurrence', () async {
    await ready();
    final count = socket.sent.length;
    socket.receive('queue-state', {
      ...queue,
      'currentUniqueId': 'occurrence-2',
    });
    await _flush();
    repository.seek(
      const Duration(seconds: 2),
      generation: repository.state.generation,
      occurrence: 'occurrence-1',
    );
    expect(socket.sent, hasLength(count));
    expect(repository.state.playback.occurrence, 'occurrence-2');
  });

  test(
    'jumps to a duplicate by occurrence and waits for a new snapshot',
    () async {
      await ready();
      final result = repository.jump('occurrence-2');
      expect(socket.sent.last, {
        'event': 'queue-jump',
        'uniqueId': 'occurrence-2',
      });
      socket.receive('queue-state', {
        ...queue,
        'currentUniqueId': 'occurrence-2',
      });
      expect(await result, MutationResult.applied);
    },
  );

  test('correlates browse and ignores a mismatched response', () async {
    await ready();
    final result = repository.browse(Catalog.tracks, 30, 'rain');
    final id = socket.sent.last['requestId'];
    expect(socket.sent.last['startIndex'], 30);
    expect(socket.sent.last['searchTerm'], 'rain');
    socket.receive('albums-response', {
      'requestId': id,
      'hasMore': false,
      'items': [],
    });
    socket.receive('tracks-response', {
      'requestId': id,
      'hasMore': false,
      'items': [song],
    });
    expect((await result)?.items.single.id, 'track');
  });

  test('waits for authoritative add evidence after a successful ack', () async {
    await ready();
    final pending = repository.play(Catalog.tracks, 'track', Placement.last);
    var completed = false;
    unawaited(pending.then((_) => completed = true));
    socket.receive('operation-ack', {
      'requestId': socket.sent.last['requestId'],
    });
    await _flush();
    expect(completed, isFalse);
    socket.receive('queue-state', {
      ...queue,
      'items': [
        ...queue['items']! as List<Map<String, Object>>,
        {'id': 'track', 'uniqueId': 'occurrence-3', 'name': 'After Rain'},
      ],
    });
    expect(await pending, MutationResult.applied);
  });

  test(
    'stops at a rejected authentication and fails pending work on disconnect',
    () async {
      final connecting = repository.connect(profile, 'incorrect');
      await _flush();
      await socket.finish(4004);
      expect(await connecting, isFalse);
      expect(repository.state.connection, Connection.authFailed);
      expect(await repository.browse(Catalog.tracks, 0, ''), isNull);
    },
  );

  test(
    'reports observed queue changes for a collection without claiming membership',
    () async {
      await ready();
      final result = repository.play(Catalog.albums, 'album', Placement.last);
      socket.receive('operation-ack', {
        'requestId': socket.sent.last['requestId'],
      });
      socket.receive('queue-state', {
        ...queue,
        'items': [
          ...queue['items']! as List<Map<String, Object>>,
          {
            'id': 'another-track',
            'uniqueId': 'occurrence-3',
            'name': 'Blue Hour',
          },
        ],
      });
      expect(await result, MutationResult.queueChanged);
    },
  );

  test('normalizes default ports and keeps selected transport explicit', () {
    expect(remoteEndpoint('studio.local', encrypted: false)?.port, 4333);
    expect(
      remoteEndpoint('studio.example/remote', encrypted: true)?.path,
      '/remote',
    );
    expect(remoteEndpoint('ws://studio.local', encrypted: true), isNull);
    expect(
      remoteEndpoint('user:secret@studio.local', encrypted: false),
      isNull,
    );
  });

  test('generates repeatable decorative peaks by track identity', () {
    final a = generatedPeaks('source:track-a', 72);
    expect(a, generatedPeaks('source:track-a', 72));
    expect(a, isNot(generatedPeaks('source:track-b', 72)));
    expect(a, everyElement(inInclusiveRange(0.0, 1.0)));
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Socket implements WebSocketChannel {
  final _incoming = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  int? _closeCode;

  @override
  int? get closeCode => _closeCode;

  @override
  Future<void> get ready => Future.value();

  @override
  Stream<String> get stream => _incoming.stream;

  @override
  late final WebSocketSink sink = _Sink(sent);

  void receive(String event, Object? data) =>
      _incoming.add(jsonEncode({'event': event, 'data': data}));

  Future<void> finish(int code) {
    _closeCode = code;
    return _incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sink implements WebSocketSink {
  _Sink(this.sent);

  final List<Map<String, dynamic>> sent;

  @override
  void add(dynamic data) =>
      sent.add(jsonDecode(data as String) as Map<String, dynamic>);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
