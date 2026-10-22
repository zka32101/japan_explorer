import 'dart:convert';

import 'package:http/http.dart' as http;

/// Why a deletion request did not go through.
enum AccountDeletionFailure {
  /// The sign-in is too old; the user must sign in again first.
  recentLoginRequired,

  /// The user dismissed the re-sign-in prompt.
  cancelled,

  /// Network, server or any other error.
  failed,
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.failure, [this.detail]);
  final AccountDeletionFailure failure;
  final String? detail;

  @override
  String toString() => 'AccountDeletionException($failure, $detail)';
}

/// Calls the `deleteAccount` Cloud Function (callable, asia-northeast1) over
/// plain HTTPS with the user's ID token, so no extra Firebase plugin is needed.
class AccountDeletionClient {
  AccountDeletionClient({http.Client? client, this.region = 'asia-northeast1'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String region;

  Uri endpoint(String projectId) =>
      Uri.https('$region-$projectId.cloudfunctions.net', '/deleteAccount');

  /// Returns normally when the account and its data were deleted.
  Future<void> deleteAccount({
    required String idToken,
    required String projectId,
  }) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            endpoint(projectId),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'data': <String, dynamic>{}}),
          )
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      throw AccountDeletionException(AccountDeletionFailure.failed, '$e');
    }
    if (res.statusCode == 200) return;

    String? message;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message = (body['error'] as Map<String, dynamic>?)?['message'] as String?;
    } catch (_) {}
    throw AccountDeletionException(
      message == 'recent-login-required'
          ? AccountDeletionFailure.recentLoginRequired
          : AccountDeletionFailure.failed,
      message ?? 'HTTP ${res.statusCode}',
    );
  }
}
