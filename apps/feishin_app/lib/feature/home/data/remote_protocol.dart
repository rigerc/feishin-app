import '../domain/remote.dart';

typedef WireObject = Map<String, dynamic>;

T enumValue<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((entry) => entry.name == value).firstOrNull ?? fallback;

Uri? artworkUri(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '::1') {
    return null;
  }
  return uri;
}

double? finiteNumber(Object? value) => switch (value) {
  final num number when number.isFinite => number.toDouble(),
  _ => null,
};

String? _string(Object? value) => value is String ? value : null;
int? _integer(Object? value) => finiteNumber(value)?.round();

Duration? trackDuration(Object? value) {
  final number = finiteNumber(value);
  if (number == null || number <= 0 || number > 604800000) return null;
  return Duration(milliseconds: number.round());
}

Duration? positionDuration(Object? value) {
  final number = finiteNumber(value);
  if (number == null || number < 0 || number > 604800) return null;
  return Duration(
    microseconds: (number * Duration.microsecondsPerSecond).round(),
  );
}

class RemoteTrackModel {
  const RemoteTrackModel(this.value);

  final WireObject value;

  Track? toEntity() {
    final id = _string(value['id']);
    final name = _string(value['name']);
    if (id == null || id.isEmpty || name == null) return null;
    return (
      id: id,
      name: name,
      artist:
          _string(value['artistName']) ??
          _string(value['albumArtistName']) ??
          '',
      album: _string(value['album']),
      serverId: _string(value['_serverId']),
      serverType: _string(value['_serverType']),
      occurrence: _string(value['_uniqueId']),
      duration: trackDuration(value['duration']),
      artwork: artworkUri(value['imageUrl']),
      favorite: value['userFavorite'] is bool
          ? value['userFavorite'] as bool
          : null,
      rating: _integer(value['userRating']),
      year: _integer(value['releaseYear']),
      songCount: _integer(value['songCount']),
    );
  }

  factory RemoteTrackModel.fromEntity(Track track) => RemoteTrackModel({
    'id': track.id,
    'name': track.name,
    'artistName': track.artist,
    'album': track.album,
    '_serverId': track.serverId,
    '_serverType': track.serverType,
    '_uniqueId': track.occurrence,
    'duration': track.duration?.inMilliseconds,
    'imageUrl': track.artwork?.toString(),
    'userFavorite': track.favorite,
    'userRating': track.rating,
    'releaseYear': track.year,
    'songCount': track.songCount,
  });
}

QueueSnapshot? decodeQueue(WireObject data) {
  final items = data['items'];
  final current = data['currentUniqueId'];
  if (items is! List ||
      items.length > 20000 ||
      (current != null && current is! String)) {
    return null;
  }
  final occurrences = <String>{};
  final result = <QueueEntry>[];
  for (final item in items) {
    if (item is! WireObject || item['uniqueId'] is! String) return null;
    final occurrence = item['uniqueId'] as String;
    final track = RemoteTrackModel(item).toEntity();
    if (track == null || occurrence.isEmpty || !occurrences.add(occurrence)) {
      return null;
    }
    result.add((occurrence: occurrence, track: track));
  }
  return (current: current as String?, items: List.unmodifiable(result));
}
