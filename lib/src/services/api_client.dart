import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models.dart';

typedef SessionChanged = FutureOr<void> Function(AuthSession? session);

const _productionApiBaseUrl = 'https://apiapply.zabtec.co/api/v1';

const _localNetworkApiBaseUrl = String.fromEnvironment(
  'LOCAL_NETWORK_API_BASE_URL',
  defaultValue: '',
);

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;
  final List<dynamic> errors;

  @override
  String toString() => message;
}

class UploadFilePayload {
  const UploadFilePayload({
    required this.bytes,
    required this.filename,
    this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String? mimeType;
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    SessionChanged? onSessionChanged,
  }) : baseUrl = _resolveBaseUrl(baseUrl).replaceFirst(RegExp(r'/$'), ''),
       _http = httpClient ?? http.Client(),
       _onSessionChanged = onSessionChanged;

  final String baseUrl;
  final http.Client _http;
  final SessionChanged? _onSessionChanged;
  AuthSession? _session;

  AuthSession? get session => _session;

  static String _resolveBaseUrl(String? override) {
    if (override != null && override.trim().isNotEmpty) return override;

    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.trim().isNotEmpty) return configured;

    // Flutter web development should exercise the local backend by default.
    // Release builds continue to use the hosted production API below.
    if (kIsWeb && kDebugMode) {
      return 'http://127.0.0.1:5000/api/v1';
    }

    if (!kIsWeb && _localNetworkApiBaseUrl.trim().isNotEmpty) {
      return _localNetworkApiBaseUrl;
    }

    final appUri = Uri.base;
    if ((appUri.scheme == 'http' || appUri.scheme == 'https') &&
        appUri.host.isNotEmpty) {
      if (appUri.port == 8080) {
        return '${appUri.scheme}://${appUri.authority}/api/v1';
      }
    }

