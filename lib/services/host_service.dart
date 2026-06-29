import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/host_profile.dart';

const _hostsCollection = 'hosts';
const _requestsCollection = 'host_requests';

class HostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _logger = Logger();

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<HostProfile>> getHosts({
    String? city,
    String? interest,
    String? language,
    int limit = 20,
  }) async {
    try {
      Query query = _db
          .collection(_hostsCollection)
          .where('is_active', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      if (interest != null) {
        query = query.where('interests', arrayContains: interest);
      }
      if (language != null) {
        query = query.where('languages', arrayContains: language);
      }

      final snap = await query.get();
      return snap.docs
          .map((d) => HostProfile.fromFirestore(d))
          .toList();
    } catch (e) {
      _logger.e('Error fetching hosts', error: e);
      rethrow;
    }
  }

  Future<HostProfile?> getHost(String uid) async {
    try {
      final doc = await _db.collection(_hostsCollection).doc(uid).get();
      if (!doc.exists) return null;
      return HostProfile.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error fetching host $uid', error: e);
      rethrow;
    }
  }

  Future<bool> isRegisteredHost(String uid) async {
    final doc = await _db.collection(_hostsCollection).doc(uid).get();
    return doc.exists;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> registerHost(HostProfile profile) async {
    try {
      await _db
          .collection(_hostsCollection)
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      _logger.e('Error registering host ${profile.uid}', error: e);
      rethrow;
    }
  }

  Future<void> updateHost(HostProfile profile) async {
    try {
      await _db
          .collection(_hostsCollection)
          .doc(profile.uid)
          .update({
        ...profile.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating host ${profile.uid}', error: e);
      rethrow;
    }
  }

  Future<void> setHostActive(String uid, bool isActive) async {
    await _db.collection(_hostsCollection).doc(uid).update({
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Requests ──────────────────────────────────────────────────────────────

  Future<String> sendRequest(HostRequest request) async {
    try {
      final ref = await _db
          .collection(_requestsCollection)
          .add(request.toFirestore());
      return ref.id;
    } catch (e) {
      _logger.e('Error sending request', error: e);
      rethrow;
    }
  }

  /// Requests sent BY this user (as guest).
  Stream<List<HostRequest>> streamMyRequests(String guestUid) {
    return _db
        .collection(_requestsCollection)
        .where('guest_uid', isEqualTo: guestUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HostRequest.fromFirestore(d)).toList());
  }

  /// Requests received BY this host.
  Stream<List<HostRequest>> streamIncomingRequests(String hostUid) {
    return _db
        .collection(_requestsCollection)
        .where('host_uid', isEqualTo: hostUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HostRequest.fromFirestore(d)).toList());
  }

  Future<void> updateRequestStatus(
      String requestId, RequestStatus status) async {
    await _db
        .collection(_requestsCollection)
        .doc(requestId)
        .update({'status': status.name});
  }
}
