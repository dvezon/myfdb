// main.dart
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

import 'firebase_options.dart';
import 'main_menu.dart';
import 'appointments_page.dart';
import 'event_diary_page.dart';
import 'screen_settings.dart';
import 'greek_localizations.dart';

// ---------------- Auth providers -------------
final emailAuthProvider = EmailAuthProvider();
final googleProvider = GoogleProvider(
  clientId:
      '697374211054-83abftc39o0mtdi30bpc6fq4qst3unj5.apps.googleusercontent.com',
);

// ---------------- Global UID -------------
String? globalUid;
String? devUid;

// ---------------- Firestore helper ----------
Future<void> _saveUserToFirestore(auth.User user) async {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'uid': user.uid,
    'email': user.email,
    'displayName': user.displayName,
    'photoURL': user.photoURL,
    'lastLogin': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  globalUid = user.uid;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  devUid = 'oRP8yo3mJcPF03N5kAWfgEwZaj03';
  runApp(const MyApp());
}

// ====================================================
//                       MyApp
// ====================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Admin',
      debugShowCheckedModeBanner: false,

      locale: const Locale('el'),
      supportedLocales: const [Locale('el'), Locale('en')],
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        const GreekLocalizationsDelegate(),
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: const Color(0xFFE8F5E9)),

      home: StreamBuilder<auth.User?>(
        stream: auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            _saveUserToFirestore(snapshot.data!);
            return const HomeScreen();
          }

          return SignInScreen(
            providers: [emailAuthProvider, googleProvider],
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                final user = auth.FirebaseAuth.instance.currentUser;
                if (user != null) await _saveUserToFirestore(user);
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              }),
            ],
          );
        },
      ),
      routes: {
        '/appointments': (_) => const AppointmentsPage(),
        '/leaves': (_) => const PlaceholderScreen(title: 'Διαχείριση Αδειών'),
        '/createdoc':
            (_) => const PlaceholderScreen(title: 'Δημιουργία Εγγράφου'),
        '/logbook': (_) => const EventDiaryPage(year: 2025),
        '/settings': (_) => const EditFieldsScreen(),
      },
    );
  }
}

// ====================================================
//                     HomeScreen
// ====================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Καλωσήρθες, ${user?.displayName ?? 'Χρήστη'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const MainMenu(),
    );
  }
}

// ====================================================
//                 Generic placeholder page
// ====================================================
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
  );
}
