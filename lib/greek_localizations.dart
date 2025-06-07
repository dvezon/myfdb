// lib/greek_localizations.dart
//
// Ελληνική τοπικοποίηση για firebase_ui_auth.

import 'package:flutter/widgets.dart'; // Locale, LocalizationsDelegate
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

/// ---------------------------------------------------------------------------
///  Ελληνικά labels (override όσων χρειάζεσαι)
/// ---------------------------------------------------------------------------
class ElLocalizations extends DefaultLocalizations {
  const ElLocalizations();

  // ---- A ----
  @override
  String get accessDisabledErrorText =>
      'Η πρόσβαση σε αυτόν τον λογαριασμό έχει προσωρινά απενεργοποιηθεί';
  @override
  String get arrayLabel => 'πίνακας';

  // ---- B ----
  @override
  String get booleanLabel => 'Boolean';

  // ---- C ----
  @override
  String get cancelLabel => 'Άκυρο';
  @override
  String get chooseACountry => 'Επιλέξτε χώρα';
  @override
  String get confirmPasswordDoesNotMatchErrorText =>
      'Οι κωδικοί δεν ταιριάζουν';
  @override
  String get confirmPasswordInputLabel => 'Επιβεβαίωση κωδικού';
  @override
  String get confirmPasswordIsRequiredErrorText => 'Επιβεβαιώστε τον κωδικό';
  @override
  String get continueText => 'Συνέχεια';
  @override
  String get countryCode => 'Κωδικός';
  @override
  String get credentialAlreadyInUseErrorText =>
      'Αυτός ο πάροχος συνδέεται με διαφορετικό λογαριασμό.';

  // ---- D ----
  @override
  String get deleteAccount => 'Διαγραφή λογαριασμού';
  @override
  String get differentMethodsSignInTitleText =>
      'Χρησιμοποιήστε έναν από τους παρακάτω τρόπους για είσοδο';
  @override
  String get disable => 'Απενεργοποίηση';
  @override
  String get dismissButtonLabel => 'Κλείσιμο';
  @override
  String get doneButtonLabel => 'Έτοιμο';

  // ---- E ----
  @override
  String get eastInitialLabel => 'Α';
  @override
  String get emailInputLabel => 'Email';
  @override
  String get emailIsRequiredErrorText => 'Το email είναι υποχρεωτικό';
  @override
  String get emailLinkSignInButtonLabel => 'Σύνδεση με magic link';
  @override
  String get emailTakenErrorText => 'Υπάρχει ήδη λογαριασμός με αυτό το email';
  @override
  String get enable => 'Ενεργοποίηση';
  @override
  String get enableMoreSignInMethods =>
      'Ενεργοποίηση περισσότερων τρόπων σύνδεσης';
  @override
  String get enterSMSCodeText => 'Εισάγετε κωδικό SMS';

  // ---- F ----
  @override
  String get findProviderForEmailTitleText =>
      'Εισάγετε το email σας για συνέχεια';
  @override
  String get forgotPasswordButtonLabel => 'Ξεχάσατε τον κωδικό;';
  @override
  String get forgotPasswordHintText =>
      'Δώστε το email σας και θα στείλουμε σύνδεσμο επαναφοράς';
  @override
  String get forgotPasswordViewTitle => 'Ανάκτηση κωδικού';

  // ---- G ----
  @override
  String get geopointLabel => 'γεωσημείο';
  @override
  String get goBackButtonLabel => 'Πίσω';

  // ---- I ----
  @override
  String get invalidCountryCode => 'Μη έγκυρος κωδικός';
  @override
  String get isNotAValidEmailErrorText => 'Δώστε έγκυρο email';
  @override
  String get invalidVerificationCodeErrorText =>
      'Ο κωδικός που εισάγατε δεν είναι έγκυρος.';

  // ---- L ----
  @override
  String get latitudeLabel => 'πλάτος';
  @override
  String get linkEmailButtonText => 'Επόμενο';
  @override
  String get longitudeLabel => 'μήκος';

  // ---- M ----
  @override
  String get mapLabel => 'χάρτης';
  @override
  String get mfaTitle => 'Έλεγχος σε 2 βήματα';

  // ---- N ----
  @override
  String get name => 'Όνομα';
  @override
  String get northInitialLabel => 'Β';
  @override
  String get nullLabel => 'null';
  @override
  String get numberLabel => 'αριθμός';

  // ---- O ----
  @override
  String get off => 'Ανενεργό';
  @override
  String get on => 'Ενεργό';
  @override
  String get okButtonLabel => 'ΟΚ';

  // ---- P ----
  @override
  String get passwordInputLabel => 'Κωδικός πρόσβασης';
  @override
  String get passwordIsRequiredErrorText => 'Ο κωδικός είναι υποχρεωτικός';
  @override
  String get passwordResetEmailSentText =>
      'Στείλαμε email επαναφοράς κωδικού. Ελέγξτε το inbox.';
  @override
  String get phoneInputLabel => 'Αριθμός τηλεφώνου';
  @override
  String get phoneNumberInvalidErrorText => 'Μη έγκυρος αριθμός τηλεφώνου';
  @override
  String get phoneNumberIsRequiredErrorText => 'Απαιτείται αριθμός τηλεφώνου';
  @override
  String get phoneVerificationViewTitleText => 'Εισάγετε τον αριθμό τηλεφώνου';
  @override
  String get profile => 'Προφίλ';
  @override
  String get provideEmail => 'Δώστε email και κωδικό';

