// -----------------------------------------------------------------------------
// template_dropdown_page.dart
// Λίστα αρχείων με Edit • Delete • Export + κοινή φόρμα προβολής/επεξεργασίας
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mywidgets.dart';

// -----------------------------------------------------------------------------
// Config
// -----------------------------------------------------------------------------
const String scriptUrl =
    'https://script.google.com/macros/s/AKfycbxPhoA2y9NsvjALog2AGUG_66FTMGQWE7y0UpP_HJXKxORDGq8VJNxqrxkDIqocaziM/exec';

const String proxyExportUrl =
    'https://proxyexport-mhdemkezbq-uc.a.run.app'; // Cloud Function

const String defaultFolderId =
    '1gQCEPMZ5y4PJX9NW73qQHMejfHN-FPcL'; // fallback Drive folder

class TemplateDropdownPage extends StatefulWidget {
  const TemplateDropdownPage({super.key});
  @override
  State<TemplateDropdownPage> createState() => _TemplateDropdownPageState();
}

class _TemplateDropdownPageState extends State<TemplateDropdownPage> {
  // ---------------- Templates ----------------
  List<Map<String, String>> _templates = [];
  bool _loadingTemplates = true;
  String? _selectedFileId;
  String? _selectedName;

  // ---------------- Docs ----------------
  bool _loadingDocs = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedDoc;

  // ---------------- Form ----------------
  bool _showForm = false; // φόρμα ορατή
  bool _viewMode = false; // read-only φόρμα
  bool _saving = false;
  bool _editing = false;
  String? _editingDocId;

  final _filenameCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _selectedDate;

