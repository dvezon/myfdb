import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mywidgets.dart';

// ---------------- Firestore ----------------
CollectionReference<Map<String, dynamic>> _appointmentsRef() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('appointments');
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Διαχείριση ραντεβού')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _appointmentsRef()
                .orderBy('dateTime')
                .where('dateTime', isGreaterThan: now)
                .limit(30)
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
                  const Text('Δεν υπάρχουν ραντεβού'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Νέο ραντεβού'),
                    onPressed: () => _showAppointmentDialog(context),
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
                final dt = (data['dateTime'] as Timestamp).toDate();

                return ListTile(
                  title: Text(data['title'] ?? '—'),
                  subtitle: Text(
                    '${dt.day}/${dt.month}/${dt.year}  '
                    '${dt.hour.toString().padLeft(2, "0")}:'
                    '${dt.minute.toString().padLeft(2, "0")}\n'
                    '${data['notes'] ?? ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---------- EDIT ----------
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Επεξεργασία',
                        onPressed:
                            () => _showAppointmentDialog(context, doc: doc),
                      ),
                      // ---------- DELETE ----------
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Διαγραφή',
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
        onPressed: () => _showAppointmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -------------------------------------------------------------------
// Dialog για προσθήκη *ή* επεξεργασία ραντεβού
// Αν doc == null → ADD, αλλιώς EDIT
// -------------------------------------------------------------------
void _showAppointmentDialog(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? doc,
}) {
  final data = doc?.data();
  final titleCtrl = TextEditingController(text: data?['title'] ?? '');
  final notesCtrl = TextEditingController(text: data?['notes'] ?? '');
  DateTime? selectedDateTime =
      data?['dateTime'] != null
          ? (data!['dateTime'] as Timestamp).toDate()
          : null;

  showDialog(
    context: context,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              // ημερομηνία
              final date = await showDatePicker(
                context: ctx,
                useRootNavigator: false,
                firstDate: now,
                initialDate: selectedDateTime ?? now,
                lastDate: DateTime(now.year + 5),
              );
              if (date == null || !ctx.mounted) return;
              // ώρα
              final time = await showTimePicker(
                context: ctx,
                useRootNavigator: false,
                initialTime:
                    selectedDateTime != null
                        ? TimeOfDay.fromDateTime(selectedDateTime!)
                        : TimeOfDay.fromDateTime(now),
              );
              if (time == null || !ctx.mounted) return;

              setState(() {
                selectedDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return AlertDialog(
              title: Text(
                doc == null ? 'Νέο ραντεβού' : 'Επεξεργασία ραντεβού',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Τίτλος'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Παρατηρήσεις',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: pickDateTime,
                    child: Text(
                      selectedDateTime == null
                          ? 'Επιλογή ημερομηνίας & ώρας'
                          : 'Επιλέχθηκε: '
                              '${selectedDateTime!.day}/${selectedDateTime!.month} '
                              '${selectedDateTime!.hour.toString().padLeft(2, "0")}:'
                              '${selectedDateTime!.minute.toString().padLeft(2, "0")}',
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
                    final title = titleCtrl.text.trim();
                    final dateTime = selectedDateTime;
                    if (title.isEmpty || dateTime == null) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Συμπλήρωσε όλα τα πεδία'),
                        ),
                      );
                      return;
                    }

                    if (doc == null) {
                      // --- ADD ---
                      await _appointmentsRef().add({
                        'title': title,
                        'notes': notesCtrl.text.trim(),
                        'dateTime': Timestamp.fromDate(dateTime),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      // --- EDIT ---
                      await doc.reference.update({
                        'title': title,
                        'notes': notesCtrl.text.trim(),
                        'dateTime': Timestamp.fromDate(dateTime),
                        'updatedAt': FieldValue.serverTimestamp(),
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
