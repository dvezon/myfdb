import 'package:flutter/material.dart';
//import 'package:google_sign_in/google_sign_in.dart';
//import 'package:googleapis_auth/auth_io.dart' as auth;
//import 'package:googleapis/documents/v1.dart'           as docs_api;
//import 'package:googleapis/drive/v3.dart' as drive_api;

class EditFieldsScreen extends StatefulWidget {
  const EditFieldsScreen({super.key});

  @override
  State<EditFieldsScreen> createState() => _EditFieldsScreenState();
}

class _EditFieldsScreenState extends State<EditFieldsScreen> {
  // Δηλώνουμε TextEditingController για κάθε string
  late final TextEditingController _ypourgeioLine1Ctrl;
  late final TextEditingController _ypourgeioLine2Ctrl;
  late final TextEditingController _perDieythCtrl;
  late final TextEditingController _dieythCtrl;
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _schoolNameGenCtrl;
  late final TextEditingController _schoolAddressCtrl;
  late final TextEditingController _schoolCodeCtrl;
  late final TextEditingController _informationCtrl;
  late final TextEditingController _schoolPhoneCtrl;
  late final TextEditingController _schoolEmailCtrl;
  late final TextEditingController _schoolWebPageCtrl;
  late final TextEditingController _titleSignatureCtrl;
  late final TextEditingController _nameSignatureCtrl;
  late final TextEditingController _kladosSignatureCtrl;

  @override
  void initState() {
    super.initState();

    // Βάζουμε τις αρχικές τιμές στα πεδία
    _ypourgeioLine1Ctrl = TextEditingController(text: 'ΠΑΙΔΕΙΑΣ');
    _ypourgeioLine2Ctrl = TextEditingController(
      text: 'ΘΡΗΣΚΕΥΜΑΤΩΝ ΚΑΙ ΑΘΛΗΤΙΣΜΟΥ',
    );
    _perDieythCtrl = TextEditingController(text: 'ΠΕΛΟΠΟΝΝΗΣΟΥ');
    _dieythCtrl = TextEditingController(text: 'Δ/ΝΣΗ Β/ΘΜΙΑΣ ΕΚΠ/ΣΗΣ ΚΟΡΙΝΘΟΥ');
    _schoolNameCtrl = TextEditingController(
      text: 'ΗΜΕΡΗΣΙΟ ΓΥΜΝΑΣΙΟ ΖΕΥΓΟΛΑΤΙΟΥ',
    );
    _schoolNameGenCtrl = TextEditingController(text: 'ΓΥΜΝΑΣΙΟΥ ΖΕΥΓΟΛΑΤΙΟΥ');
    _schoolAddressCtrl = TextEditingController(text: 'Ασημούλας Βουδούρη');
    _schoolCodeCtrl = TextEditingController(text: '20001 Ζευγολατιό Κορινθίας');
    _informationCtrl = TextEditingController(text: 'Βεζονιαράκης Δημήτρης');
    _schoolPhoneCtrl = TextEditingController(text: '27410 -54160');
    _schoolEmailCtrl = TextEditingController(
      text: 'mail@gym-zevgol.kor.sch.gr',
    );
    _schoolWebPageCtrl = TextEditingController(
      text: 'http://gym-zevgol.kor.sch.gr',
    );
    _titleSignatureCtrl = TextEditingController(text: 'Ο Διευθυντής');
    _nameSignatureCtrl = TextEditingController(text: 'Βεζονιαράκης Δημήτριος');
    _kladosSignatureCtrl = TextEditingController(text: 'ΠΕ86-ΠΛΗΡΟΦΟΡΙΚΗΣ');
  }

  @override
  void dispose() {
    // Καθαρίζουμε τους controllers
    _ypourgeioLine1Ctrl.dispose();
    _ypourgeioLine2Ctrl.dispose();
    _perDieythCtrl.dispose();
    _dieythCtrl.dispose();
    _schoolNameCtrl.dispose();
    _schoolNameGenCtrl.dispose();
    _schoolAddressCtrl.dispose();
    _schoolCodeCtrl.dispose();
    _informationCtrl.dispose();
    _schoolPhoneCtrl.dispose();
    _schoolEmailCtrl.dispose();
    _schoolWebPageCtrl.dispose();
    _titleSignatureCtrl.dispose();
    _nameSignatureCtrl.dispose();
    _kladosSignatureCtrl.dispose();
    super.dispose();
  }

