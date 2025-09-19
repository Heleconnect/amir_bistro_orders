import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../utils/ui_helpers.dart';

class NotesScreen extends StatefulWidget {
  static const routeName = '/notes';

  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();

  void _showNoteDialog({Note? note}) {
    _controller.text = note?.content ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(note == null ? Icons.add : Icons.edit,
                color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(note == null ? "إضافة ملاحظة" : "تعديل الملاحظة"),
          ],
        ),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "الملاحظة",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_controller.text.trim().isEmpty) {
                UiHelper.showSnackBar(context, "❌ لا يمكن ترك الملاحظة فارغة", error: true);
                return;
              }

              final notesProvider = Provider.of<NotesProvider>(context, listen: false);

              if (note == null) {
                // 🟢 إضافة ملاحظة جديدة
                notesProvider.addNote(
                  Note(content: _controller.text.trim(), orderId: 0),
                );
                UiHelper.showSnackBar(context, "✅ تم إضافة الملاحظة");
              } else {
                // 🟢 تحديث ملاحظة موجودة
                notesProvider.updateNote(
                  note,
                  _controller.text.trim(),
                );
                UiHelper.showSnackBar(context, "✅ تم تعديل الملاحظة");
              }

              _controller.clear();
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save),
            label: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📝 إدارة الملاحظات المقترحة"),
        ),
        body: notesProvider.notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sticky_note_2, size: 80, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      "لا توجد ملاحظات بعد\nاضغط + لإضافة واحدة ✨",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notesProvider.notes.length,
                itemBuilder: (ctx, i) {
                  final note = notesProvider.notes[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.note, color: Colors.blue),
                      title: Text(note.content),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showNoteDialog(note: note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              notesProvider.deleteNote(note); // ✅ Note كامل
                              UiHelper.showSnackBar(context, "🗑️ تم حذف الملاحظة");
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNoteDialog(),
          icon: const Icon(Icons.add),
          label: const Text("إضافة ملاحظة"),
        ),
      ),
    );
  }
}