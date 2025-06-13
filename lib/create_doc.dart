//
// ------------------------------------------------------------
// create_doc_page.dart (νέα έκδοση)
// Δημιουργία εγγράφου από επιλεγμένο template
// ------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'main.dart' show globalUid;

const proxyUrl = 'https://proxyexport-mhdemkezbq-uc.a.run.app';
const scriptUrl =
    'https://script.google.com/macros/s/AKfycbxdq-FIwWx6vokgGHIDvLQ5iXarjlfvLF4PlWTGn8DR9sStTDFwkNXJi22ZCOMDQUHg/exec';

CollectionReference<Map<String, dynamic>> _myDocsRef(String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mydocs');

class CreateDocPage extends StatefulWidget {
  const CreateDocPage({super.key});

  @override
  State<CreateDocPage> createState() => _CreateDocPageState();
}

class _CreateDocPageState extends State<CreateDocPage> {
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _filenameCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  List<Map<String, String>> _templates = [];
  List<DocumentSnapshot> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    final res = await http.get(Uri.parse('$scriptUrl?action=listTemplates'));
    if (res.statusCode == 200) {
      final List parsed = jsonDecode(res.body);
      setState(() {
        _templates = List<Map<String, String>>.from(parsed);
      });
    }
  }

  Future<void> _fetchHistory(String uid, String templateId) async {
    final snap =
        await _myDocsRef(uid)
            .where('templateId', isEqualTo: templateId)
            .orderBy('createdAt', descending: true)
            .get();
    setState(() => _history = snap.docs);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _saveDoc() async {
    final uid = globalUid;
    if (uid == null || _selectedTemplateId == null) return;

    final subject = _subjectCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final protocol = _protocolCtrl.text.trim();
    final filename = _filenameCtrl.text.trim();
    final date = _selectedDate;

    if ([subject, content, protocol, filename].any((v) => v.isEmpty) ||
        date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Συμπλήρωσε όλα τα πεδία')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef = await _myDocsRef(uid).add({
        'templateId': _selectedTemplateId,
        'templateName': _selectedTemplateName,
        'filename': filename,
        'record': {
          'subject': subject,
          'content': content,
          'protocol': protocol,
          'date': DateFormat('dd/MM/yyyy').format(date),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      final folderId = await _fetchDriveFolderId(uid);
      if (folderId == null) throw ('Δεν έχει οριστεί φάκελος Drive.');

      final payload = {
        'uid': uid,
        'folderId': folderId,
        'scriptUrl': scriptUrl,
        'templateId': _selectedTemplateId,
        'filename': filename,
        'record': {
          'docId': docRef.id,
          'subject': subject,
          'content': content,
          'date': DateFormat('dd/MM/yyyy').format(date),
          'protocol': protocol,
        },
      };

      final res = await http.post(
        Uri.parse(proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Δημιουργήθηκε επιτυχώς!')),
        );
        Navigator.pop(context);
      } else {
        throw ('Server error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Σφάλμα: $e')));
      }
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _fetchDriveFolderId(String uid) async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();
      final raw = snap.data()?['googleFolder'] as String?;
      return (raw != null && raw.isNotEmpty) ? driveFolderIdFromUrl(raw) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = globalUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('⚠️ Δεν υπάρχει χρήστης')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Νέο έγγραφο')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Πρότυπο'),
                        items:
                            _templates
                                .map(
                                  (tpl) => DropdownMenuItem(
                                    value: tpl['fileId'],
                                    child: Text(tpl['name'] ?? ''),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedTemplateId = val;
                            _selectedTemplateName =
                                _templates.firstWhere(
                                  (tpl) => tpl['fileId'] == val,
                                )['name'];
                          });
                          _fetchHistory(uid, val!);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_history.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📜 Ιστορικό αρχείων:'),
                            ..._history.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return ListTile(
                                title: Text(data['filename'] ?? 'χωρίς όνομα'),
                                subtitle: Text(
                                  (data['createdAt'] as Timestamp?)
                                          ?.toDate()
                                          .toString() ??
                                      '',
                                ),
                              );
                            }),
                            const Divider(),
                          ],
                        ),
                      TextField(
                        controller: _filenameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Όνομα αρχείου',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Θέμα'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Περιεχόμενο',
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _pickDate,
                              child: Text(
                                _selectedDate == null
                                    ? 'Επιλογή ημερομηνίας'
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _protocolCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Πρωτόκολλο',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveDoc,
                        icon: const Icon(Icons.save),
                        label: const Text('Αποθήκευση & Εξαγωγή'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

String driveFolderIdFromUrl(String input) {
  final regex = RegExp(r'[-\w]{25,}');
  final match = regex.firstMatch(input);
  return match != null ? match[0]! : input;
}
