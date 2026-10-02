import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.status, this.detail);
  final int status;
  final dynamic detail;
  @override
  String toString() => '$detail';
}

class Api {
  Api(this.baseUrl, {http.Client? client}) : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  Future<http.Response> binary(
    String method,
    String path, {
    required String token,
    Uint8List? bytes,
    String contentType = 'image/png',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = contentType;
    if (bytes != null) request.bodyBytes = bytes;
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        jsonDecode(response.body)['detail'],
      );
    }
    return response;
  }

  Future<dynamic> call(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 8));
    final data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        data?['detail'] ?? 'Request failed',
      );
    }
    return data;
  }
}
