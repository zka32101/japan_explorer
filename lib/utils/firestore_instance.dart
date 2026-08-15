import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// The Firestore database used by this app.
///
/// The Firebase project (app1-6c108) hosts multiple apps that share a
/// single project but not a single Firestore database — this app uses its
/// own named database ("japanexplorer"), separate from the project's
/// "(default)" and "fortune" databases used elsewhere. Always go through
/// this instance rather than `FirebaseFirestore.instance` (which points at
/// "(default)") so every read/write lands in the right place.
final db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'japanexplorer',
);
