import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mylib/mywidgets.dart';
import 'mylib/providers.dart';

// ──────────────────────────────────────────────────────────────
// page
// ──────────────────────────────────────────────────────────────
class TemplateDropdownPage extends ConsumerStatefulWidget {
  const TemplateDropdownPage({super.key});
  @override
  ConsumerState<TemplateDropdownPage> createState() =>
      _TemplateDropdownPageState();
}

class _TemplateDropdownPageState extends ConsumerState<TemplateDropdownPage> {
  // ---------- controllers ----------
  final _filenameCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _receiversCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _selectedDate;

  DateTime? _dateAitisis;

  final _genArtCtrl = TextEditingController();
  final _genEndiafCtrl = TextEditingController();
  final _employCtrl = TextEditingController();

  final _eidikotitaCtrl = TextEditingController();
  final _numDaysCtrl = TextEditingController();
  DateTime? _dateFromCtrl;
  DateTime? _dateToCtrl;

  //{{gen}} {{eployName}}{{eidikotita}} {{schoolNameGen}}{{numDays}} {{dateFrom}} {{dateTo}}.

  // ---------- UI flags ----------
  bool _showForm = false;
  bool _viewMode = false;
  bool _editing = false;
  bool _saving = false;
  String? _editingDocId;

  // ---------- helpers ----------
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _populateForm(Map<String, dynamic> d) {
    _filenameCtrl.text = d['filename'] ?? '';
    _protocolCtrl.text = d['protocol'] ?? '';
    _receiversCtrl.text = d['receivers'] ?? '';
    _subjectCtrl.text = d['subject'] ?? '';
    _contentCtrl.text = d['content'] ?? '';
    _selectedDate = (d['date'] as Timestamp?)?.toDate();

    _dateAitisis = (d['dateAitisis'] as Timestamp?)?.toDate();
    _genEndiafCtrl.text = d['male-female-endiaf'] ?? '';

    _genArtCtrl.text = d['genArt'] ?? '';
    _employCtrl.text = d['eployName'] ?? '';
    _eidikotitaCtrl.text = d['eidikotita'] ?? '';
    _numDaysCtrl.text = d['numDays'] ?? '';
    _dateFromCtrl = (d['dateFrom'] as Timestamp?)?.toDate();
    _dateToCtrl = (d['dateTo'] as Timestamp?)?.toDate();
  }

  void _clearForm() {
    _filenameCtrl.clear();
    _protocolCtrl.clear();
    _receiversCtrl.clear();
    _subjectCtrl.clear();
    _contentCtrl.clear();
    _selectedDate = null;

    _dateAitisis = null;
    _genArtCtrl.clear();
    _genEndiafCtrl.clear();
    _employCtrl.clear();

    _eidikotitaCtrl.clear();
    _numDaysCtrl.clear();
    _dateFromCtrl = null;
    _dateToCtrl = null;
  }

  Future<void> _pickDateGeneric(
    DateTime? current,
    void Function(DateTime) set,
  ) async {
    if (_viewMode) return;
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (d != null) setState(() => set(d));
  }

