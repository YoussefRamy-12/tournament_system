import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import 'api_router.dart';

class TournamentServer {
  HttpServer? _server;

  Future<void> start() async {
    final handler = Pipeline()
        .addMiddleware(
          logRequests(),
        ) // Shows all incoming requests in your console
        .addHandler(ApiRouter().router.call);

    // Bind to 0.0.0.0 to listen to any device on the Wi-Fi
    // Port 8080 is standard and safe
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);

    // print('🚀 Server running on ${_server!.address.address}:${_server!.port}');
  }

  Future<void> stop() async {
    await _server?.close();
    // print('🛑 Server stopped');
  }
}
