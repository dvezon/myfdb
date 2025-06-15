import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'drive_service.dart';

// config
const scriptUrl =
    'https://script.google.com/macros/s/AKfycbzNZv85DPuXnNgaM_4nS8sg5k9XT9gtSWC5LpK7H4uWUj3BYYc5G39Qzcq_PYtPsI-f/exec';
const proxyExportUrl = 'https://proxyexport-mhdemkezbq-uc.a.run.app';
const defaultFolderId = '1gQCEPMZ5y4PJX9NW73qQHMejfHN-FPcL';

// DriveService singleton
final driveServiceProvider = Provider<DriveService>((ref) {
  return DriveService(
    scriptUrl: scriptUrl,
    proxyExportUrl: proxyExportUrl,
    defaultFolderId: defaultFolderId,
  );
});

// templates
final templatesProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final svc = ref.read(driveServiceProvider);
  return svc.fetchTemplates();
});

// auth uid (απλή υλοποίηση ― βάλε listener αν θες)
final authUidProvider = Provider<String?>(
  (_) => FirebaseAuth.instance.currentUser?.uid,
);

// selected templateId
final selectedTemplateIdProvider = StateProvider<String?>((_) => null);
