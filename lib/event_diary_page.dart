// -----------------------------------------------------------------------------
// event_diary_page.dart (Flutter)
// Καταγραφή Ημερολογίου Συμβάντων + Εξαγωγή μέσω Cloud Function proxyExport
// -----------------------------------------------------------------------------
// ➤ Προϋποθέσεις
//    1. Firebase Core, Auth, Firestore έχουν αρχικοποιηθεί
//    2. Cloud Function proxyExport (Node 18, v2) είναι αναπτυγμένη και δημόσια
//    3. Ο proxy δέχεται JSON { uid, folderId, records, scriptUrl }
//       και προωθεί στο Apps Script Web App που δημιουργεί/ενημερώνει Spreadsheet
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'main.dart' show globalUid; // ↩︎ πάρε το UID ενεργού χρήστη
import 'mywidgets.dart'; // BorderedBox κ.λπ.

// ---------------------------  Config  ---------------------------
const proxyUrl = 'https://proxyexport-mhdemkezbq-uc.a.run.app';

const scriptUrl =
    'https://script.google.com/macros/s/AKfycbxEmDBWKZrEpDmKPg5cckGm5EfGRpF1dyQfJ9Kb22e0tuTUs2djtlKvy2G3Q3aoSfqv/exec';
// ----------------------------------------------------------------

CollectionReference<Map<String, dynamic>> _eventsRef(String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaryEvents');

class EventDiaryPage extends StatelessWidget {
  const EventDiaryPage({super.key, required this.year});
  final int year;

  DateTime get _firstDayOfYear => DateTime(year, 1, 1);

  @override
  Widget build(BuildContext context) {
    final uid = globalUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('⚠️ Ο χρήστης δεν είναι συνδεδεμένος')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Καταγραφή ημερολογίου συμβάντων'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Εξαγωγή σε Google Sheets',
            onPressed: () => _exportToSheets(context, uid, _firstDayOfYear),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _eventsRef(uid)
                .orderBy('date')
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(_firstDayOfYear),
                )
                .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Σφάλμα: ${snap.error}'));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Δεν υπάρχουν καταγραφές'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Προσθήκη συμβάντος'),
                    onPressed:
                        () => _showEventDialog(
                          context,
                          uid,
                          firstDay: _firstDayOfYear,
                        ),
                  ),
                ],
              ),
            );
          }

          return BorderedBox(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();
                final dt = (data['date'] as Timestamp).toDate();

                return ListTile(
                  title: Text(
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['event'] ?? '—'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed:
                            () => _showEventDialog(
                              context,
                              uid,
                              doc: doc,
                              firstDay: _firstDayOfYear,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_sharp, size: 20),
                        onPressed: () => doc.reference.delete(),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => _showEventDialog(context, uid, firstDay: _firstDayOfYear),
        child: const Icon(Icons.add),
      ),
    );
  }

  // -------------------- Dialogs --------------------

  void _showEventDialog(
    BuildContext context,
    String uid, {
    required DateTime firstDay,
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) {
    final isEdit = doc != null;
    final controller = TextEditingController(
      text: isEdit ? doc.data()!['event'] ?? '' : '',
    );
    DateTime? selectedDate =
        isEdit ? (doc.data()!['date'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setState) {
              Future<void> pickDate() async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: ctx,
                  useRootNavigator: false,
                  firstDate: firstDay,
                  initialDate:
                      selectedDate ?? (now.year == year ? now : firstDay),
                  lastDate: DateTime(year, 12, 31),
                );
                if (date == null || !ctx.mounted) return;
                setState(() => selectedDate = date);
              }

              return AlertDialog(
                title: Text(isEdit ? 'Επεξεργασία συμβάντος' : 'Νέο συμβάν'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Περιγραφή συμβάντος',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: pickDate,
                      child: Text(
                        selectedDate == null
                            ? 'Επιλογή ημερομηνίας'
                            : 'Επιλέχθηκε: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Ακύρωση'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty || selectedDate == null) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Συμπλήρωσε όλα τα πεδία'),
                          ),
                        );
                        return;
                      }
                      if (isEdit) {
                        await doc.reference.update({
                          'event': text,
                          'date': Timestamp.fromDate(selectedDate!),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await _eventsRef(uid).add({
                          'event': text,
                          'date': Timestamp.fromDate(selectedDate!),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Αποθήκευση'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // -------------------- Export --------------------

  Future<void> _exportToSheets(
    BuildContext context,
    String uid,
    DateTime firstDayOfYear,
  ) async {
    // 1. Βρες folderId από Firestore settings
    String? folderId;
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();
      folderId = (snap.data()?["googleFolder"] as String?) ?? '';
      folderId = folderId.isNotEmpty ? driveFolderIdFromUrl(folderId) : null;
    } catch (_) {}

    if (folderId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ Δεν έχει οριστεί φάκελος Drive.')),
        );
      }
      return;
    }

    // 2. Fetch όλα τα records του έτους
    final snapshot =
        await _eventsRef(uid)
            .orderBy('date')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfYear),
            )
            .get();

    final records =
        snapshot.docs.map((d) {
          final dt = (d['date'] as Timestamp).toDate();
          return {
            'date':
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
            'event': d['event'] ?? '',
          };
        }).toList();

    if (records.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ Δεν υπάρχουν δεδομένα προς εξαγωγή')),
        );
      }
      return;
    }

    // 3. Κάνε POST στον proxy
    try {
      final res = await http.post(
        Uri.parse(proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'folderId': folderId,
          'records': records,
          'scriptUrl': scriptUrl,
        }),
      );

      if (!context.mounted) return;
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Εξαγωγή ολοκληρώθηκε!')),
        );

        // logging export action
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('exports')
            .add({'timestamp': FieldValue.serverTimestamp()});
      } else {
        throw Exception('Server error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Σφάλμα εξαγωγής: $e')));
      }
    }
  }
}

// --------------------------- Helpers ---------------------------

/// Εξάγει το ID φακέλου από URL or ID string
String driveFolderIdFromUrl(String input) {
  final regex = RegExp(r'[-\w]{25,}');
  final match = regex.firstMatch(input);
  return match != null ? match[0]! : input;
}
