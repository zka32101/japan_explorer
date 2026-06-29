import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../providers/auth_provider.dart';

// ── Hive cache ───────────────────────────────────────────────────────────────

class _JournalCache {
  static const _box = 'journal_entries';
  static Box<String>? _hive;

  static Future<Box<String>> _open() async {
    _hive ??= await Hive.openBox<String>(_box);
    return _hive!;
  }

  static Future<void> save(List<JournalEntry> entries) async {
    final box = await _open();
    await box.put('entries', json.encode(entries.map((e) => e.toMap()).toList()));
  }

  static Future<List<JournalEntry>> load() async {
    final box = await _open();
    final raw = box.get('entries');
    if (raw == null) return [];
    return (json.decode(raw) as List)
        .map((e) => JournalEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Firestore collection name ─────────────────────────────────────────────────

const _kJournalCol = 'journal_entries';

// ── State ────────────────────────────────────────────────────────────────────

class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;
  final String? error;

  const JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    String? error,
  }) =>
      JournalState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class JournalNotifier extends StateNotifier<JournalState> {
  final Ref _ref;

  JournalNotifier(this._ref) : super(const JournalState()) {
    _load();
  }

  String? get _uid => _ref.read(appUserProvider).valueOrNull?.uid;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_kJournalCol);

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      // Try Firestore first
      final uid = _uid;
      if (uid != null) {
        final snap = await _col(uid)
            .orderBy('visit_date', descending: true)
            .get();
        final entries =
            snap.docs.map(JournalEntry.fromFirestore).toList();
        await _JournalCache.save(entries);
        state = state.copyWith(entries: entries, isLoading: false);
        return;
      }
    } catch (_) {
      // Fall through to cache
    }

    // Offline fallback
    final cached = await _JournalCache.load();
    state = state.copyWith(entries: cached, isLoading: false);
  }

  Future<void> refresh() => _load();

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<void> createEntry({
    required String curationId,
    required String curationTitle,
    required String content,
    required JournalMood mood,
    required DateTime visitDate,
    File? imageFile,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    String imageUrl = '';
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref('journal/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final now = DateTime.now();
    final entry = JournalEntry(
      id: '',
      userId: uid,
      curationId: curationId,
      curationTitle: curationTitle,
      content: content,
      imageUrl: imageUrl,
      mood: mood,
      visitDate: visitDate,
      createdAt: now,
      updatedAt: now,
    );

    final doc = await _col(uid).add(entry.toFirestore());
    final saved = entry.copyWith();
    // Rebuild with real id
    final withId = JournalEntry(
      id: doc.id,
      userId: entry.userId,
      curationId: entry.curationId,
      curationTitle: entry.curationTitle,
      content: entry.content,
      imageUrl: entry.imageUrl,
      mood: entry.mood,
      visitDate: entry.visitDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );

    final updated = [withId, ...state.entries];
    await _JournalCache.save(updated);
    state = state.copyWith(entries: updated);
    saved.toString(); // suppress unused warning
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<void> updateEntry(
    String entryId, {
    String? content,
    JournalMood? mood,
    DateTime? visitDate,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final idx = state.entries.indexWhere((e) => e.id == entryId);
    if (idx < 0) return;

    final updated = state.entries[idx].copyWith(
      content: content,
      mood: mood,
      visitDate: visitDate,
      updatedAt: DateTime.now(),
    );

    await _col(uid).doc(entryId).update({
      if (content != null) 'content': content,
      if (mood != null) 'mood': mood.name,
      if (visitDate != null)
        'visit_date': Timestamp.fromDate(visitDate),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });

    final list = [...state.entries];
    list[idx] = updated;
    await _JournalCache.save(list);
    state = state.copyWith(entries: list);
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String entryId) async {
    final uid = _uid;
    if (uid == null) return;

    await _col(uid).doc(entryId).delete();
    final updated =
        state.entries.where((e) => e.id != entryId).toList();
    await _JournalCache.save(updated);
    state = state.copyWith(entries: updated);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>(
  (ref) => JournalNotifier(ref),
);

/// Entries filtered for a specific curation
final curationJournalProvider =
    Provider.family<List<JournalEntry>, String>((ref, curationId) {
  return ref
      .watch(journalProvider)
      .entries
      .where((e) => e.curationId == curationId)
      .toList();
});