  // ---- R ----
  @override
  String get referenceLabel => 'αναφορά';
  @override
  String get registerActionText => 'Εγγραφή';
  @override
  String get registerHintText => 'Δεν έχετε λογαριασμό;';
  @override
  String get registerText => 'Εγγραφή';
  @override
  String get resetPasswordButtonLabel => 'Επαναφορά κωδικού';
  @override
  String get resendVerificationEmailButtonLabel =>
      'Επαναποστολή email επιβεβαίωσης';

  // ---- S ----
  @override
  String get sendLinkButtonLabel => 'Αποστολή magic link';
  @override
  String get signInActionText => 'Σύνδεση';
  @override
  String get signInHintText => 'Έχετε ήδη λογαριασμό;';
  @override
  String get signInMethods => 'Μέθοδοι σύνδεσης';
  @override
  String get signInText => 'Σύνδεση';
  @override
  String get signInWithAppleButtonText => 'Σύνδεση με Apple';
  @override
  String get signInWithEmailLinkSentText =>
      'Στείλαμε magic link στο email σας. Ελέγξτε το inbox.';
  @override
  String get signInWithEmailLinkViewTitleText => 'Σύνδεση με magic link';
  @override
  String get signInWithFacebookButtonText => 'Σύνδεση με Facebook';
  @override
  String get signInWithGoogleButtonText => 'Σύνδεση με Google';
  @override
  String get signInWithPhoneButtonText => 'Σύνδεση με τηλέφωνο';
  @override
  String get signInWithTwitterButtonText => 'Σύνδεση με Twitter';
  @override
  String get signOutButtonText => 'Αποσύνδεση';
  @override
  String get smsAutoresolutionFailedError =>
      'Αποτυχία αυτόματης ανάκτησης SMS. Εισάγετε τον κωδικό χειροκίνητα';
  @override
  String get southInitialLabel => 'Ν';
  @override
  String get stringLabel => 'συμβολοσειρά';

  // ---- T ----
  @override
  String get timestampLabel => 'χρονοσφραγίδα';
  @override
  String get typeLabel => 'τύπος';

  // ---- U ----
  @override
  String get unknownError => 'Άγνωστο σφάλμα';
  @override
  String get updateLabel => 'ενημέρωση';
  @override
  String get userNotFoundErrorText => 'Ο λογαριασμός δεν υπάρχει';
  @override
  String get uploadButtonText => 'Μεταφόρτωση αρχείου';

  // ---- V ----
  @override
  String get valueLabel => 'τιμή';
  @override
  String get verifyCodeButtonText => 'Επαλήθευση';
  @override
  String get verifyingSMSCodeText => 'Επαλήθευση κωδικού SMS…';
  @override
  String get verifyItsYouText => 'Επαληθεύστε ότι είστε εσείς';
  @override
  String get verifyPhoneNumberButtonText => 'Επόμενο';
  @override
  String get verifyEmailTitle => 'Επιβεβαίωση email';
  @override
  String get verificationEmailSentText =>
      'Στάλθηκε email επιβεβαίωσης. Ελέγξτε το inbox.';
  @override
  String get verificationFailedText => 'Αποτυχία επιβεβαίωσης email.';
  @override
  String get verificationEmailSentTextShort => 'Εστάλη email επιβεβαίωσης';
  @override
  String get emailIsNotVerifiedText => 'Το email δεν έχει επιβεβαιωθεί';
  @override
  String get waitingForEmailVerificationText => 'Αναμονή επιβεβαίωσης email';

  // ---- W ----
  @override
  String get westInitialLabel => 'Δ';
  @override
  String get wrongOrNoPasswordErrorText =>
      'Λάθος κωδικός ή ο χρήστης δεν έχει κωδικό';

  // ---- X / Y / Z ----
  //@override String get verifyEmailTitle             => 'Επιβεβαιώστε το email σας';
  @override
  String get ulinkProviderAlertTitle => 'Αφαίρεση παρόχου';
  @override
  String get unlinkProviderAlertMessage =>
      'Θέλετε σίγουρα να αφαιρέσετε αυτόν τον πάροχο;';
  @override
  String get confirmUnlinkButtonLabel => 'Αφαίρεση';
  @override
  String get cancelButtonLabel => 'Άκυρο';
  @override
  String get weakPasswordErrorText =>
      'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες';
  @override
  String get confirmDeleteAccountAlertTitle =>
      'Επιβεβαίωση διαγραφής λογαριασμού';
  @override
  String get confirmDeleteAccountAlertMessage =>
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε τον λογαριασμό σας;';
  @override
  String get confirmDeleteAccountButtonLabel => 'Ναι, διαγραφή';
  @override
  String get sendVerificationEmailLabel => 'Αποστολή email επιβεβαίωσης';
}

/// ---------------------------------------------------------------------------
///  Delegate – εκθέτει τα ElLocalizations όταν locale.languageCode == 'el'
/// ---------------------------------------------------------------------------
class GreekLocalizationsDelegate
    extends LocalizationsDelegate<FirebaseUILocalizationLabels> {
  const GreekLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'el';

  @override
  Future<FirebaseUILocalizationLabels> load(Locale locale) async {
    debugPrint('🟢 Greek delegate loaded for $locale');
    return const ElLocalizations();
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<FirebaseUILocalizationLabels> old,
  ) => false;
}
