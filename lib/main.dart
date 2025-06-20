import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as auth
    hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

import 'mylib/firebase_options.dart';
import 'main_menu.dart';
import 'appointments_page.dart';
import 'event_diary_page.dart';
import 'screen_settings.dart';
import 'create_doc.dart';
import 'mylib/mywidgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------- Auth providers -------------
final emailAuthProvider = EmailAuthProvider();

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

/*Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  devUid = 'oRP8yo3mJcPF03N5kAWfgEwZaj03';
  runApp(const MyApp());
}
*/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  devUid = 'oRP8yo3mJcPF03N5kAWfgEwZaj03';

  // ▼▼▼ ΕΔΩ: ProviderScope ψηλότερα απ' όλα ▼▼▼
  runApp(const ProviderScope(child: MyApp()));
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

      supportedLocales: const [Locale('el'), Locale('en')],
      localizationsDelegates: const [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        //GreekLocalizationsDelegate(),
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

          return Scaffold(
            backgroundColor: const Color(0xFFE8F5E9),
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100.0),
                    child: SignInScreen(
                      headerBuilder: (context, constraints, _) {
                        return const AppsDiscriptionHead();
                      },
                      providers: [emailAuthProvider],
                      actions: [
                        AuthStateChangeAction<SignedIn>((context, state) async {
                          final user = auth.FirebaseAuth.instance.currentUser;
                          if (user != null) await _saveUserToFirestore(user);
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: AppsDiscriptionTail()),
                ),
              ],
            ),
          );
        },
      ),

      routes: {
        '/appointments': (_) => const AppointmentsPage(),
        '/createdoc': (_) => const TemplateDropdownPage(),
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
    // final labels = FirebaseUILocalizations.labelsOf(context);
    //   print(labels.runtimeType); // για να δεις τι τύπος είναι
    //  print(labels); // για να δεις τι έχει διαθέσιμο
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
