import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'drive_service.dart';

// config
const scriptUrl = '…';
const proxyExportUrl = '…';
const defaultFolderId = '…';

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
