// lib/services/drive_service.dart
// Drive business‑logic separated from UI. Includes safe JSON fetch and guards
// -----------------------------------------------------------------------------
import 'dart:convert';
//import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DriveService {
  DriveService({
    required this.scriptUrl,
    required this.proxyExportUrl,
    required this.defaultFolderId,
  });

  final String scriptUrl;
  final String proxyExportUrl;
  final String defaultFolderId;

  // ──────────────────────────────────────────────────────────────
  // Helper: GET + safe JSON
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw 'HTTP ${res.statusCode}: ${res.body.substring(0, 120)}';
    }

    final ct = res.headers['content-type'] ?? '';
    if (!ct.startsWith('application/json')) {
      debugPrint('▼ URI → ${uri.toString()}');
      debugPrint('▼ SERVER BODY (πρώτα 300 bytes) ▼');
      debugPrint(res.body.substring(0, 300));
      throw 'Server returned non-JSON data';
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ──────────────────────────────────────────────────────────────
  // Templates
  // ──────────────────────────────────────────────────────────────
  Future<List<Map<String, String>>> fetchTemplates() async {
    final decoded = await _getJson(
      Uri.parse('$scriptUrl?action=listTemplates'),
    );

    if (decoded['ok'] != true) {
      throw decoded['message'] ?? 'Unknown error';
    }

    final raw = decoded['templates'] as List<dynamic>;
    return raw
        .map<Map<String, String>>(
          (e) => {
            'name': e['name'].toString(),
            'fileId': e['fileId'].toString(),
          },
        )
        .toList()
      ..sort(
        (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
      );
  }

  // ──────────────────────────────────────────────────────────────
  // Docs list
  // ──────────────────────────────────────────────────────────────
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchDocs({
    required String uid,
    required String templateId,
  }) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('mydocs')
            .where('templateId', isEqualTo: templateId)
            .get();

    final docs =
        snap.docs..sort((a, b) {
          final ta = a['createdAt'] as Timestamp?;
          final tb = b['createdAt'] as Timestamp?;
          return (tb?.millisecondsSinceEpoch ?? 0).compareTo(
            ta?.millisecondsSinceEpoch ?? 0,
          );
        });

    return docs;
  }

  Future<void> deleteDoc({required String uid, required String docId}) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mydocs')
          .doc(docId)
          .delete();

  Future<void> saveDoc({
    required String uid,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mydocs');

    if (docId == null) {
      await col.add(data);
    } else {
      await col.doc(docId).update(data);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Export
  // ──────────────────────────────────────────────────────────────
  Future<void> exportDoc({
    required String uid,
    required String templateId,
    required Map<String, dynamic> docData,
    required Map<String, dynamic> userSettings,
  }) async {
    if (templateId.isEmpty) {
      throw 'templateId is empty – choose template first';
    }

    // 1. placeholders
    final keysJson = await _getJson(
      Uri.parse(
        '$scriptUrl?action=listKeys&templateId=${Uri.encodeComponent(templateId)}',
      ),
    );
    if (keysJson['ok'] != true) {
      throw keysJson['message'] ?? 'listKeys error';
    }
    final keys = List<String>.from(keysJson['keys']);

    // 2. form fields
    final formFields = {
      'subject': docData['subject'],
      'title': docData['subject'],
      'protocol': docData['protocol'],
      'date': DateFormat(
        'dd/MM/yyyy',
      ).format((docData['date'] as Timestamp).toDate()),
    };

    // 3. record
    final record = <String, dynamic>{};
    for (final k in keys) {
      if (formFields.containsKey(k)) {
        record[k] = formFields[k];
      } else if (userSettings.containsKey(k)) {
        record[k] = userSettings[k];
      } else {
        record[k] = 'ΑΓΝΩΣΤΟ:$k';
      }
    }

    // 4. folder
    final folderId = _extractId(
      (userSettings['googleFolder'] as String?) ?? defaultFolderId,
    );

    // 5. proxy call
    final payload = {
      'uid': uid,
      'folderId': folderId,
      'scriptUrl': scriptUrl,
      'templateId': templateId,
      'filename': docData['filename'],
      'record': record,
    };

    final res = await http.post(
      Uri.parse(proxyExportUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final decodedExport = jsonDecode(res.body);

    if (res.statusCode != 200 || decodedExport['ok'] != true) {
      throw decodedExport['message'] ?? 'export error';
    }

    // 6. open doc
    final urlStr = decodedExport['url']?.toString();
    if (urlStr != null && urlStr.isNotEmpty) {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Utils
  // ──────────────────────────────────────────────────────────────
  String _extractId(String input) =>
      RegExp(r'[-\w]{25,}').firstMatch(input)?.group(0) ?? input;
}
