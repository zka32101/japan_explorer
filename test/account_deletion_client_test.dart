import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:japan_explorer/services/account_deletion_client.dart';

void main() {
  test('POSTs the ID token to the regional deleteAccount endpoint', () async {
    late http.Request seen;
    final client = AccountDeletionClient(
      client: MockClient((req) async {
        seen = req;
        return http.Response(jsonEncode({'result': {'ok': true}}), 200);
      }),
    );
    await client.deleteAccount(idToken: 'tok', projectId: 'proj');
    expect(seen.method, 'POST');
    expect(seen.url.toString(),
        'https://asia-northeast1-proj.cloudfunctions.net/deleteAccount');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(seen.body), {'data': <String, dynamic>{}});
  });

  test('a stale sign-in is reported as recentLoginRequired', () async {
    final client = AccountDeletionClient(
      client: MockClient((_) async => http.Response(
          jsonEncode({
            'error': {
              'status': 'FAILED_PRECONDITION',
              'message': 'recent-login-required'
            }
          }),
          400)),
    );
    expect(
      client.deleteAccount(idToken: 't', projectId: 'p'),
      throwsA(isA<AccountDeletionException>().having(
          (e) => e.failure, 'failure', AccountDeletionFailure.recentLoginRequired)),
    );
  });

  test('server and network errors are reported as failed', () async {
    final serverError = AccountDeletionClient(
      client: MockClient((_) async => http.Response('oops', 500)),
    );
    expect(
      serverError.deleteAccount(idToken: 't', projectId: 'p'),
      throwsA(isA<AccountDeletionException>()
          .having((e) => e.failure, 'failure', AccountDeletionFailure.failed)),
    );
    final offline = AccountDeletionClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(
      offline.deleteAccount(idToken: 't', projectId: 'p'),
      throwsA(isA<AccountDeletionException>()
          .having((e) => e.failure, 'failure', AccountDeletionFailure.failed)),
    );
  });
}