  /*
  /// Καλείται όταν ο χρήστης πατήσει "Δημιουργία Εγγράφου"
  Future<void> _onGenerateDocument() async {
    // 1. Βεβαιωνόμαστε ότι τα πεδία έχουν τιμές
    final ypourgeioLine1 = _ypourgeioLine1Ctrl.text.trim();
    final ypourgeioLine2 = _ypourgeioLine2Ctrl.text.trim();
    final perDieyth = _perDieythCtrl.text.trim();
    final dieyth = _dieythCtrl.text.trim();
    final schoolName = _schoolNameCtrl.text.trim();
    final schoolNameGen = _schoolNameGenCtrl.text.trim();
    final schoolAddress = _schoolAddressCtrl.text.trim();
    final schoolCode = _schoolCodeCtrl.text.trim();
    final information = _informationCtrl.text.trim();
    final schoolPhone = _schoolPhoneCtrl.text.trim();
    final schoolEmail = _schoolEmailCtrl.text.trim();
    final schoolWebPage = _schoolWebPageCtrl.text.trim();
    final titleSignature = _titleSignatureCtrl.text.trim();
    final nameSignature = _nameSignatureCtrl.text.trim();
    final kladosSignature = _kladosSignatureCtrl.text.trim();

    // 2. Εδώ καλούμε μια συνάρτηση που θα χρησιμοποιεί την Google API για να:
    //    α) Δημιουργήσει ένα νέο έγγραφο (ή να αντιγράψει πρότυπο)
    //    β) Θα εισάγει τα παραπάνω δεδομένα σε συγκεκριμένες θέσεις του εγγράφου
    //    γ) Θα αποθηκεύσει το τελικό έγγραφο στο Drive του signed-in χρήστη
    //
    // Σημείωση: Πρέπει πρώτα να έχεις υλοποιήσει ή εισάγει ένα helper που
    // χειρίζεται:
    //   • Google Sign-In (ώστε να πάρεις ένα OAuth credential του χρήστη)
    //   • Google Docs API (για να τροποποιήσεις το περιεχόμενο του Doc)
    //   • Google Drive API (για να το αποθηκεύσεις/μοιραστείς)
    //
    // Εδώ απλώς καλώ τη placeholder συνάρτηση:
    try {
      await generateGoogleDoc(
        ypourgeioLine1: ypourgeioLine1,
        ypourgeioLine2: ypourgeioLine2,
        perDieyth: perDieyth,
        dieyth: dieyth,
        schoolName: schoolName,
        schoolNameGen: schoolNameGen,
        schoolAddress: schoolAddress,
        schoolCode: schoolCode,
        information: information,
        schoolPhone: schoolPhone,
        schoolEmail: schoolEmail,
        schoolWebPage: schoolWebPage,
        titleSignature: titleSignature,
        nameSignature: nameSignature,
        kladosSignature: kladosSignature,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Το έγγραφο δημιουργήθηκε με επιτυχία!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Σφάλμα κατά τη δημιουργία: $e')));
    }
  }


  */

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ρυθμίσεις Εγγράφου')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Scrollable μέρος: 80%
            Flexible(
              flex: 9,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 12,
                    top: 0,
                    bottom: 8,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Υπουργείο (γραμμή 1)',
                        _ypourgeioLine1Ctrl,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Υπουργείο (γραμμή 2)',
                        _ypourgeioLine2Ctrl,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Περιφέρεια / Διεύθυνση', _perDieythCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Διεύθυνση Εκπαίδευσης', _dieythCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Όνομα Σχολείου', _schoolNameCtrl),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Γενική Μορφή Σχολείου',
                        _schoolNameGenCtrl,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Διεύθυνση Σχολείου', _schoolAddressCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Κωδικός Σχολείου', _schoolCodeCtrl),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Υπεύθυνος Πληροφορικής',
                        _informationCtrl,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Τηλέφωνο Σχολείου', _schoolPhoneCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Email Σχολείου', _schoolEmailCtrl),
                      const SizedBox(height: 8),
                      _buildTextField(
                        'Ιστοσελίδα Σχολείου',
                        _schoolWebPageCtrl,
                      ),
                      const SizedBox(height: 8),
                      _buildTextField('Τίτλος Υπογραφής', _titleSignatureCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Όνομα Υπογραφής', _nameSignatureCtrl),
                      const SizedBox(height: 8),
                      _buildTextField('Κλάδος Υπογραφής', _kladosSignatureCtrl),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // 🔸 Κουμπί: 20%
            Flexible(
              flex: 1,
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('Ενημέρωση'),
                  onPressed: null, //_onGenerateDocument,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Βοηθητική για να φτιάξουμε ένα TextField με label
  Widget _buildTextField(String label, TextEditingController ctrl) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: ctrl,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.primary),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// ===========================
///  Placeholder συνάρτηση για Google Doc + Drive
///  Εδώ πρέπει να υλοποιήσεις (ή να φέρεις δική σου υλοποίηση) που να:
///   1. Κάνει sign-in στον Google (ή χρησιμοποιεί ήδη υπάρχον token)
///   2. Κατεβάζει ένα πρότυπο Google Doc (ή δημιουργεί νέο)
///   3. Αντικαθιστά placeholders με τα strings που παρέχονται
///   4. Αποθηκεύει / μοιράζει το νέο έγγραφο στο Drive του χρήστη
///
///  Το παρακάτω είναι ένα δείγμα υποθετικού API – ΔΕΝ είναι πλήρες,
///  απαιτεί να έχεις ρυθμίσει OAuth2 credentials, να ενσωματώσεις το
///  googleapis Auth και να χρησιμοποιήσεις το Google Docs & Drive SDK.
/// ===========================
/*Future<void> generateGoogleDoc({
  required String ypourgeioLine1,
  required String ypourgeioLine2,
  required String perDieyth,
  required String dieyth,
  required String schoolName,
  required String schoolNameGen,
  required String schoolAddress,
  required String schoolCode,
  required String information,
  required String schoolPhone,
  required String schoolEmail,
  required String schoolWebPage,
  required String titleSignature,
  required String nameSignature,
  required String kladosSignature,
}) async {
/
  // 1) Κάνεις Google Sign-In (ή παίρνεις ήδη έγκυρο OAuth credential).
  final googleUser = await GoogleSignIn(
    scopes: [
      drive_api.DriveApi.driveFileScope,
      docs_api.DocsApi.documentsScope,
    ],
  ).signIn();

  if (googleUser == null) {
    throw Exception('Ακύρωσες τη σύνδεση στο Google');
  }

  final authHeaders = await googleUser.authHeaders;
  final authenticateClient = auth.authenticatedClient(
    Client(),      // χρειάζεται http.Client import: `import 'package:http/http.dart' show Client;`
    auth.AccessCredentials.fromJson(authHeaders),
  );

  // 2) Δημιουργείς ή αντιγράφεις ένα πρότυπο έγγραφο
  final docsClient = docs_api.DocsApi(authenticateClient);

  // Παράδειγμα: Αντιγράφουμε ένα υπάρχον Google Doc ως “template”:
  //
  // final copiedFile = await drive_api.DriveApi(authenticateClient)
  //     .files
  //     .copy('TEMPLATE_FILE_ID', drive_api.File(name: 'Νέο Έγγραφο Σχολείου'));
  //
  // final documentId = copiedFile.id;
  //
  // Για απλό demo, ας δημιουργήσουμε ένα τελείως καινούριο:
  final createReq = docs_api.Document()..title = 'Έγγραφο Σχολείου';
  final newDoc = await docsClient.documents.create(createReq);
  final documentId = newDoc.documentId!;

  // 3) Συναρτήσεις αντικατάστασης placeholders
  //    Στον κειμενογράφο του Docs, έχε placeholders τύπου {{YPOURGEIO_LINE1}}, {{SCHOOL_NAME}} κ.λπ.

  final requests = <docs_api.Request>[];

  // Βάζουμε παραδείγματα ReplaceText requests:
  requests.addAll([
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{YPOURGEIO_LINE1}}'),
        replaceText: ypourgeioLine1,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{YPOURGEIO_LINE2}}'),
        replaceText: ypourgeioLine2,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{PER_DIEYTH}}'),
        replaceText: perDieyth,
      ),
    ),
    // … πρόσθεσε και για όλα τα υπόλοιπα placeholders:
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{DIEYTH}}'),
        replaceText: dieyth,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_NAME}}'),
        replaceText: schoolName,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_NAME_GEN}}'),
        replaceText: schoolNameGen,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_ADDRESS}}'),
        replaceText: schoolAddress,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_CODE}}'),
        replaceText: schoolCode,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{INFORMATION}}'),
        replaceText: information,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_PHONE}}'),
        replaceText: schoolPhone,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_EMAIL}}'),
        replaceText: schoolEmail,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{SCHOOL_WEBPAGE}}'),
        replaceText: schoolWebPage,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{TITLE_SIGNATURE}}'),
        replaceText: titleSignature,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{NAME_SIGNATURE}}'),
        replaceText: nameSignature,
      ),
    ),
    docs_api.Request(
      replaceAllText: docs_api.ReplaceAllTextRequest(
        containsText: docs_api.SubstringMatchCriteria(text: '{{KLADOS_SIGNATURE}}'),
        replaceText: kladosSignature,
      ),
    ),
  ]);

  // Εκτελούμε τα replace-all requests στον Doc
  await docsClient.documents.batchUpdate(
    docs_api.BatchUpdateDocumentRequest(requests: requests),
    documentId,
  );

  // 4) (Προαιρετικά) Μοιράζεις το έγγραφο στο Drive, δίνεις δικαιώματα;
  //    Παράδειγμα: Αλλάζεις το όνομα, το public link, κ.λπ.

  // Αν θέλεις να αποθηκεύσεις το file ID κάπου ή να κάνεις share, έτσι:
  // final driveClient = drive_api.DriveApi(authenticateClient);
  // await driveClient.permissions.create(
  //   drive_api.Permission(role: 'reader', type: 'anyone'),
  //   documentId,
  // );
  //
  // Στο τέλος μπορείς να επιστρέψεις το public URL:
  // final url = 'https://docs.google.com/document/d/$documentId/edit';
  // print('New Doc URL: $url');

  return;
}
*/
