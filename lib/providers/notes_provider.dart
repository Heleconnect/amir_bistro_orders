import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import '../services/db_helper.dart';

class NotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Note> _notes = [];
  final List<Note> _pendingNotes = []; // 🕒 ملاحظات لم تُزامن بعد

  NotesProvider() {
    // ✅ تحميل الملاحظات عند البداية
    loadNotes();

    // ✅ الاستماع لتحديثات Firebase
    _firestore.collection("notes").snapshots().listen(_updateNotesFromFirebase);
  }

  List<Note> get notes => [..._notes];

  // ======================
  // تحميل الملاحظات (كلها)
  // ======================
  Future<void> loadNotes() async {
    // 🔹 تحميل محلي
    final localNotes = await DBHelper.getAllNotes();
    _notes
      ..clear()
      ..addAll(localNotes);

    // 🔹 تحميل من Firebase ودمج
    final snapshot = await _firestore.collection("notes").get();
    for (var doc in snapshot.docs) {
      final note = Note.fromJson(doc.data());
      if (!_notes.any((n) => n.id == note.id)) {
        _notes.add(note);
        await DBHelper.insertNote(note);
      }
    }

    notifyListeners();
  }

  // ======================
  // ملاحظات لطلب محدد
  // ======================
  List<Note> notesForOrder(int orderId) {
    return _notes.where((n) => n.orderId == orderId).toList();
  }

  // ======================
  // إضافة ملاحظة
  // ======================
  Future<void> addNote(Note note) async {
    _notes.add(note);
    notifyListeners();

    await DBHelper.insertNote(note);

    try {
      await _firestore.collection("notes").doc(note.id.toString()).set(note.toJson());
    } catch (_) {
      _pendingNotes.add(note);
    }
  }

  // ======================
  // تحديث ملاحظة
  // ======================
  Future<void> updateNote(Note note, String newContent) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;

    // ✅ تعديل نسخة جديدة بدلاً من التغيير على final
    final updatedNote = Note(
      id: note.id,
      content: newContent,
      orderId: note.orderId,
    );
    _notes[index] = updatedNote;
    notifyListeners();

    try {
      await _firestore
          .collection("notes")
          .doc(note.id.toString())
          .update({'content': newContent});
      await DBHelper.insertNote(updatedNote); // نحدث SQLite
    } catch (_) {
      _pendingNotes.add(updatedNote);
    }
  }

  // ======================
  // حذف ملاحظة
  // ======================
  Future<void> deleteNote(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();

    try {
      await _firestore.collection("notes").doc(note.id.toString()).delete();
    } catch (_) {}

    // 🔹 SQLite
    if (note.id != null) {
      await DBHelper.deleteNote(note.id!);
    }
  }

  // ======================
  // مسح كل الملاحظات
  // ======================
  Future<void> clearAllNotes() async {
    _notes.clear();
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection("notes").get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}

    await DBHelper.clearNotes();
  }

  // ======================
  // تحديثات Firebase
  // ======================
  void _updateNotesFromFirebase(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      final note = Note.fromJson(doc.data() as Map<String, dynamic>);
      final index = _notes.indexWhere((n) => n.id == note.id);

      if (index >= 0) {
        _notes[index] = note;
        await DBHelper.insertNote(note);
      } else {
        _notes.add(note);
        await DBHelper.insertNote(note);
      }
    }
    notifyListeners();
  }

  // ======================
  // مزامنة الملاحظات المعلقة
  // ======================
  Future<void> syncPendingNotes() async {
    for (var note in List<Note>.from(_pendingNotes)) {
      try {
        await _firestore
            .collection("notes")
            .doc(note.id.toString())
            .set(note.toJson());
        _pendingNotes.remove(note);
      } catch (_) {}
    }
  }
}