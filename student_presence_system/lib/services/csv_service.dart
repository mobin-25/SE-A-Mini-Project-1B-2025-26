import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:excel/excel.dart';

class CsvService {
  // ═══════════════════════════════════════════════════════════
  //  PICK FILE ONLY
  //  Call this BEFORE showing any loading dialog
  // ═══════════════════════════════════════════════════════════
  static Future<PlatformFile?> pickFileOnly() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;
    return result.files.single;
  }

  // ═══════════════════════════════════════════════════════════
  //  MASTER UPLOAD
  //  Creates Firebase Auth accounts + Firestore records.
  //  Division is NOT set here.
  // ═══════════════════════════════════════════════════════════
  static Future<String> uploadStudentsFromFile() async {
    FirebaseApp? secondaryApp;

    try {
      final file = await pickFileOnly();
      if (file == null) return "No file selected.";

      final students = file.name.toLowerCase().endsWith('.xlsx')
          ? _parseXlsx(file.bytes!)
          : _parseCsv(file.bytes!);

      if (students.isEmpty) return "No valid student rows found.";

      try {
        secondaryApp = Firebase.app('StudentCreatorApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'StudentCreatorApp',
          options: Firebase.app().options,
        );
      }

      FirebaseAuth secondaryAuth =
      FirebaseAuth.instanceFor(app: secondaryApp);
      await secondaryAuth.signOut();

      final firestore = FirebaseFirestore.instance;
      int recordCount = 0;
      int skippedCount = 0;

      const int chunkSize = 10;
      final chunks = <List<Map<String, String>>>[];
      for (int i = 0; i < students.length; i += chunkSize) {
        chunks.add(students.sublist(
          i,
          (i + chunkSize > students.length) ? students.length : i + chunkSize,
        ));
      }

      for (final chunk in chunks) {
        WriteBatch batch = firestore.batch();
        bool batchHasData = false;

        for (final student in chunk) {
          final String rawName = student['name'] ?? '';
          final String rollNo = student['roll_no'] ?? '';

          if (rawName.isEmpty) {
            skippedCount++;
            continue;
          }

          final String titleName = _toTitleCase(rawName);
          final String generatedEmail =
              '${rawName.replaceAll(' ', '').toLowerCase()}@apsit.edu.in';
          final String firstName = _toTitleCase(rawName.split(' ').first);
          final String generatedPassword = '${firstName}123';

          try {
            UserCredential userCred = await secondaryAuth
                .createUserWithEmailAndPassword(
              email: generatedEmail,
              password: generatedPassword,
            )
                .timeout(const Duration(seconds: 10),
                onTimeout: () =>
                throw Exception('Timeout for $generatedEmail'));

            final String uid = userCred.user!.uid;
            await secondaryAuth.signOut();

            batch.set(
              firestore.collection('students').doc(uid),
              {
                'uid': uid,
                'name': titleName,
                'roll_no': rollNo,
                'division': '',
                'email': generatedEmail,
                'default_password': generatedPassword,
                'role': 'student',
                'isFirstLogin': true,
              },
            );
            batchHasData = true;
            recordCount++;
          } catch (e) {
            skippedCount++;
            debugPrint("Skipping $generatedEmail — $e");
          }
        }

        if (batchHasData) await batch.commit();
      }

      await secondaryApp.delete();
      secondaryApp = null;

      if (recordCount == 0) {
        return "⚠️ No new students uploaded.\n"
            "$skippedCount skipped (already exist or missing data).";
      }

      return "✅ Master upload complete!\n"
          "• $recordCount account(s) created\n"
          "${skippedCount > 0 ? '• $skippedCount skipped (already exist)\n' : ''}"
          "\nNow tap a Division tile to assign students.";
    } catch (e) {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
      return "❌ Error: $e";
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  DIVISION UPLOAD — matches by NAME (not roll_no)
  //  Processes an already-picked file.
  // ═══════════════════════════════════════════════════════════
  static Future<String> assignDivisionFromPickedFile(
      PlatformFile file, String division) async {
    try {
      if (file.bytes == null) return "❌ File has no data.";

      final students = file.name.toLowerCase().endsWith('.xlsx')
          ? _parseXlsx(file.bytes!)
          : _parseCsv(file.bytes!);

      if (students.isEmpty) return "No valid student rows found.";

      final firestore = FirebaseFirestore.instance;

      // Fetch all students and build a name → docId map
      final allSnap = await firestore.collection('students').get();

      // Normalise stored names for fuzzy matching
      final Map<String, String> nameToDocId = {};
      for (final doc in allSnap.docs) {
        final storedName =
        (doc.data()['name'] ?? '').toString().trim().toLowerCase();
        if (storedName.isNotEmpty) {
          nameToDocId[storedName] = doc.id;
        }
      }

      int updatedCount = 0;
      int notFoundCount = 0;

      WriteBatch batch = firestore.batch();
      int batchCount = 0;

      for (final student in students) {
        final String rawName = student['name']?.toString().trim() ?? '';
        if (rawName.isEmpty) {
          notFoundCount++;
          continue;
        }

        // Normalise the Excel name the same way for matching
        final String normalisedName = _toTitleCase(rawName).toLowerCase();

        // Try exact match first
        String? docId = nameToDocId[normalisedName];

        // If no exact match, try without spaces (handles spacing differences)
        if (docId == null) {
          final nameNoSpaces = normalisedName.replaceAll(' ', '');
          for (final entry in nameToDocId.entries) {
            if (entry.key.replaceAll(' ', '') == nameNoSpaces) {
              docId = entry.value;
              break;
            }
          }
        }

        if (docId == null) {
          notFoundCount++;
          debugPrint("Name not found in Firestore: $rawName");
          continue;
        }

        batch.update(
          firestore.collection('students').doc(docId),
          {'division': division.toUpperCase()},
        );
        batchCount++;
        updatedCount++;

        if (batchCount == 500) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) await batch.commit();

      if (updatedCount == 0) {
        return "⚠️ No students updated.\n"
            "Make sure Master Upload was done first so names exist in the database.";
      }

      return "✅ Division $division assigned!\n"
          "• $updatedCount student(s) updated\n"
          "${notFoundCount > 0 ? '• $notFoundCount name(s) not found — run Master Upload first.' : ''}";
    } catch (e) {
      return "❌ Error: $e";
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  XLSX PARSER — Sheet1: Col0=Name, Col1=RollNo (optional)
  // ═══════════════════════════════════════════════════════════
  static List<Map<String, String>> _parseXlsx(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, String>> students = [];

    Sheet? sheet =
        excel.tables['Sheet1'] ?? excel.tables[excel.tables.keys.first];
    if (sheet == null) return students;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;
      final col0 = row[0]?.value?.toString().trim() ?? '';
      final col1 = row.length > 1
          ? (row[1]?.value?.toString().trim() ?? '')
          : '';

      if (col0.isEmpty) continue;
      if (col0.toUpperCase() == 'NAME' ||
          col0.toUpperCase().contains('ROLL') ||
          col0.toUpperCase().contains('STUDENT') ||
          col0.toUpperCase().contains('DEPARTMENT')) {
        continue;
      }

      students.add({
        'name': col0,
        'roll_no': col1,
      });
    }
    return students;
  }

  // ═══════════════════════════════════════════════════════════
  //  CSV PARSER
  // ═══════════════════════════════════════════════════════════
  static List<Map<String, String>> _parseCsv(List<int> bytes) {
    final csvString = utf8.decode(bytes);
    final lines = csvString.split(RegExp(r'\r\n|\r|\n'));
    final List<Map<String, String>> students = [];

    if (lines.isEmpty) return students;
    final headers =
    lines[0].split(',').map((e) => e.trim().toLowerCase()).toList();

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = line.split(',').map((e) => e.trim()).toList();
      final Map<String, String> row = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < cols.length) row[headers[j]] = cols[j];
      }

      if ((row['name'] ?? '').isNotEmpty) {
        students.add({
          'name': row['name'] ?? '',
          'roll_no': row['roll_no'] ?? '',
        });
      }
    }
    return students;
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPER — "SHAIKH MOBIN" → "Shaikh Mobin"
  // ═══════════════════════════════════════════════════════════
  static String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isEmpty
        ? ''
        : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}