// lib/ui/template_dropdown_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';

import 'mylib/providers.dart'; // scriptUrl, driveServiceProvider, κ.λπ.
import 'mylib/mywidgets.dart'; // BorderedBox ή ό,τι άλλο έχεις

class TemplateDropdownPage extends ConsumerStatefulWidget {
  const TemplateDropdownPage({super.key});

  @override
  ConsumerState<TemplateDropdownPage> createState() =>
      _TemplateDropdownPageState();
}

class _TemplateDropdownPageState extends ConsumerState<TemplateDropdownPage> {
  // ─────────────────────────── FORM CONTROLLERS & UI FLAGS ────────────────
  final _filenameCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _selectedDate;

  bool _viewMode = false;
  bool _saving = false;
  bool _editing = false;
  String? _editingDocId;

  @override
  void dispose() {
    _filenameCtrl.dispose();
    _protocolCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────── HELPERS ────────────────────────────────────
  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ─────────────────────────── EXPORT DOC ─────────────────────────────────
  Future<void> _exportDoc(Map<String, dynamic> docData) async {
    final uid = ref.read(authUidProvider);
    final templateId = ref.read(selectedTemplateIdProvider);
    if (uid == null || templateId == null) return;

    _showSnack('Εξαγωγή…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // settings χρήστη
      final settingsSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();

      // DriveService μέσω provider
      final svc = ref.read(driveServiceProvider);
      await svc.exportDoc(
        uid: uid,
        templateId: templateId,
        docData: docData,
        userSettings: settingsSnap.data() ?? {},
      );

      if (!mounted) return;
      _showSnack('✅ Εξαγωγή επιτυχής');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Σφάλμα εξαγωγής: $e');
    } finally {
      if (mounted) Navigator.of(context).pop(); // κλείσε spinner
    }
  }

  // ─────────────────────────── SAVE DOC DEMO (απλή έκδοση) ────────────────
  Future<void> _saveDoc() async {
    if (_viewMode) return;
    final uid = ref.read(authUidProvider);
    final templateId = ref.read(selectedTemplateIdProvider);
    if (uid == null || templateId == null) return;

    final filename = _filenameCtrl.text.trim();
    final protocol = _protocolCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final date = _selectedDate;

    if ([filename, protocol, subject, content].any((v) => v.isEmpty) ||
        date == null) {
      _showSnack('❗ Συμπλήρωσε όλα τα πεδία');
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'templateId': templateId,
        'filename': filename,
        'protocol': protocol,
        'subject': subject,
        'content': content,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
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

      _showSnack('✅ Αποθήκευση OK');
      _clearForm();
    } catch (e) {
      _showSnack('Σφάλμα αποθήκευσης: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
      _editing = false;
      _editingDocId = null;
    }
  }

  // ─────────────────────────── BUILD ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final selectedTemplateId = ref.watch(selectedTemplateIdProvider);
    final uid = ref.watch(authUidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Έγγραφα')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedTemplateId == null) {
            _showSnack('Πρώτα επιλέξτε template');
            return;
          }
          setState(() {
            _viewMode = false;
            _editing = false;
            _editingDocId = null;
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
            // ───────── DROP-DOWN (Templates) ─────────
            BorderedBox(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Σφάλμα: $e'),
                data: (templates) {
                  final currentId =
                      selectedTemplateId ?? templates.first['fileId'];
                  // αρχικοποίηση provider (μόνο την 1η φορά)
                  ref.read(selectedTemplateIdProvider.notifier).state ??=
                      currentId;

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Επιλέξτε τύπο εγγράφου',
                    ),
                    value: currentId,
                    items:
                        templates
                            .map(
                              (t) => DropdownMenuItem(
                                value: t['fileId'],
                                child: Text(t['name']!),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) =>
                            ref
                                .read(selectedTemplateIdProvider.notifier)
                                .state = val,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // ───────── DOCS LIST ─────────
            Expanded(
              child:
                  uid == null || selectedTemplateId == null
                      ? const Center(child: Text('—'))
                      : DocsList(
                        uid: uid,
                        templateId: selectedTemplateId,
                        onExport: _exportDoc,
                        onEdit: (data, id) {
                          setState(() {
                            _populateForm(data);
                            _viewMode = false;
                            _editing = true;
                            _editingDocId = id;
                          });
                        },
                        onView: (data) {
                          setState(() {
                            _populateForm(data);
                            _viewMode = true;
                          });
                        },
                      ),
            ),
            const SizedBox(height: 8),
            // ───────── ΑΠΛΗ ΦΟΡΜΑ (demo) ─────────
            BorderedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _filenameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Όνομα αρχείου',
                    ),
                    readOnly: _viewMode,
                  ),
                  TextField(
                    controller: _protocolCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Αρ. Πρωτοκόλλου',
                    ),
                    readOnly: _viewMode,
                  ),
                  TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Θέμα'),
                    readOnly: _viewMode,
                  ),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Περιεχόμενο'),
                    readOnly: _viewMode,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _viewMode ? null : _pickDate,
                    child: Text(
                      _selectedDate == null
                          ? 'Ημερομηνία'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_viewMode)
                    ElevatedButton(
                      onPressed: _saving ? null : _saveDoc,
                      child:
                          _saving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(_editing ? 'Ενημέρωση' : 'Αποθήκευση'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── DocsList Widget ──────────────────────────────
class DocsList extends ConsumerWidget {
  const DocsList({
    super.key,
    required this.uid,
    required this.templateId,
    required this.onExport,
    required this.onEdit,
    required this.onView,
  });

  final String uid;
  final String templateId;
  final void Function(Map<String, dynamic>) onExport;
  final void Function(Map<String, dynamic>, String id) onEdit;
  final void Function(Map<String, dynamic>) onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(
      FutureProvider.autoDispose((ref) {
        final svc = ref.watch(driveServiceProvider);
        return svc.fetchDocs(uid: uid, templateId: templateId);
      }),
    );

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Σφάλμα: $e'),
      data:
          (docs) => ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (ctx, i) {
              final data = docs[i].data();
              final id = docs[i].id;
              final ts = data['date'] as Timestamp;
              return ListTile(
                title: Text(data['subject'] ?? ''),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(ts.toDate()),
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                onTap: () => onView(data),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => onEdit(data, id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      onPressed: () => onExport(data),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

/*// -----------------------------------------------------------------------------
// template_dropdown_page.dart  (με bug-fix για το templateId)
// Λίστα εγγράφων (Edit • Delete • Export) + φόρμα δημιουργίας/προβολής
// -----------------------------------------------------------------------------
//  • Τα settings του χρήστη (π.χ. typLine1, schoolAddr …) διαβάζονται
//    από /users/<uid>/settings/app  και στέλνονται μαζί με τα πεδία φόρμας.
//  • Έτσι όλα τα {{placeholders}} του template αντικαθίστανται.
// -----------------------------------------------------------------------------
//  Για άνοιγμα του URL μετά την εξαγωγή — αν το θες —
//  πρόσθεσε στο pubspec.yaml το url_launcher (^6.2.5) και άφησε το import.
//
//  dependencies:
//    url_launcher: ^6.2.5
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import import
import 'package:url_launcher/url_launcher.dart';

// import 'package:url_launcher/url_launcher.dart';   // ← προαιρετικό
import 'mylib/mywidgets.dart';

// -----------------------------------------------------------------------------
// Config
// -----------------------------------------------------------------------------
const String scriptUrl =
    'https://script.google.com/macros/s/AKfycbzNZv85DPuXnNgaM_4nS8sg5k9XT9gtSWC5LpK7H4uWUj3BYYc5G39Qzcq_PYtPsI-f/exec';
const String proxyExportUrl = 'https://proxyexport-mhdemkezbq-uc.a.run.app';
const String defaultFolderId = '1gQCEPMZ5y4PJX9NW73qQHMejfHN-FPcL';

// -----------------------------------------------------------------------------
// Page
// -----------------------------------------------------------------------------
class TemplateDropdownPage extends StatefulWidget {
  const TemplateDropdownPage({super.key});
  @override
  State<TemplateDropdownPage> createState() => _TemplateDropdownPageState();
}

class _TemplateDropdownPageState extends State<TemplateDropdownPage> {
  //──────────────────────────────── TEMPLATES ──────────────────────────────
  List<Map<String, String>> _templates = [];
  bool _loadingTemplates = true;
  String? _selectedFileId;
  String? _selectedName;

  //──────────────────────────────── DOCS ────────────────────────────────────
  bool _loadingDocs = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  // ignore: unused_field
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedDoc;

  //──────────────────────────────── FORM ────────────────────────────────────
  bool _showForm = false;
  bool _viewMode = false;
  bool _saving = false;
  bool _editing = false;
  String? _editingDocId;

  final _filenameCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _filenameCtrl.dispose();
    _protocolCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  //────────────────────────────── INIT / FETCH TEMPLATES ───────────────────
  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      final res = await http
          .get(Uri.parse('$scriptUrl?action=listTemplates'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      final List<dynamic> raw =
          (decoded is Map &&
                  decoded['ok'] == true &&
                  decoded['templates'] is List)
              ? decoded['templates']
              : throw const FormatException('Bad schema');

      final t =
          raw
              .map<Map<String, String>>(
                (e) => {
                  'name': e['name'].toString(),
                  'fileId': e['fileId'].toString(),
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

        // ► αν δεν έχει επιλεγεί template, επέλεξε το πρώτο
        if (_selectedFileId == null && _templates.isNotEmpty) {
          _selectedFileId = _templates.first['fileId'];
          _selectedName = _templates.first['name'];
          _fetchDocsForTemplate();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTemplates = false);
      _showErrorDialog('Σφάλμα template: $e', _fetchTemplates);
    }
  }

  //────────────────────────────── FETCH DOCS (client-side sort) ────────────
  Future<void> _fetchDocsForTemplate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedFileId == null) return;

    setState(() => _loadingDocs = true);

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('mydocs')
              .where('templateId', isEqualTo: _selectedFileId)
              .get();

      final docs =
          snap.docs..sort((a, b) {
            final ta = a['createdAt'] as Timestamp?;
            final tb = b['createdAt'] as Timestamp?;
            return (tb?.millisecondsSinceEpoch ?? 0).compareTo(
              ta?.millisecondsSinceEpoch ?? 0,
            );
          });

      if (!mounted) return;
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

  //────────────────────────────── JSON helper ───────────────────────────────
  // ignore: unused_element
  dynamic _jsonReady(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonReady(val)));
    }
    if (v is List) return v.map(_jsonReady).toList();
    return v;
  }

  // ---------------------------------------------------------------------------
  // EXPORT – στέλνει ΜΟΝΟ τα keys του template
  // ---------------------------------------------------------------------------

  // …

  Future<void> _exportDoc(Map<String, dynamic> docData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ► modal spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      /* 1.  placeholders του template */
      final keysRes = await http.get(
        Uri.parse(
          '$scriptUrl?action=listKeys&templateId=${Uri.encodeComponent(_selectedFileId ?? '')}',
        ),
      );
      final decodedKeys = jsonDecode(keysRes.body);
      if (decodedKeys['ok'] != true) throw 'listKeys error: ${keysRes.body}';
      final List<String> keys = List<String>.from(decodedKeys['keys']);

      /* 2.  settings χρήστη */
      final settingsSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('settings')
              .doc('app')
              .get();
      final settings = settingsSnap.data() ?? {};

      /* 3.  πεδία φόρμας */
      final formFields = {
        'subject': docData['subject'],
        'title': docData['subject'],
        'protocol': docData['protocol'],
        'date': DateFormat(
          'dd/MM/yyyy',
        ).format((docData['date'] as Timestamp).toDate()),
      };

      /* 4.  record ΜΟΝΟ με τα ζητούμενα keys */
      final record = <String, dynamic>{};
      for (final k in keys) {
        if (formFields.containsKey(k)) {
          record[k] = formFields[k];
        } else if (settings.containsKey(k)) {
          record[k] = settings[k];
        } else {
          record[k] = 'ΑΓΝΩΣΤΟ:$k';
        }
      }

      /* 5.  φάκελος προορισμού */
      final folderId = _extractId(
        (settings['googleFolder'] as String?) ?? defaultFolderId,
      );

      final payload = {
        'uid': uid,
        'folderId': folderId,
        'scriptUrl': scriptUrl,
        'templateId': _selectedFileId,
        'filename': docData['filename'],
        'record': record,
      };

      final res = await http.post(
        Uri.parse(proxyExportUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final decodedExport = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 && decodedExport['ok'] == true) {
        // ► άνοιγμα εγγράφου
        /*final urlStr = decodedExport['url']?.toString();
        if (urlStr != null && urlStr.isNotEmpty) {
          final uri = Uri.parse(urlStr);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        */
        

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Εξαγωγή επιτυχής')));
      } else {
        throw 'export error: HTTP ${res.statusCode} → ${res.body}';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα εξαγωγής: $e')));
    } finally {
      // ► κλείσιμο spinner ό,τι κι αν έγινε
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Helper – εξάγει το ID από URL ή επιστρέφει άθικτο το ID
  // ---------------------------------------------------------------------------
  String _extractId(String input) =>
      RegExp(r'[-\w]{25,}').firstMatch(input)?.group(0) ?? input;

  // ---------------------------------------------------------------------------
  // Φόρμα – populate / clear / pickDate
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ---------------------------------------------------------------------------
  // Delete document
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
  // Save (add ή update)
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
      final data = {
        'templateId': _selectedFileId,
        'templateName': _selectedName,
        'filename': filename,
        'protocol': protocol,
        'subject': subject,
        'content': content,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
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
  // Λίστα αρχείων
  // ---------------------------------------------------------------------------
  Widget _listBox() {
    if (_loadingDocs) return const Center(child: CircularProgressIndicator());
    if (_docs.isEmpty) return const Center(child: Text('Δεν υπάρχουν αρχεία'));

    return ListView.separated(
      itemCount: _docs.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final data = _docs[i].data();
        final id = _docs[i].id;
        final ts = data['date'] as Timestamp;
        final dateStr = DateFormat('dd/MM/yyyy  HH:mm:ss').format(ts.toDate());

        return ListTile(
          title: Text(data['subject'] ?? ''),
          subtitle: Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
          onTap: () {
            setState(() {
              _selectedDoc = _docs[i];
              _populateForm(data);
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
                    _populateForm(data);
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
                onPressed: () => _exportDoc(data),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Κάτω πλαίσιο (φόρμα / preview)
  // ---------------------------------------------------------------------------
  Widget _bottomBox() {
    if (!_showForm) {
      return const Center(child: Text('Επίλεξε αρχείο ή (+) για νέο'));
    }

    final ro = _viewMode; // readOnly

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _filenameCtrl,
          decoration: const InputDecoration(labelText: 'Όνομα αρχείου'),
          readOnly: ro,
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
                        readOnly: ro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: ro ? null : _pickDate,
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
                  readOnly: ro,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Περιεχόμενο'),
                  readOnly: ro,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!ro)
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
            Expanded(flex: 1, child: BorderedBox(child: _listBox())),
            const SizedBox(height: 4),
            Expanded(flex: 2, child: BorderedBox(child: _bottomBox())),
          ],
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Helper: εμφανίζει AlertDialog σφάλματος + προαιρετικό κουμπί Retry
  //------------------------------------------------------------------------------
  Future<void> _showErrorDialog(String message, [VoidCallback? onRetry]) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Σφάλμα σύνδεσης'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onRetry();
                  },
                  child: const Text('Retry'),
                ),
            ],
          ),
    );
  }
}
*/
