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

import 'firebase_options.dart'; // generated with `flutterfire configure`
import 'main_menu.dart'; // the MainMenu widget
import 'appointments_page.dart';

// ---------------- Route names ----------------
const String routeAppointments = '/appointments';
const String routeLeaves = '/leaves';
const String routeLogbook = '/logbook';
const String routeSettings = '/settings';

// ---------------- Auth providers -------------
final emailAuthProvider = EmailAuthProvider();
final googleProvider = GoogleProvider(
  clientId:
      '697374211054-83abftc39o0mtdi30bpc6fq4qst3unj5.apps.googleusercontent.com',
);

// ---------------- Firestore helper ----------
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅  Ενεργοποίηση persistence με τις νέες ρυθμίσεις
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // on-disk cache
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    // synchronizeTabs: true,          // υπάρχει μόνο στο web
  );

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
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('el'), Locale('en')],
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey.shade300,
      ),

      // Initial route depends on auth state
      initialRoute:
          auth.FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',

      // Named routes
      routes: {
        // Authentication screen
        '/sign-in':
            (_) => SignInScreen(
              providers: [emailAuthProvider, googleProvider],
              actions: [
                // Generic action για SignedIn state
                AuthStateChangeAction<SignedIn>((context, state) {
                  final user = auth.FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    _saveUserToFirestore(user); // fire-and-forget
                  }

                  Navigator.pushReplacementNamed(context, '/home');
                }),
              ],
            ),

        // Home
        '/home': (_) => const HomeScreen(),

        // Functional placeholders
        routeAppointments: (_) => const AppointmentsPage(),
        routeLeaves: (_) => const PlaceholderScreen(title: 'Διαχείριση Αδειών'),
        routeLogbook:
            (_) => const PlaceholderScreen(
              title: 'Καταγραφή ημερολογίου συμβάντων',
            ),
        routeSettings: (_) => const PlaceholderScreen(title: 'Ρυθμίσεις'),
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
      body: const MainMenu(), // Main navigation menu
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
