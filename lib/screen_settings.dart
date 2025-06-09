import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'mywidgets.dart';

/// -----------------------------------------------------------------
///  EditFieldsScreen
/// -----------------------------------------------------------------
///  * Αποθηκεύει / διαβάζει ρυθμίσεις σε Cloud Firestore **per‑user**.
///  * Παρέχει κουμπί «Επαναφορά» που επαναφέρει όλες τις τιμές στα
///    προεπιλεγμένα και τις ξαναγράφει στο Firestore.
/// -----------------------------------------------------------------
class EditFieldsScreen extends StatefulWidget {
  const EditFieldsScreen({super.key});

  @override
  State<EditFieldsScreen> createState() => _EditFieldsScreenState();
}

class _EditFieldsScreenState extends State<EditFieldsScreen> {
  // ------------  Σταθερά & meta  ------------
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

  // Αρχικές τιμές (defaults)
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

  late final List<TextEditingController> _controllers;
  late final TextEditingController googleFolder;

  bool _busy = false;

  // ------------  Init  ------------
  @override
  void initState() {
    super.initState();

    _controllers = _defaults
        .map((d) => TextEditingController(text: d))
        .toList(growable: false);

    googleFolder = TextEditingController();

    _initialise();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -----------------------------------------------------------
  // 1. INIT – ορισμός σωστού _docRef και φόρτωση ρυθμίσεων
  // -----------------------------------------------------------
  late DocumentReference<Map<String, dynamic>> _docRef;

  Future<void> _initialise() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    // ➜ Για ανώνυμο χρήστη γράφουμε κάτω από /settings/global/app
    final base =
        uid == null
            ? FirebaseFirestore.instance.collection('settings').doc('global')
            : FirebaseFirestore.instance.collection('users').doc(uid);

    _docRef = base.collection('settings').doc('app');

    await _readFromFirestore();
    if (mounted) setState(() {});
  }

  // -----------------------------------------------------------
  // 2. READ – φόρτωση πεδίων στους controllers
  // -----------------------------------------------------------
  Future<void> _readFromFirestore() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final data = snap.data() ?? {};

        // generic πεδία
        for (var i = 0; i < _controllers.length; i++) {
          final val = data[_keys[i]];
          if (val is String) _controllers[i].text = val;
        }

        // googleFolder
        googleFolder.text = (data[_googleFolderKey] ?? '') as String;
      } else {
        await _writeToFirestore(); // πρώτη φορά → γράψε defaults
      }
    } catch (e) {
      _showSnack('Σφάλμα ανάγνωσης ρυθμίσεων: $e');
    }
  }

  // -----------------------------------------------------------
  // 3. WRITE – αποθήκευση (merge) όλων των πεδίων
  // -----------------------------------------------------------
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

  // ------------  Reset  ------------
  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Επαναφορά ρυθμίσεων'),
            content: const Text(
              'Θέλεις να διαγραφεί και ο κοινόχρηστος φάκελος του Drive;',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Όχι'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ναι'),
              ),
            ],
          ),
    );

    setState(() => _busy = true);

    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = _defaults[i];
    }

    if (confirm == true) {
      googleFolder.text = '';
    }

    await _writeToFirestore();
    if (mounted) setState(() => _busy = false);
    _showSnack('Οι αρχικές τιμές επαναφέρθηκαν.');
  }

  // ------------  Dispose  ------------
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    googleFolder.dispose();
    super.dispose();
  }

  // ------------  UI  ------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις Εγγράφου')),
      body: Column(
        children: [
          Flexible(
            flex: 7,
            child: BorderedBox(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(children: _buildFields(cs)),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: BorderedBox(
              child: MyTextField(
                controller: googleFolder,
                label: "Drive Κοινόχρηστος Φάκελλος",
                cs: cs,
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(_busy ? 'Αποθήκευση…' : 'Ενημέρωση'),
                    onPressed: _busy ? null : _onSavePressed,
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

    return List.generate(labels.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MyTextField(
          controller: _controllers[i],
          label: labels[i],
          cs: cs,
        ),
      );
    });
  }

  // ------------  Actions  ------------
  Future<void> _onSavePressed() async {
    setState(() => _busy = true);
    await _writeToFirestore();
    if (mounted) setState(() => _busy = false);
    _showSnack('Οι ρυθμίσεις αποθηκεύτηκαν.');
  }
}
