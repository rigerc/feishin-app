import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel openChannel(Uri endpoint) => IOWebSocketChannel.connect(
  endpoint,
  connectTimeout: const Duration(seconds: 5),
  pingInterval: const Duration(seconds: 15),
);
