// ------------------------------
// event_diary_page.dart
// Καταγραφή Ημερολογίου Συμβάντων + Εξαγωγή με HTTP POST προς Google Apps Script
// ------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ---------------- Firestore ----------------
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Καταγραφή ημερολογίου συμβάντων'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Εξαγωγή σε Google Sheets',
            onPressed: () => _exportToSheets(context),
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
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final dt = (data['date'] as Timestamp).toDate();
              return ListTile(
                leading: Text(
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                title: Text(data['event'] ?? '—'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever_sharp),
                  onPressed: () => docs[i].reference.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, firstDay: _firstDayOfYear),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, {required DateTime firstDay}) {
    final eventCtrl = TextEditingController();

    DateTime? selectedDate;

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
                  initialDate: now.year == year ? now : firstDay,
                  lastDate: DateTime(year, 12, 31),
                );
                if (date == null || !ctx.mounted) return;
                setState(() => selectedDate = date);
              }

              final colorScheme = Theme.of(ctx).colorScheme;
              return AlertDialog(
                title: const Text('Νέο συμβάν'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //TextField(
                    //  controller: eventCtrl,
                    //  decoration: const InputDecoration(
                    //    labelText: 'Περιγραφή συμβάντος',
                    //  ),

                    //),
                    TextField(
                      controller: eventCtrl,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Περιγραφή συμβάντος',
                        labelStyle: TextStyle(color: colorScheme.primary),
                        filled: true,
                        fillColor:
                            Theme.of(ctx).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
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
                      if (eventCtrl.text.trim().isEmpty ||
                          selectedDate == null) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Συμπλήρωσε όλα τα πεδία'),
                          ),
                        );
                        return;
                      }
                      await _eventsRef().add({
                        'event': eventCtrl.text.trim(),
                        'date': Timestamp.fromDate(selectedDate!),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
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

  // ---------------- Εξαγωγή σε Google Sheets μέσω HTTP POST ----------------
  Future<void> _exportToSheets(BuildContext context) async {
    const webAppUrl = 'https://script.google.com/macros/s/ΤΟ_URL_ΣΟΥ/exec';

    try {
      final snapshot =
          await _eventsRef()
              .orderBy('date')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_firstDayOfYear),
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

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'records': data}),
      );

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(content: Text('✅ Εξαγωγή ολοκληρώθηκε!')),
        );
      } else {
        throw Exception('Σφάλμα από server: ${response.body}');
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