  // ---------------------------------------------------------------------------
  // Init – load templates
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      final res = await http.get(Uri.parse('$scriptUrl?action=listTemplates'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final List<dynamic> parsed = jsonDecode(res.body);
      final t =
          parsed
              .map<Map<String, String>>(
                (e) => {
                  'name': e['name'] as String,
                  'fileId': e['fileId'] as String,
                },
              )
              .toList()
            ..sort(
              (a, b) =>
                  a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
            );
      if (!mounted) return;
      setState(() {
        _templates = t;
        _loadingTemplates = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTemplates = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα templates: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // Load docs for selected template (client-side sort)
  // ---------------------------------------------------------------------------
  Future<void> _fetchDocsForTemplate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedFileId == null) return;

    setState(() {
      _loadingDocs = true;
      _docs = [];
      _selectedDoc = null;
    });

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('mydocs')
              .where('templateId', isEqualTo: _selectedFileId)
              .get();

      if (!mounted) return;

      final docs =
          snap.docs..sort((a, b) {
            final ta = a['createdAt'] as Timestamp?;
            final tb = b['createdAt'] as Timestamp?;
            return (tb?.millisecondsSinceEpoch ?? 0).compareTo(
              ta?.millisecondsSinceEpoch ?? 0,
            );
          });

      setState(() {
        _docs = docs;
        _loadingDocs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDocs = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα αρχείων: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // Helper:  Timestamp → ISO string   (recursive)
  // ---------------------------------------------------------------------------
  dynamic _jsonReady(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonReady(val)));
    }
    if (v is List) return v.map(_jsonReady).toList();
    return v;
  }

  // ---------------------------------------------------------------------------
  // Export (replace {{ids}} & save copy on Drive)
  // ---------------------------------------------------------------------------
  Future<void> _exportDoc(Map<String, dynamic> d) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Εξαγωγή…')));

    try {
      // Drive folder από settings
      final settingsSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();

      final rawFolder = settingsSnap.data()?['googleFolder'] as String?;
      final folderId =
          rawFolder != null && rawFolder.isNotEmpty
              ? _extractId(rawFolder)
              : defaultFolderId;

      final recordClean = Map<String, dynamic>.from(
        _jsonReady(d) as Map,
      ); // ασφαλής copy

      final payload = {
        'uid': uid,
        'folderId': folderId,
        'scriptUrl': scriptUrl,
        'templateId': _selectedFileId,
        'filename': d['filename'],
        'record': recordClean,
      };

      final res = await http.post(
        Uri.parse(proxyExportUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Εξαγωγή OK')));
      } else {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα εξαγωγής: $e')));
    }
  }

  String _extractId(String urlOrId) {
    final m = RegExp(r'[-\\w]{25,}').firstMatch(urlOrId);
    return m != null ? m[0]! : urlOrId;
  }

  // ---------------------------------------------------------------------------
  // Helpers φόρμας
  // ---------------------------------------------------------------------------
  void _populateForm(Map<String, dynamic> d) {
    _filenameCtrl.text = d['filename'] ?? '';
    _protocolCtrl.text = d['protocol'] ?? '';
    _subjectCtrl.text = d['subject'] ?? '';
    _contentCtrl.text = d['content'] ?? '';
    _selectedDate = (d['date'] as Timestamp?)?.toDate();
  }

  void _clearForm() {
    _filenameCtrl.clear();
    _protocolCtrl.clear();
    _subjectCtrl.clear();
    _contentCtrl.clear();
    _selectedDate = null;
  }

  Future<void> _pickDate() async {
    if (_viewMode) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ---------------------------------------------------------------------------
  // Delete doc
  // ---------------------------------------------------------------------------
  Future<void> _deleteDoc(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Διαγραφή'),
            content: const Text('Να διαγραφεί το αρχείο;'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Άκυρο'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Διαγραφή'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mydocs')
        .doc(docId)
        .delete();
    await _fetchDocsForTemplate();
  }

  // ---------------------------------------------------------------------------
  // Save (create or update)
  // ---------------------------------------------------------------------------
  Future<void> _saveDoc() async {
    if (_viewMode) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final filename = _filenameCtrl.text.trim();
    final protocol = _protocolCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final date = _selectedDate;

    if ([filename, protocol, subject, content].any((v) => v.isEmpty) ||
        date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Συμπλήρωσε όλα τα πεδία')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final settingsSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();

      final data = {
        'templateId': _selectedFileId,
        'templateName': _selectedName,
        'filename': filename,
        'protocol': protocol,
        'date': Timestamp.fromDate(date),
        'subject': subject,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        ...?settingsSnap.data(),
      };

      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mydocs');

      if (_editing) {
        await col.doc(_editingDocId).update(data);
      } else {
        await col.add(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Αποθηκεύτηκε')));

      await _fetchDocsForTemplate();
      setState(() => _showForm = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα αποθήκευσης: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
      _editing = false;
      _editingDocId = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Λίστα με μικρά εικονίδια (edit • delete • export)
  // ---------------------------------------------------------------------------
  Widget _listBox() {
    if (_loadingDocs) return const Center(child: CircularProgressIndicator());
    if (_docs.isEmpty) return const Center(child: Text('Δεν υπάρχουν αρχεία'));

    return ListView.separated(
      itemCount: _docs.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final d = _docs[i].data();
        final id = _docs[i].id;
        final selected = id == _selectedDoc?.id;

        final ts = d['date'] as Timestamp;
        final dateStr = DateFormat('dd/MM/yyyy  HH:mm:ss').format(ts.toDate());

        return Container(
          color: selected ? Colors.black12 : null,
          child: ListTile(
            title: Text(d['subject'] ?? ''), // 1η γραμμή
            subtitle: Text(
              // 2η γραμμή
              dateStr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              setState(() {
                _selectedDoc = _docs[i];
                _populateForm(d);
                _showForm = true;
                _viewMode = true;
              });
            },
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Επεξεργασία',
                  onPressed: () {
                    setState(() {
                      _selectedDoc = _docs[i];
                      _populateForm(d);
                      _showForm = true;
                      _viewMode = false;
                      _editing = true;
                      _editingDocId = id;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Διαγραφή',
                  onPressed: () => _deleteDoc(id),
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Εξαγωγή σε Drive',
                  onPressed: () => _exportDoc(d),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom box (φόρμα)
  // ---------------------------------------------------------------------------
  Widget _bottomBox() {
    if (!_showForm) {
      return const Center(child: Text('Επίλεξε αρχείο ή ➕ για νέο'));
    }

    final readOnly = _viewMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _filenameCtrl,
          decoration: const InputDecoration(labelText: 'Όνομα αρχείου'),
          readOnly: readOnly,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _protocolCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Αρ. Πρωτοκόλλου',
                        ),
                        readOnly: readOnly,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: readOnly ? null : _pickDate,
                        child: Text(
                          _selectedDate == null
                              ? 'Ημερομηνία'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Θέμα'),
                  readOnly: readOnly,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Περιεχόμενο'),
                  readOnly: readOnly,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!readOnly)
          ElevatedButton(
            onPressed: _saving ? null : _saveDoc,
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(_editing ? 'Ενημέρωση' : 'Αποθήκευση'),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Έγγραφα')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedFileId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Πρώτα επιλέξτε template')),
            );
            return;
          }
          setState(() {
            _showForm = true;
            _viewMode = false;
            _editing = false;
            _selectedDoc = null;
            _clearForm();
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown --------------------------------------------------------
            BorderedBox(
              child:
                  _loadingTemplates
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Επιλέξτε τύπο εγγράφου',
                        ),
                        value: _selectedFileId,
                        items:
                            _templates
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t['fileId'],
                                    child: Text(t['name']!),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) async {
                          setState(() {
                            _selectedFileId = val;
                            _selectedName =
                                _templates.firstWhere(
                                  (t) => t['fileId'] == val,
                                )['name'];
                            _showForm = false;
                            _selectedDoc = null;
                          });
                          await _fetchDocsForTemplate();
                        },
                      ),
            ),
            const SizedBox(height: 4),

            // List ------------------------------------------------------------
            Expanded(flex: 1, child: BorderedBox(child: _listBox())),
            const SizedBox(height: 4),

            // Form ------------------------------------------------------------
            Expanded(flex: 2, child: BorderedBox(child: _bottomBox())),
          ],
        ),
      ),
    );
  }
}
