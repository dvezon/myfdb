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
///  * SnackBars & context‑safety via helper.
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
  late DocumentReference<Map<String, dynamic>> _docRef;
  bool _busy = false;

  // ------------  Init  ------------
  @override
  void initState() {
    super.initState();
    _controllers = _defaults
        .map((d) => TextEditingController(text: d))
        .toList(growable: false);
    _initialise();
  }

  // Helper για ασφαλή SnackBars
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _initialise() async {
    await Firebase.initializeApp();
    final user = auth.FirebaseAuth.instance.currentUser;
    final docId = user?.uid ?? 'global';
    _docRef = FirebaseFirestore.instance.collection('settings').doc(docId);

    await _readFromFirestore();
    if (mounted) setState(() {});
  }

  // ------------  Firestore   ------------
  Future<void> _readFromFirestore() async {
    try {
      final snap = await _docRef.get();
      if (snap.exists) {
        final data = snap.data()!;
        for (var i = 0; i < _controllers.length; i++) {
          final val = data[_keys[i]];
          if (val is String && val.isNotEmpty) {
            _controllers[i].text = val;
          }
        }
      } else {
        await _writeToFirestore(); // πρώτη φορά → γράψε defaults
      }
    } catch (e) {
      _showSnack('Σφάλμα ανάγνωσης ρυθμίσεων: $e');
    }
  }

  Future<void> _writeToFirestore() async {
    final map = Map<String, String>.fromIterables(
      _keys,
      _controllers.map((c) => c.text),
    );
    await _docRef.set(map);
  }

  // ------------  Reset to defaults  ------------
  Future<void> _resetToDefaults() async {
    setState(() => _busy = true);
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = _defaults[i];
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
    super.dispose();
  }

  // ------------  UI  ------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις Εγγράφου')),
      body: //Padding(
      //padding: const EdgeInsets.all(16),
      Column(
        children: [
          // --- πεδία -----------------------
          Flexible(
            flex: 9,
            child: BorderedBox(
              child: SingleChildScrollView(
                child: Column(children: _buildFields(cs)),
              ),
            ),
          ),
          // --- κουμπιά ---------------------
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
        child: TextField(
          controller: _controllers[i],
          decoration: InputDecoration(
            labelText: labels[i],
            labelStyle: TextStyle(color: cs.primary),
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
