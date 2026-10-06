import 'dart:async';
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
  Api(
    this.baseUrl, {
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 8),
  }) : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  final Duration requestTimeout;

  Future<http.Response> _send(
    http.AbortableRequest request,
    Completer<void> abort,
    Duration timeout,
  ) async {
    try {
      return await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } finally {
      // Future.timeout alone leaves the socket/upload alive after retry starts.
      if (!abort.isCompleted) abort.complete();
    }
  }

  Never _throwError(http.Response response) {
    dynamic detail;
    try {
      final data = jsonDecode(response.body);
      if (data is Map) detail = data['detail'];
    } on FormatException {
      // Proxies may return plain text/HTML. Preserve the HTTP status, especially
      // 401, so the caller still retires an expired session. Do not show HTML.
    }
    throw ApiException(
      response.statusCode,
      detail ?? 'Request failed (${response.statusCode})',
    );
  }

  Future<http.Response> binary(
    String method,
    String path, {
    required String token,
    Uint8List? bytes,
    String contentType = 'image/png',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      method,
      Uri.parse('$baseUrl$path'),
      abortTrigger: abort.future,
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = contentType;
    if (bytes != null) request.bodyBytes = bytes;
    final response = await _send(request, abort, timeout);
    if (response.statusCode >= 400) {
      _throwError(response);
    }
    return response;
  }

  Future<dynamic> call(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
    Future<void>? cancellation,
  }) async {
    final abort = Completer<void>();
    cancellation?.then((_) {
      if (!abort.isCompleted) abort.complete();
    });
    final request = http.AbortableRequest(
      method,
      Uri.parse('$baseUrl$path'),
      abortTrigger: abort.future,
    );
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final response = await _send(request, abort, timeout ?? requestTimeout);
    if (response.statusCode >= 400) {
      _throwError(response);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
