import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'token_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _http;
  final TokenStorageService _tokenStorage;
  final Future<void> Function()? onUnauthorized;
  Completer<void>? _refreshCompleter;

  ApiClient({
    http.Client? httpClient,
    TokenStorageService? tokenStorage,
    this.onUnauthorized,
  })  : _http = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorageService();

  Future<dynamic> get(String path, {bool authRequired = true}) {
    return _send(
      method: 'GET',
      path: path,
      authRequired: authRequired,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      authRequired: authRequired,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authRequired,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _buildHeaders(authRequired: authRequired);

    late http.Response response;
    try {
      if (method == 'GET') {
        response = await _http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else if (method == 'POST') {
        response = await _http
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      } else {
        throw const ApiException('Unsupported HTTP method');
      }
    } on TimeoutException {
      throw const ApiException(
        'Request timed out. Please check your connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Network error. Please check your connection and try again.',
      );
    }

    // Handle 401 with token refresh
    if (response.statusCode == 401 && authRequired && !isRetry && path != '/auth/refresh-jwt') {
      // If refresh is already in progress, wait for it to complete
      if (_refreshCompleter != null) {
        try {
          await _refreshCompleter!.future;
          // Retry request with new token
          return await _send(
            method: method,
            path: path,
            body: body,
            authRequired: authRequired,
            isRetry: true,
          );
        } catch (e) {
          // Refresh failed for another request, propagate appropriate error.
          if (_isConnectivityIssue(e)) {
            throw const ApiException(
              'No internet connection. Please check your network and try again.',
            );
          }
          await onUnauthorized?.call();
          throw const ApiException(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      // Start new refresh
      _refreshCompleter = Completer<void>();
      try {
        // Try to refresh the token
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResponse = await _http
              .post(
                Uri.parse('${ApiConfig.baseUrl}/auth/refresh-jwt'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonEncode({'refreshToken': refreshToken}),
              )
              .timeout(const Duration(seconds: 20));

          if (refreshResponse.statusCode == 200) {
            final refreshData = jsonDecode(refreshResponse.body);
            final newJwt = refreshData['jwt'] as String;
            final newRefreshToken = refreshData['refreshToken'] as String?;
            
            await _tokenStorage.saveJwt(newJwt);
            if (newRefreshToken != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('refresh_token', newRefreshToken);
            }
            
            _refreshCompleter!.complete();
            _refreshCompleter = null;

            // Retry original request with new token
            return await _send(
              method: method,
              path: path,
              body: body,
              authRequired: authRequired,
              isRetry: true,
            );
          }
        }
        
        // Refresh failed
        _refreshCompleter!.completeError(const ApiException('Token refresh failed'));
        _refreshCompleter = null;
        await onUnauthorized?.call();
        throw const ApiException('Session expired. Please login again.', statusCode: 401);
      } catch (e) {
        // Complete with error so waiting requests fail too
        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.completeError(e);
        }
        _refreshCompleter = null;

        if (_isConnectivityIssue(e)) {
          throw const ApiException(
            'No internet connection. Please check your network and try again.',
          );
        }

        // Refresh failed due to auth/session reason, trigger logout.
        await onUnauthorized?.call();
        throw const ApiException(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      }
    }

    return await _decodeResponse(response);
  }

  Future<Map<String, String>> _buildHeaders({required bool authRequired}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authRequired) {
      final jwt = await _tokenStorage.getJwt();
      if (jwt == null || jwt.isEmpty) {
        throw const ApiException('JWT token not found. Please login again.');
      }
      headers['Authorization'] = 'Bearer $jwt';
    }

    return headers;
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      if (body.isEmpty) {
        return null;
      }
      return jsonDecode(body);
    }

    // Handle unauthorized (JWT expired or invalid)
    if (status == 401) {
      await onUnauthorized?.call();
      // Throw a gentle error that won't be shown to user since they'll be redirected
      throw const ApiException('Session expired. Please login again.', statusCode: 401);
    }

    String message = 'Request failed with status $status';
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          message = (decoded['message'] as String?) ??
              (decoded['error'] as String?) ??
              message;
        }
      } catch (_) {
        message = body;
      }
    }

    throw ApiException(message, statusCode: status);
  }

  bool _isConnectivityIssue(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return true;
    }

    if (error is http.ClientException) {
      return true;
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable') ||
        message.contains('timed out') ||
        message.contains('timeout');
  }
}
