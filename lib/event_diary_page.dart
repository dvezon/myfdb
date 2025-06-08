// ------------------------------
// event_diary_page.dart
// Καταγραφή Ημερολογίου Συμβάντων + Εξαγωγή με HTTP POST προς Google Apps Script

// ------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'mywidgets.dart';

// ---------------- Firestore  ----------------
CollectionReference<Map<String, dynamic>> _eventsRef() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('diaryEvents');
}

class EventDiaryPage extends StatelessWidget {
  const EventDiaryPage({super.key, required this.year});
  final int year;
  DateTime get _firstDayOfYear => DateTime(year, 1, 1);

  @override
  Widget build(BuildContext context) {
    //final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Καταγραφή ημερολογίου συμβάντων'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Εξαγωγή σε Google Sheets',
            onPressed: () => _exportToSheets(context, _firstDayOfYear),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _eventsRef()
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
                        () =>
                            _showAddDialog(context, firstDay: _firstDayOfYear),
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
                  leading: Text(
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(data['event'] ?? '—'),
                  //tileColor: cs.surfaceContainerLowest,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- EDIT ----------
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Επεξεργασία',
                        onPressed: () => _showEditDialog(context, doc: doc),
                      ),
                      // ---------- DELETE ----------
                      IconButton(
                        icon: const Icon(Icons.delete_forever_sharp, size: 20),
                        tooltip: 'Διαγραφή',
                        onPressed: () => docs[i].reference.delete(),
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
        onPressed: () => _showAddDialog(context, firstDay: _firstDayOfYear),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------- Προσθήκη νέου συμβάντος ----------------
  void _showAddDialog(BuildContext context, {required DateTime firstDay}) {
    _showEventDialog(context, firstDay: firstDay);
  }

  // ---------------- Edit υπάρχοντος συμβάντος ----------------
  void _showEditDialog(
    BuildContext context, {
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data()!;
    _showEventDialog(
      context,
      firstDay: _firstDayOfYear,
      initialText: data['event'] ?? '',
      initialDate: (data['date'] as Timestamp).toDate(),
      onSave: (text, date) async {
        await doc.reference.update({
          'event': text,
          'date': Timestamp.fromDate(date),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
    );
  }

  // ---------------- Διαλογικό modal για Add / Edit ----------------
  void _showEventDialog(
    BuildContext context, {
    required DateTime firstDay,
    String initialText = '',
    DateTime? initialDate,

    Future<void> Function(String text, DateTime date)? onSave,
  }) {
    final textCtrl = TextEditingController(text: initialText);
    DateTime? selectedDate = initialDate;

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

              final cs = Theme.of(ctx).colorScheme;
              return AlertDialog(
                title: Text(
                  initialText.isEmpty ? 'Νέο συμβάν' : 'Επεξεργασία συμβάντος',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textCtrl,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Περιγραφή συμβάντος',
                        labelStyle: TextStyle(color: cs.primary),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                      final text = textCtrl.text.trim();
                      final date = selectedDate;
                      if (text.isEmpty || date == null) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Συμπλήρωσε όλα τα πεδία'),
                          ),
                        );
                        return;
                      }

                      // default save: ADD new entry
                      if (onSave == null) {
                        await _eventsRef().add({
                          'event': text,
                          'date': Timestamp.fromDate(date),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await onSave(text, date);
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

  Future<void> _exportToSheets(
    BuildContext context,
    DateTime firstDayOfYear,
  ) async {
    const webAppUrl =
        'https://script.google.com/macros/s/AKfycbxDji48s2N15OhSz_wvp_R0cZMVNoE0CjB9aWH53q-lqGN1PLjow5UPEKzfbnM3jOPOIA/exec';
    //print('🔗 URL προς αποστολή: $webAppUrl');
    try {
      final snapshot =
          await _eventsRef()
              .orderBy('date')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfYear),
              )
              .get();

      final data =
          snapshot.docs.map((doc) {
            final dt = (doc['date'] as Timestamp).toDate();
            final ev = doc['event'] ?? '';
            return {
              'date':
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
              'event': ev,
            };
          }).toList();

      if (data.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❗Δεν υπάρχουν δεδομένα προς εξαγωγή'),
            ),
          );
        }
        return;
      }

      final res = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'records': data}),
      );

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      // Ανίχνευση επιτυχίας
      if ((res.statusCode == 200 || res.statusCode == 302) &&
          res.body.trim().isNotEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('✅ Εξαγωγή ολοκληρώθηκε!')),
        );

        // Προαιρετική καταγραφή στο Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('exports')
            .add({'timestamp': FieldValue.serverTimestamp()});
      } else {
        // Αν πάρουμε HTML ή redirect, εμφάνισε κατάλληλο σφάλμα
        throw Exception('Σφάλμα από server: ${res.statusCode}\n${res.body}');
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