    return _productionApiBaseUrl;
  }

  void setSession(AuthSession? session) {
    _session = session;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    final clean = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null || value.toString().trim().isEmpty) continue;
      clean[entry.key] = value.toString();
    }
    return uri.replace(queryParameters: clean.isEmpty ? null : clean);
  }

  Future<AuthSession> register({
    required String fullName,
    required String cnic,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _jsonRequest(
      'POST',
      '/auth/register',
      auth: false,
      body: {
        'fullName': fullName,
        'cnic': cnic,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return _installSession(AuthSession.fromJson(_map(data)));
  }

  Future<AuthSession> login({
    String? cnic,
    String? email,
    required String password,
  }) async {
    final body = <String, dynamic>{'password': password};
    if (cnic != null) body['cnic'] = cnic;
    if (email != null) body['email'] = email;
    final data = await _jsonRequest(
      'POST',
      '/auth/login',
      auth: false,
      body: body,
    );
    return _installSession(AuthSession.fromJson(_map(data)));
  }

  Future<void> logout() async {
    final refresh = _session?.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _jsonRequest(
          'POST',
          '/auth/logout',
          auth: false,
          body: {'refreshToken': refresh},
        );
      }
    } finally {
      await _installNullableSession(null);
    }
  }

  Future<Account> fetchMe() async {
    final data = await _jsonRequest('GET', '/auth/me');
    final user = Account.fromJson(_map(data));
    final current = _session;
    if (current != null) {
      await _installSession(
        AuthSession(
          user: user,
          accessToken: current.accessToken,
          refreshToken: current.refreshToken,
        ),
      );
    }
    return user;
  }

  Future<ScholarshipApplication> getStudentApplication() async {
    final data = await _jsonRequest('GET', '/student/application');
    return ScholarshipApplication.fromJson(_map(data));
  }

  Future<ScholarshipApplication> getStudentStatus() async {
    final data = await _jsonRequest('GET', '/student/application/status');
    return ScholarshipApplication.fromJson(_map(data));
  }

  Future<Map<String, dynamic>> updatePersonal(Map<String, dynamic> payload) =>
      _jsonMap('PUT', '/student/application/personal', body: payload);

  Future<Map<String, dynamic>> updateFamily(Map<String, dynamic> payload) =>
      _jsonMap('PUT', '/student/application/family', body: payload);

  Future<Map<String, dynamic>> updateEducation(
    List<Map<String, dynamic>> entries,
  ) => _jsonMap(
    'PUT',
    '/student/application/education',
    body: {'entries': entries},
  );

  Future<Map<String, dynamic>> updateExperience(Map<String, dynamic> payload) =>
      _jsonMap('PUT', '/student/application/experience', body: payload);

  Future<Map<String, dynamic>> updateResearch(Map<String, dynamic> payload) =>
      _jsonMap('PUT', '/student/application/research', body: payload);

  Future<Map<String, dynamic>> submitApplication() =>
      _jsonMap('POST', '/student/application/submit');

  Future<List<StudentDocument>> getDocuments() async {
    final data = await _jsonRequest('GET', '/student/documents');
    return _list(
      data,
    ).map((item) => StudentDocument.fromJson(_map(item))).toList();
  }

  Future<StudentDocument> uploadDocument({
    required String documentType,
    required UploadFilePayload file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/student/documents/upload'),
    );
    request.headers.addAll(_authHeaders());
    request.fields['documentType'] = documentType;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes,
        filename: file.filename,
        contentType: _mediaTypeFor(file),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = await _decodeResponse(
      response,
      retry: () {
        return uploadDocument(
          documentType: documentType,
          file: file,
        ).then<Map<String, dynamic>>((doc) => docToJson(doc));
      },
    );

    if (data is StudentDocument) return data;
    return StudentDocument.fromJson(_map(data));
  }

  Future<void> deleteDocument(String id) async {
    await _jsonRequest('DELETE', '/student/documents/$id');
  }

  Future<void> deleteStudentAccount() async {
    await _jsonRequest('DELETE', '/student/account');
    await _installNullableSession(null);
  }

  Future<ActivationReceipt> processPayment({
    String method = 'bank_transfer',
    String? cardHolderName,
    String? cardNumber,
  }) async {
    final body = <String, dynamic>{'method': method};
    if (cardHolderName != null && cardHolderName.trim().isNotEmpty) {
      body['cardHolderName'] = cardHolderName.trim();
    }
    final digits = cardNumber?.replaceAll(RegExp(r'\D'), '');
    if (digits != null && digits.isNotEmpty) body['cardNumber'] = digits;

    final data = await _jsonRequest(
      'POST',
      '/student/payment/activate',
      body: body,
    );
    return ActivationReceipt.fromJson(_map(data), account: _requireUser());
  }

  Future<ActivationReceipt?> getReceipt() async {
    try {
      final data = await _jsonRequest('GET', '/student/payment/receipt');
      return ActivationReceipt.fromJson(_map(data), account: _requireUser());
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ActivationReceipt> uploadPaymentProof(UploadFilePayload file) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/student/payment/proof'),
    );
    request.headers.addAll(_authHeaders());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes,
        filename: file.filename,
        contentType: _mediaTypeFor(file),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = await _decodeResponse(
      response,
      retry: () => uploadPaymentProof(file),
    );
    if (data is ActivationReceipt) return data;
    return ActivationReceipt.fromJson(_map(data), account: _requireUser());
  }

  Future<SupportThread> getStudentSupport() async =>
      SupportThread.fromJson(await _jsonMap('GET', '/student/support'));

  Future<SupportMessage> sendStudentSupportMessage(String message) async =>
      SupportMessage.fromJson(
        await _jsonMap(
          'POST',
          '/student/support/messages',
          body: {'message': message.trim()},
        ),
      );

  Future<Map<String, dynamic>> adminDashboard() =>
      _jsonMap('GET', '/admin/dashboard');

  Future<Map<String, dynamic>> adminPaymentStats() =>
      _jsonMap('GET', '/admin/payment-stats');

  Future<Map<String, dynamic>> adminPayments({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) => _jsonMap(
    'GET',
    '/admin/payments',
    query: {'status': status, 'search': search, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> adminReviewPayment(
    String id, {
    required String status,
    String? rejectionReason,
    String? reviewNotes,
  }) {
    final body = <String, dynamic>{'status': status};
    if (rejectionReason != null) body['rejectionReason'] = rejectionReason;
    if (reviewNotes != null) body['reviewNotes'] = reviewNotes;
    return _jsonMap('PATCH', '/admin/payments/$id/review', body: body);
  }

  Future<Uint8List> adminPaymentProof(String id) =>
      _binaryRequest('/admin/payments/$id/proof');

  Future<Map<String, dynamic>> adminApplications({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) => _jsonMap(
    'GET',
    '/admin/applications',
    query: {'status': status, 'search': search, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> adminApplication(String id) =>
      _jsonMap('GET', '/admin/applications/$id');

  Future<Map<String, dynamic>> adminUpdateStatus(
    String id, {
    required String status,
    String? reviewNotes,
  }) {
    final body = <String, dynamic>{'status': status};
    if (reviewNotes != null) body['reviewNotes'] = reviewNotes;
    return _jsonMap('PATCH', '/admin/applications/$id/status', body: body);
  }

  Future<Map<String, dynamic>> adminStudents({
    String? search,
    int page = 1,
    int limit = 20,
  }) => _jsonMap(
    'GET',
    '/admin/students',
    query: {'search': search, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> adminStudent(String id) =>
      _jsonMap('GET', '/admin/students/$id');

  Future<Map<String, dynamic>> adminUsers({
    String? role,
    int page = 1,
    int limit = 20,
  }) => _jsonMap(
    'GET',
    '/admin/users',
    query: {'role': role, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> adminCreateStaff(Map<String, dynamic> payload) =>
      _jsonMap('POST', '/admin/users', body: payload);

  Future<Map<String, dynamic>> adminToggleUserStatus(String id) =>
      _jsonMap('PATCH', '/admin/users/$id/toggle-status');

  Future<List<SupportThread>> adminSupportThreads({
    String? search,
    String? status,
  }) async {
    final data = await _jsonMap(
      'GET',
      '/admin/support',
      query: {'search': search, 'status': status, 'limit': 100},
    );
    return _list(
      data['threads'],
    ).map((item) => SupportThread.fromJson(_map(item))).toList();
  }

  Future<SupportThread> adminSupportThread(String id) async =>
      SupportThread.fromJson(await _jsonMap('GET', '/admin/support/$id'));

  Future<SupportMessage> sendAdminSupportMessage(
    String id,
    String message,
  ) async => SupportMessage.fromJson(
    await _jsonMap(
      'POST',
      '/admin/support/$id/messages',
      body: {'message': message.trim()},
    ),
  );

  Future<void> updateAdminSupportStatus(String id, String status) async {
    await _jsonMap(
      'PATCH',
      '/admin/support/$id/status',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> hecDashboard() =>
      _jsonMap('GET', '/hec/dashboard');

  Future<Map<String, dynamic>> hecApplications({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) => _jsonMap(
    'GET',
    '/hec/applications',
    query: {'status': status, 'search': search, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> hecApplication(String id) =>
      _jsonMap('GET', '/hec/applications/$id');

  Future<Map<String, dynamic>> hecReviewApplication(
    String id, {
    required String status,
    String? reviewNotes,
  }) {
    final body = <String, dynamic>{'status': status};
    if (reviewNotes != null) body['reviewNotes'] = reviewNotes;
    return _jsonMap('PATCH', '/hec/applications/$id/review', body: body);
  }

  Future<Map<String, dynamic>> hecVerifyDocument(
    String docId, {
    required bool verified,
    String? rejectionReason,
  }) {
    final body = <String, dynamic>{'verified': verified};
    if (rejectionReason != null) body['rejectionReason'] = rejectionReason;
    return _jsonMap('PATCH', '/hec/documents/$docId/verify', body: body);
  }

  Future<Map<String, dynamic>> hecReports({String? from, String? to}) =>
      _jsonMap('GET', '/hec/reports', query: {'from': from, 'to': to});

  Future<Map<String, dynamic>> _jsonMap(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async => _map(
    await _jsonRequest(method, path, body: body, query: query, auth: auth),
  );

  Future<dynamic> _jsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool allowRefresh = true,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers.addAll({
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (auth) ..._authHeaders(),
    });
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(
      response,
      allowRefresh: auth && allowRefresh,
      retry: () => _jsonRequest(
        method,
        path,
        body: body,
        query: query,
        auth: auth,
        allowRefresh: false,
      ),
    );
  }

  Future<Uint8List> _binaryRequest(
    String path, {
    bool allowRefresh = true,
  }) async {
    final request = http.Request('GET', _uri(path));
    request.headers.addAll(_authHeaders());
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && allowRefresh) {
      final refreshed = await _refreshSession();
      if (refreshed) return _binaryRequest(path, allowRefresh: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) json = _map(decoded);
      } catch (_) {}
      throw ApiException(
        json['message']?.toString() ?? 'Could not load stamped challan',
        statusCode: response.statusCode,
        errors: _list(json['errors']),
      );
    }
    return response.bodyBytes;
  }

  Future<dynamic> _decodeResponse(
    http.Response response, {
    FutureOr<dynamic> Function()? retry,
    bool allowRefresh = true,
  }) async {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode == 401 && allowRefresh && retry != null) {
      final refreshed = await _refreshSession();
      if (refreshed) return retry();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final json = decoded is Map<String, dynamic> ? decoded : const {};
      throw ApiException(
        json['message']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
        errors: _list(json['errors']),
      );
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  Future<bool> _refreshSession() async {
    final current = _session;
    if (current == null || current.refreshToken.isEmpty) return false;
    try {
      final data = await _jsonRequest(
        'POST',
        '/auth/refresh-token',
        auth: false,
        allowRefresh: false,
        body: {'refreshToken': current.refreshToken},
      );
      final refreshed = AuthSession(
        user: current.user,
        accessToken: _map(data)['accessToken']?.toString() ?? '',
        refreshToken: _map(data)['refreshToken']?.toString() ?? '',
      );
      if (refreshed.accessToken.isEmpty || refreshed.refreshToken.isEmpty) {
        return false;
      }
      await _installSession(refreshed);
      return true;
    } catch (_) {
      await _installNullableSession(null);
      return false;
    }
  }

  Map<String, String> _authHeaders() {
    final token = _session?.accessToken;
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Account _requireUser() {
    final user = _session?.user;
    if (user == null) {
      throw const ApiException('You need to sign in again.');
    }
    return user;
  }

  Future<AuthSession> _installSession(AuthSession session) async {
    _session = session;
    await _onSessionChanged?.call(session);
    return session;
  }

  Future<void> _installNullableSession(AuthSession? session) async {
    _session = session;
    await _onSessionChanged?.call(session);
  }

  Map<String, dynamic> docToJson(StudentDocument doc) => {
    '_id': doc.id,
    'documentType': doc.documentType,
    'filename': doc.filename,
    'originalName': doc.originalName,
    'mimeType': doc.mimeType,
    'sizeBytes': doc.sizeBytes,
    'url': doc.url,
    'isVerified': doc.isVerified,
    if (doc.rejectionReason != null) 'rejectionReason': doc.rejectionReason,
    if (doc.createdAt != null) 'createdAt': doc.createdAt!.toIso8601String(),
  };

  MediaType? _mediaTypeFor(UploadFilePayload file) {
    final mimeType = file.mimeType ?? _mimeTypeFromFilename(file.filename);
    if (mimeType == null) return null;
    final parts = mimeType.split('/');
    if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
      return null;
    }
    return MediaType(parts.first.trim(), parts.last.trim());
  }

  String? _mimeTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> _list(Object? value) => value is List ? value : const [];
