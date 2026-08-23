import 'package:cloud_firestore/cloud_firestore.dart';

/// The Firestore database used by this app.
///
/// Japan Explorer now has its own dedicated Firebase project
/// (japanexplorer-4c1ea), so it uses that project's "(default)" database.
/// Kept as a shared accessor (rather than switching every call site back
/// to `FirebaseFirestore.instance`) so a future move to a named database
/// only requires a change here.
final db = FirebaseFirestore.instance;
