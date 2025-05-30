import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as auth
    hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

import 'firebase_options.dart'; // <- δημιουργείται με `flutterfire configure`

// ----------------- Providers -----------------
final emailAuthProvider = EmailAuthProvider();
final googleProvider = GoogleProvider(
  clientId:
      '697374211054-83abftc39o0mtdi30bpc6fq4qst3unj5.apps.googleusercontent.com',
);
// ---------------------------------------------

Future<void> _saveUserToFirestore(auth.User user) async {
  final users = FirebaseFirestore.instance.collection('users');
  await users.doc(user.uid).set({
    'uid': user.uid,
    'email': user.email,
    'displayName': user.displayName,
    'photoURL': user.photoURL,
    'lastLogin': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

void main() async {
  // <- H συνάρτηση main που έλειπε
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase UI Auth Demo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        // όχι const λίστα
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('el'), Locale('en')],
      initialRoute:
          auth.FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',
      routes: {
        '/sign-in':
            (_) => SignInScreen(
              providers: [emailAuthProvider, googleProvider],
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  final user = auth.FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    _saveUserToFirestore(user); // fire-and-forget
                  }
                  Navigator.pushReplacementNamed(context, '/home');
                }),
              ],
            ),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Αρχική'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(child: Text('Συνδεδεμένος ως: ${user?.email ?? "-"}')),
    );
  }
}
