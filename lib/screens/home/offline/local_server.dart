import 'dart:io';
import 'dart:convert';
import 'package:aims_admin/utils/local_storage.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'DataBaseHelper.dart';

class LocalServer {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  HttpServer? _server;

  Future<void> startServer() async {
    if (_server != null) {
      print('🚨 Server is already running.');
      return;
    }

    final handler = (Request request) async {
      final headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };

      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: headers);
      }

      try {
        if (request.url.path == 'items') {
          return await _handleItems(request, headers);
        } else if (request.url.pathSegments.length == 2 &&
            request.url.pathSegments[0] == 'items') {
          final id = int.tryParse(request.url.pathSegments[1]);
          return await _handleSingleItem(request, headers, id);
        }

        return Response.notFound('Not Found', headers: headers);
      } catch (e) {
        return Response.internalServerError(
          body: 'Error: ${e.toString()}',
          headers: headers,
        );
      }
    };

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      final serverIp = _server!.address.address;
      final port = _server!.port;

      // ✅ Save server IP to local storage
      await LocalStorage.saveServerIp(serverIp);

      print('✅ Server started at: http://$serverIp:$port');
    } catch (e) {
      print('❌ Failed to start server: $e');
      rethrow;
    }
  }


  Future<Response> _handleItems(Request request, Map<String, String> headers) async {
    switch (request.method) {
      case 'GET':
        final data = await _databaseHelper.getAllData();
        return Response.ok(
          jsonEncode(data),
          headers: {...headers, 'Content-Type': 'application/json'},
        );

      case 'POST':
        final payload = await request.readAsString();
        final itemData = jsonDecode(payload) as Map<String, dynamic>;
        final id = await _databaseHelper.insertData(itemData);
        return Response(
          HttpStatus.created,
          body: jsonEncode({...itemData, 'id': id}),
          headers: headers,
        );

      default:
        return Response(HttpStatus.methodNotAllowed, headers: headers);
    }
  }

  Future<Response> _handleSingleItem(
      Request request,
      Map<String, String> headers,
      int? id
      ) async {
    if (id == null) return Response(HttpStatus.badRequest, body: 'Invalid ID', headers: headers);

    switch (request.method) {
      case 'GET':
        final item = await _databaseHelper.getDataById(id);
        return item != null
            ? Response.ok(jsonEncode(item), headers: headers)
            : Response.notFound('Item not found', headers: headers);

      case 'PUT':
        final payload = await request.readAsString();
        final updateData = jsonDecode(payload) as Map<String, dynamic>;
        final success = await _databaseHelper.updateData(id, updateData);
        return success
            ? Response.ok(jsonEncode(await _databaseHelper.getDataById(id)), headers: headers)
            : Response.notFound('Item not found', headers: headers);

      case 'DELETE':
        final success = await _databaseHelper.deleteDataById(id);
        return success
            ? Response.ok('Item deleted', headers: headers)
            : Response.notFound('Item not found', headers: headers);

      default:
        return Response(HttpStatus.methodNotAllowed, headers: headers);
    }
  }

  bool isServerRunning() => _server != null;

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('🛑 Server stopped.');
    }
  }
}