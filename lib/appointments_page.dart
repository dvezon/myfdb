import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ----------  Βοηθητικό: συλλογή ραντεβού χρήστη  ----------
CollectionReference<Map<String, dynamic>> _appointmentsRef() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('appointments');
}

/// -------------  Κύρια οθόνη Διαχείρισης Ραντεβού -------------
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
                    onPressed: () => _showAddDialog(context),
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
              final dt = (data['dateTime'] as Timestamp).toDate();

              return ListTile(
                title: Text(data['title'] ?? '—'),
                subtitle: Text(
                  '${dt.day}/${dt.month}/${dt.year}  '
                  '${dt.hour.toString().padLeft(2, "0")}:'
                  '${dt.minute.toString().padLeft(2, "0")}\n'
                  '${data['notes'] ?? ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => docs[i].reference.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// -------------  Dialog για νέο ραντεβού -------------
void _showAddDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime? selectedDateTime;

  showDialog(
    context: context,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            /// Επιλογή ημερομηνίας & ώρας με ασφαλή χρήση context
            Future<void> pickDateTime() async {
              final now = DateTime.now();

              // ----- Ημερομηνία -----
              final date = await showDatePicker(
                context: ctx,
                useRootNavigator: false,
                firstDate: now,
                initialDate: now,
                lastDate: DateTime(now.year + 5),
              );
              if (date == null || !ctx.mounted) return;

              // ----- Ώρα -----
              final time = await showTimePicker(
                context: ctx,
                useRootNavigator: false,
                initialTime: TimeOfDay.fromDateTime(now),
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
              title: const Text('Νέο ραντεβού'),
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
                    // ---- Validation ----
                    if (titleCtrl.text.trim().isEmpty ||
                        selectedDateTime == null) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Συμπλήρωσε όλα τα πεδία'),
                        ),
                      );
                      return;
                    }

                    // ---- Αποθήκευση ----
                    await _appointmentsRef().add({
                      'title': titleCtrl.text.trim(),
                      'notes': notesCtrl.text.trim(),
                      'dateTime': Timestamp.fromDate(selectedDateTime!),
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
