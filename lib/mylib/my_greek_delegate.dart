// greek_firebase_labels.dart

import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

class GreekFirebaseUILabels extends DefaultLocalizations {
  const GreekFirebaseUILabels();

  @override
  String get signInText => 'Σύνδεση';
  @override
  String get registerText => 'Εγγραφή';
  @override
  String get emailInputLabel => 'Email';
  @override
  String get passwordInputLabel => 'Κωδικός πρόσβασης';
  @override
  String get okButtonLabel => 'Εντάξει';
  @override
  String get cancelButtonLabel => 'Ακύρωση';

  // πρόσθεσε ό,τι άλλο χρειάζεσαι
}

final firebaseUIDelegate = FirebaseUILocalizations.withDefaultOverrides(
  const GreekFirebaseUILabels(),
);