  // ---------- save / delete ----------
  Future<void> _saveDoc() async {
    if (_viewMode) return;

    final uid = ref.read(authUidProvider);
    final templateId = ref.read(selectedTemplateIdProvider);
    if (uid == null || templateId == null) return;

    final missing = <String>[];
    final templateName = ref.read(selectedTemplateNameProvider);

    // Αυτόματη παραγωγή subject/filename αν λείπει
    final employee = _employCtrl.text.trim();
    final dateStr =
        _selectedDate != null
            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
            : '';
    final autoSubject = '$employee $templateName $dateStr';
    if (_subjectCtrl.text.trim().isEmpty) _subjectCtrl.text = autoSubject;
    if (_filenameCtrl.text.trim().isEmpty) _filenameCtrl.text = autoSubject;

    // Έλεγχος πεδίων ανά template
    switch (templateName) {
      case 'Απλό Έγγραφο':
        if (_filenameCtrl.text.trim().isEmpty) missing.add('Όνομα αρχείου');
        if (_protocolCtrl.text.trim().isEmpty) missing.add('Αρ. Πρωτοκόλλου');
        if (_receiversCtrl.text.trim().isEmpty) missing.add('Παραλήπτες');
        if (_subjectCtrl.text.trim().isEmpty) missing.add('Θέμα');
        if (_contentCtrl.text.trim().isEmpty) missing.add('Περιεχόμενο');
        if (_selectedDate == null) missing.add('Ημερομηνία');
        break;

      case 'Άδεια (Κανονική)':
        if (_filenameCtrl.text.trim().isEmpty) missing.add('Όνομα αρχείου');
        if (_protocolCtrl.text.trim().isEmpty) missing.add('Αρ. Πρωτοκόλλου');
        if (_receiversCtrl.text.trim().isEmpty) missing.add('Παραλήπτες');
        if (_selectedDate == null) missing.add('Ημερομηνία');
        if (_dateAitisis == null) missing.add('Ημερομηνία Αίτησης');
        if (_genArtCtrl.text.trim().isEmpty) missing.add('στον / στην');
        if (_genEndiafCtrl.text.trim().isEmpty) missing.add('ενδιαφερόμενος/η');
        if (_employCtrl.text.trim().isEmpty) missing.add('Όνομα Εργαζομένου');
        if (_eidikotitaCtrl.text.trim().isEmpty) missing.add('Κλάδος');
        if (_numDaysCtrl.text.trim().isEmpty) missing.add('Ημέρες Άδειας');
        if (_dateFromCtrl == null) missing.add('Ημερομηνία Από');
        if (_dateToCtrl == null) missing.add('Ημερομηνία Έως');
        break;

      default:
        if (_filenameCtrl.text.trim().isEmpty) missing.add('Όνομα αρχείου');
        if (_protocolCtrl.text.trim().isEmpty) missing.add('Αρ. Πρωτοκόλλου');
        if (_receiversCtrl.text.trim().isEmpty) missing.add('Παραλήπτες');
        if (_subjectCtrl.text.trim().isEmpty) missing.add('Θέμα');
        if (_contentCtrl.text.trim().isEmpty) missing.add('Περιεχόμενο');
        if (_selectedDate == null) missing.add('Ημερομηνία');
    }

    // Αν λείπει το subject → μπλοκάρουμε εντελώς
    if (_subjectCtrl.text.trim().isEmpty) {
      _snack('Σφάλμα: Το πεδίο Θέμα είναι υποχρεωτικό.');
      return;
    }

    // Αν λείπουν άλλα πεδία → εμφάνιση διαλόγου
    if (missing.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Μη συμπληρωμένα πεδία'),
              content: Text(
                'Λείπουν: ${missing.join(', ')}.\n'
                'Θέλεις να συνεχίσεις την αποθήκευση;',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Άκυρο'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Συνέχεια'),
                ),
              ],
            ),
      );
      if (ok != true) return;
    }

    // ✅ Αποθήκευση
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{};
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mydocs');

      switch (templateName) {
        case 'Απλό Έγγραφο':
          data.addAll({
            'filename': _filenameCtrl.text.trim(),
            'protocol': _protocolCtrl.text.trim(),
            'subject': _subjectCtrl.text.trim(),
            'receivers': _receiversCtrl.text.trim(),
            'content': _contentCtrl.text.trim(),
            'date':
                _selectedDate != null
                    ? Timestamp.fromDate(_selectedDate!)
                    : null,
          });
          break;

        case 'Άδεια (Κανονική)':
          data.addAll({
            'filename': _filenameCtrl.text.trim(),
            'protocol': _protocolCtrl.text.trim(),
            'subject': _subjectCtrl.text.trim(),
            'date':
                _selectedDate != null
                    ? Timestamp.fromDate(_selectedDate!)
                    : null,
            'receivers': _receiversCtrl.text.trim(),
            'dateAitisis':
                _dateAitisis != null ? Timestamp.fromDate(_dateAitisis!) : null,

            'male-female-endiaf': _genEndiafCtrl.text.trim(),
            'genArt': _genArtCtrl.text.trim(),
            'eployName': _employCtrl.text.trim(),
            'eidikotita': _eidikotitaCtrl.text.trim(),
            'numDays': _numDaysCtrl.text.trim(),
            'dateFrom':
                _dateFromCtrl != null
                    ? Timestamp.fromDate(_dateFromCtrl!)
                    : null,
            'dateTo':
                _dateToCtrl != null ? Timestamp.fromDate(_dateToCtrl!) : null,
          });
          break;

        default:
          data.addAll({
            'filename': _filenameCtrl.text.trim(),
            'protocol': _protocolCtrl.text.trim(),
            'receivers': _receiversCtrl.text.trim(),
            'subject': _subjectCtrl.text.trim(),
            'content': _contentCtrl.text.trim(),
            'date':
                _selectedDate != null
                    ? Timestamp.fromDate(_selectedDate!)
                    : null,
          });
      }
      data['templateId'] = templateId;
      data['createdAt'] = FieldValue.serverTimestamp();

      // Αποθήκευση (add ή update)
      _editing
          ? await col.doc(_editingDocId).update(data)
          : await col.add(data);

      _snack('✅ Αποθηκεύτηκε');
      setState(() => _showForm = false);
    } catch (e) {
      _snack('Σφάλμα αποθήκευσης: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
      _editing = false;
      _editingDocId = null;
    }
  }

  Future<void> _deleteDoc(String docId) async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mydocs')
        .doc(docId)
        .delete();
  }

  Future<void> _exportDoc(Map<String, dynamic> docData) async {
    final uid = ref.read(authUidProvider);
    final templateId = ref.read(selectedTemplateIdProvider);
    if (uid == null || templateId == null) return;

    // Προσθήκη παραθύρου προβολής δεδομένων
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Προβολή Δεδομένων'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    docData.entries.map((entry) {
                      // Μορφοποίηση ημερομηνιών
                      dynamic value = entry.value;
                      if (value is Timestamp) {
                        value = DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(value.toDate());
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(value?.toString() ?? 'null'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Άκυρο'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Έναρξη διαδικασίας εξαγωγής
                  _snack('Εξαγωγή…');
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final settingsSnap =
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('settings')
                            .doc('app')
                            .get();

                    final settings = settingsSnap.data();

                    if (settings == null || settings['googleFolder'] == null) {
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pop(); // Κλείνει τυχόν spinner dialog
                        _snack(
                          '⚠️ Δεν έχει οριστεί φάκελος Google Drive για εξαγωγή.',
                        );
                      }
                      return; // ➤ σταματάει η εξαγωγή
                    }

                    // ✅ Συνέχεια αν όλα OK
                    await ref
                        .read(driveServiceProvider)
                        .exportDoc(
                          uid: uid,
                          templateId: templateId,
                          docData: docData,
                          userSettings: settings,
                        );

                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // ✅ κλείνει το spinner

                    _snack('✅ Εξαγωγή επιτυχής');
                  } catch (e) {
                    Navigator.of(context).pop(); // ✅ Ασφαλές
                    _snack('Σφάλμα εξαγωγής: $e');
                  }

                  if (!context.mounted) {
                    return; // ✅ Τώρα είναι εκτός του finally
                  }

                  Navigator.of(context).pop(); // ✅ Ασφαλές
                },
                child: const Text('Συνέχεια'),
              ),
            ],
          ),
    );
  }

  // ---------- build ----------
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
            _snack('Πρώτα επιλέξτε template');
            return;
          }
          setState(() {
            _showForm = true;
            _viewMode = false;
            _editing = false;
            _editingDocId = null;
          });
          _clearForm();
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // dropdown
            BorderedBox(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Σφάλμα: $e'),
                data: (templates) {
                  final items =
                      templates.where((t) {
                        final id = t['fileId'];
                        return id is String && id.isNotEmpty;
                      }).toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Επιλέξτε τύπο εγγράφου',
                    ),
                    value: selectedTemplateId,
                    hint: const Text('—'),
                    items:
                        items
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t['fileId'] as String,
                                child: Text(t['name'] ?? ''),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      // αποθηκεύουμε το id
                      ref.read(selectedTemplateIdProvider.notifier).state = val;
                      _showForm = false;
                      // βρίσκουμε το όνομα του template που αντιστοιχεί στο id
                      final String? name =
                          items
                              .firstWhere((t) => t['fileId'] == val)['name']
                              ?.toString();

                      // αποθηκεύουμε και το όνομα σε ξεχωριστό provider
                      ref.read(selectedTemplateNameProvider.notifier).state =
                          name;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // ----- docs list -----
                  Expanded(
                    child: BorderedBox(
                      child:
                          (selectedTemplateId == null || uid == null)
                              ? const Center(
                                child: Text('Επιλέξτε τύπο εγγράφου'),
                              )
                              : FutureBuilder(
                                future: ref
                                    .read(driveServiceProvider)
                                    .fetchDocs(
                                      uid: uid,
                                      templateId: selectedTemplateId,
                                    ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Σφάλμα: ${snapshot.error}');
                                  }
                                  final docs =
                                      snapshot.data ??
                                      <
                                        QueryDocumentSnapshot<
                                          Map<String, dynamic>
                                        >
                                      >[];

                                  if (docs.isEmpty) {
                                    return const Center(
                                      child: Text('Δεν υπάρχουν αρχεία'),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: docs.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(height: 0),
                                    itemBuilder: (ctx, i) {
                                      final data = docs[i].data();
                                      final id = docs[i].id;
                                      final ts = data['date'] as Timestamp?;
                                      final dateStr =
                                          ts != null
                                              ? DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(ts.toDate())
                                              : '-';
                                      return ListTile(
                                        title: Text(data['subject'] ?? ''),
                                        subtitle: Text(
                                          dateStr,
                                          style:
                                              Theme.of(ctx).textTheme.bodySmall,
                                        ),
                                        onTap:
                                            () => setState(() {
                                              _populateForm(data);
                                              _showForm = true;
                                              _viewMode = true;
                                            }),
                                        trailing: Wrap(
                                          spacing: 4,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 20,
                                              ),
                                              tooltip: 'Επεξεργασία',
                                              onPressed:
                                                  () => setState(() {
                                                    _populateForm(data);
                                                    _showForm = true;
                                                    _viewMode = false;
                                                    _editing = true;
                                                    _editingDocId = id;
                                                  }),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                              ),
                                              tooltip: 'Διαγραφή',
                                              onPressed: () => _deleteDoc(id),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.cloud_upload,
                                                size: 20,
                                              ),
                                              tooltip: 'Εξαγωγή',
                                              onPressed: () => _exportDoc(data),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ----- form / preview -----
                  Expanded(
                    flex: 2,
                    child: BorderedBox(
                      child:
                          _showForm
                              ? _bottomBox()
                              : const Center(
                                child: Text('Επίλεξε αρχείο ή (+) για νέο'),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() => ElevatedButton(
    onPressed: _saving ? null : _saveDoc,
    child:
        _saving
            ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : Text(_editing ? 'Ενημέρωση' : 'Αποθήκευση'),
  );

  void _updateSubjectText(WidgetRef ref) {
    final templateName = ref.read(selectedTemplateNameProvider) ?? '';
    final employee = _employCtrl.text.trim();
    final dateStr =
        _dateFromCtrl != null
            ? DateFormat('dd/MM/yyyy').format(_dateFromCtrl!)
            : '';
    _subjectCtrl.text = '$employee $templateName $dateStr';
    _filenameCtrl.text = _subjectCtrl.text;
  }

  Widget _kanonikiAdeia() {
    final ro = _viewMode;
    String? gender;

    final g = _genEndiafCtrl.text;
    if (g == 'του ενδιαφερόμενου') {
      gender = 'Άρρεν';
    } else if (g == 'της ενδιαφερόμενης') {
      gender = 'Θήλυ';
    } else {
      gender = null;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          TextField(
            controller: _filenameCtrl,
            decoration: const InputDecoration(labelText: 'Όνομα αρχείου'),
            readOnly: true, //ro,
          ),
          const SizedBox(height: 8),
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
                  onPressed:
                      ro
                          ? null
                          : () => _pickDateGeneric(
                            _selectedDate,
                            (d) => _selectedDate = d,
                          ),
                  child: Text(
                    _selectedDate == null
                        ? 'Ημερομηνία'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _receiversCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Παραλήπτες'),
            readOnly: ro,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Ημερομηνία Αίτησης Άδειας:',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed:
                      ro
                          ? null
                          : () => _pickDateGeneric(
                            _dateAitisis,
                            (d) => setState(() => _dateAitisis = d),
                          ),
                  child: Text(
                    _dateAitisis == null
                        ? 'Επιλέξτε ημερομηνία Αίτησης'
                        : DateFormat('dd/MM/yyyy').format(_dateAitisis!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _employCtrl,
            decoration: const InputDecoration(labelText: 'Όνομα Εργαζομένου'),
            onChanged: (_) => _updateSubjectText(ref),
            readOnly: ro,
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _eidikotitaCtrl,
                  decoration: const InputDecoration(labelText: 'Κλάδος'),
                  readOnly: ro,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Φύλο'),
                  value: gender,
                  items: const [
                    DropdownMenuItem(value: 'Άρρεν', child: Text('Άρρεν')),
                    DropdownMenuItem(value: 'Θήλυ', child: Text('Θήλυ')),
                  ],
                  onChanged:
                      _viewMode
                          ? null
                          : (v) => setState(() {
                            gender = v;
                            if (v == 'Άρρεν') {
                              _genEndiafCtrl.text = 'του ενδιαφερόμενου';
                              _genArtCtrl.text = 'στον';
                            } else if (v == 'Θήλυ') {
                              _genEndiafCtrl.text = 'της ενδιαφερόμενης';
                              _genArtCtrl.text = 'στην';
                            }
                          }),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _numDaysCtrl,
                  decoration: const InputDecoration(labelText: '#Ημ.Αδ.'),
                  readOnly: ro,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed:
                      ro
                          ? null
                          : () => _pickDateGeneric(
                            _dateFromCtrl,
                            (d) => setState(() {
                              _dateFromCtrl = d;
                              _updateSubjectText(ref); // ✅ σωστό σημείο
                            }),
                          ),
                  child: Text(
                    _dateFromCtrl == null
                        ? 'Από'
                        : DateFormat('dd/MM/yyyy').format(_dateFromCtrl!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed:
                      ro
                          ? null
                          : () => _pickDateGeneric(
                            _dateToCtrl,
                            (d) => setState(() => _dateToCtrl = d),
                          ),
                  child: Text(
                    _dateToCtrl == null
                        ? 'Έως'
                        : DateFormat('dd/MM/yyyy').format(_dateToCtrl!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!ro) _saveButton(),
        ],
      ),
    );
  }

  Widget _simpleForm() {
    final ro = _viewMode;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _filenameCtrl,
            decoration: const InputDecoration(labelText: 'Όνομα αρχείου'),
            readOnly: ro,
          ),
          const SizedBox(height: 8),
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
                  onPressed:
                      ro
                          ? null
                          : () => _pickDateGeneric(
                            _selectedDate,
                            (d) => setState(() => _selectedDate = d),
                          ),
                  child: Text(
                    _selectedDate == null
                        ? 'Ημερομηνία'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _receiversCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Παραλήπτες'),
            readOnly: ro,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectCtrl,
            maxLines: 1,
            decoration: const InputDecoration(labelText: 'Θέμα'),
            readOnly: ro,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              //minLines: null,
              decoration: const InputDecoration(labelText: 'Περιεχόμενο'),
              readOnly: ro,
            ),
          ),
          const SizedBox(height: 8),
          if (!ro) _saveButton(),
        ],
      ),
    );
  }

  Widget _bottomBox() {
    if (!_showForm) return const SizedBox();

    // διαβάζουμε το όνομα που έχει επιλέξει ο χρήστης
    final templateName = ref.read(selectedTemplateNameProvider);

    switch (templateName) {
      case 'Απλό Έγγραφο':
        return _simpleForm();

      case 'Άδεια (Κανονική)':
        return _kanonikiAdeia(); // Άδεια (Κανονική)

      default:
        return _simpleForm();
    }
  }
}
