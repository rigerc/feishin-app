import 'dart:io';
import 'dart:typed_data';

final _client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

Future<Uint8List?> fetchArtwork(Uri uri) async {
  const maximum = 4 * 1024 * 1024;
  const deadline = Duration(seconds: 5);
  HttpClientRequest? request;
  try {
    request = await _client.getUrl(uri).timeout(deadline);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'image/*');
    final response = await request.close().timeout(deadline);
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > maximum ||
        response.headers.contentType?.primaryType != 'image') {
      request.abort();
      return null;
    }
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(deadline)) {
      if (buffer.length + chunk.length > maximum) {
        request.abort();
        return null;
      }
      buffer.add(chunk);
    }
    return buffer.takeBytes();
  } catch (_) {
    request?.abort();
    return null;
  }
}
