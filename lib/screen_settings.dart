// edit_fields_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart' show globalUid; // ✅ παίρνουμε το UID από το main
import 'mywidgets.dart';

class EditFieldsScreen extends StatefulWidget {
  const EditFieldsScreen({super.key});

  @override
  State<EditFieldsScreen> createState() => _EditFieldsScreenState();
}

class _EditFieldsScreenState extends State<EditFieldsScreen> {
  // ────────── metadata ──────────
  static const List<String> _keys = [
    'ypLine1',
    'ypLine2',
    'perDieyth',
    'dieyth',
    'schoolName',
    'schoolNameGen',
    'schoolAddr',
    'schoolCode',
    'info',
    'schoolPhone',
    'schoolEmail',
    'schoolWeb',
    'titleSig',
    'nameSig',
    'kladosSig',
  ];
  static const String _googleFolderKey = 'googleFolder';

  static const List<String> _defaults = [
    'ΠΑΙΔΕΙΑΣ',
    'ΘΡΗΣΚΕΥΜΑΤΩΝ ΚΑΙ ΑΘΛΗΤΙΣΜΟΥ',
    'ΠΕΛΟΠΟΝΝΗΣΟΥ',
    'Δ/ΝΣΗ Β/ΘΜΙΑΣ ΕΚΠ/ΣΗΣ ΚΟΡΙΝΘΟΥ',
    'ΗΜΕΡΗΣΙΟ ΓΥΜΝΑΣΙΟ ΖΕΥΓΟΛΑΤΙΟΥ',
    'ΓΥΜΝΑΣΙΟΥ ΖΕΥΓΟΛΑΤΙΟΥ',
    'Ασημούλας Βουδούρη',
    '20001 Ζευγολατιό Κορινθίας',
    'Βεζονιαράκης Δημήτρης',
    '27410-54160',
    'mail@gym-zevgol.kor.sch.gr',
    'http://gym-zevgol.kor.sch.gr',
    'Ο Διευθυντής',
    'Βεζονιαράκης Δημήτριος',
    'ΠΕ86-ΠΛΗΡΟΦΟΡΙΚΗΣ',
  ];

  late final List<TextEditingController> _controllers =
      _defaults.map((d) => TextEditingController(text: d)).toList();
  late final TextEditingController googleFolder = TextEditingController();

  bool _busy = false;
  late final DocumentReference<Map<String, dynamic>> _docRef;

  // ────────── init ──────────
  @override
  void initState() {
    super.initState();
    _initialise(); // φορτώνει ρυθμίσεις
  }

  Future<void> _initialise() async {
    // ➜ Αν για οποιονδήποτε λόγο λείπει το UID, μην κάνεις call στο Firestore.
    if (globalUid == null) {
      debugPrint('⚠️ globalUid is null – cannot load user settings.');
      return;
    }

    _docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(globalUid)
        .collection('settings')
        .doc('app');

    await _readFromFirestore();
    if (mounted) setState(() {});
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ────────── READ ──────────
  Future<void> _readFromFirestore() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final data = snap.data() ?? {};
        for (var i = 0; i < _controllers.length; i++) {
          final val = data[_keys[i]];
          if (val is String) _controllers[i].text = val;
        }
        googleFolder.text = (data[_googleFolderKey] ?? '') as String;
      } else {
        await _writeToFirestore(); // πρώτη φορά → γράψε defaults
      }
    } catch (e) {
      _showSnack('Σφάλμα ανάγνωσης ρυθμίσεων: $e');
    }
  }

  // ────────── WRITE ──────────
  Future<void> _writeToFirestore() async {
    try {
      final map = {
        for (var i = 0; i < _keys.length; i++) _keys[i]: _controllers[i].text,
        _googleFolderKey: googleFolder.text,
      };
      await _docRef.set(map, SetOptions(merge: true));
    } catch (e) {
      _showSnack('Σφάλμα αποθήκευσης ρυθμίσεων: $e');
    }
  }

  // ────────── RESET ──────────
  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Επαναφορά ρυθμίσεων'),
            content: const Text(
              'Θέλεις να διαγραφεί και ο κοινόχρηστος φάκελος του Drive;',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Όχι'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ναι'),
              ),
            ],
          ),
    );

    setState(() => _busy = true);

    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = _defaults[i];
    }
    if (confirm ?? false) googleFolder.text = '';

    await _writeToFirestore();
    if (mounted) setState(() => _busy = false);
    _showSnack('Οι αρχικές τιμές επαναφέρθηκαν.');
  }

  // ────────── UI ──────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις Εγγράφου')),
      body: Column(
        children: [
          // επάνω πλαίσιο με τα πεδία
          Flexible(
            flex: 7,
            child: BorderedBox(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(children: _buildFields(cs)),
              ),
            ),
          ),
          // πεδίο Google Folder
          Flexible(
            flex: 2,
            child: BorderedBox(
              child: MyTextField(
                controller: googleFolder,
                label: 'Drive Κοινόχρηστος Φάκελλος',
                cs: cs,
              ),
            ),
          ),
          // κουμπιά
          Flexible(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(_busy ? 'Αποθήκευση…' : 'Ενημέρωση'),
                    onPressed:
                        _busy
                            ? null
                            : () async {
                              setState(() => _busy = true);
                              await _writeToFirestore();
                              if (mounted) setState(() => _busy = false);
                              _showSnack('Οι ρυθμίσεις αποθηκεύτηκαν.');
                            },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: Text(_busy ? '…' : 'Επαναφορά'),
                    onPressed: _busy ? null : _resetToDefaults,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── helpers ──────────
  List<Widget> _buildFields(ColorScheme cs) {
    const labels = [
      'Υπουργείο (1)',
      'Υπουργείο (2)',
      'Περιφέρεια / Διεύθυνση',
      'Διεύθυνση Εκπαίδευσης',
      'Όνομα Σχολείου',
      'Γενική Μορφή Σχολείου',
      'Διεύθυνση Σχολείου',
      'Κωδικός Σχολείου',
      'Υπεύθυνος Πληροφορικής',
      'Τηλέφωνο Σχολείου',
      'Email Σχολείου',
      'Ιστοσελίδα Σχολείου',
      'Τίτλος Υπογραφής',
      'Όνομα Υπογραφής',
      'Κλάδος Υπογραφής',
    ];

    return List.generate(
      labels.length,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MyTextField(
          controller: _controllers[i],
          label: labels[i],
          cs: cs,
        ),
      ),
    );
  }
}
