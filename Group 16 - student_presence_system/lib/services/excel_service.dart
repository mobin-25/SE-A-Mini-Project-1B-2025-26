import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'subject_service.dart';

class ExcelService {
  static Future<void> exportMarksToExcel(BuildContext context, String division) async {
    try {
      // 1. Fetch Data
      final studentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('division', isEqualTo: division)
          .get();
      
      final marksSnap = await FirebaseFirestore.instance
          .collection('exam_marks')
          .get(); // We might need to filter this better if there are many marks

      final subjectsData = await SubjectService.getSubjects(division);
      final List<String> subjects = subjectsData
          .map((s) => (s['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList()
        ..sort();

      // 2. Create Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Marks - Division $division'];
      excel.delete('Sheet1');

      // 3. Header Row
      List<String> headers = ['Roll No', 'Student Name'];
      for (var sub in subjects) {
        headers.add('$sub (UT-I)');
        headers.add('$sub (UT-II)');
        headers.add('$sub (Sem Exam)');
      }
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // 4. Data Rows
      var students = studentsSnap.docs.toList()
        ..sort((a, b) {
          int r1 = int.tryParse(a['roll_no']?.toString() ?? '0') ?? 0;
          int r2 = int.tryParse(b['roll_no']?.toString() ?? '0') ?? 0;
          return r1.compareTo(r2);
        });

      for (var studentDoc in students) {
        final rollNo = studentDoc['roll_no']?.toString() ?? '';
        final name = studentDoc['name'] ?? '';
        List<CellValue?> row = [TextCellValue(rollNo), TextCellValue(name)];

        // Get marks for this student
        final studentMarks = marksSnap.docs
            .where((m) => m['roll_no']?.toString() == rollNo)
            .toList();

        for (var sub in subjects) {

          
          // Actually finding the specific doc
          QueryDocumentSnapshot? subMark;
          for(var m in studentMarks) {
            final data = m.data() as Map<String, dynamic>;
            if(data['subject'] == sub) {
              subMark = m;
              break;
            }
          }

          if (subMark != null) {
            final data = subMark.data() as Map<String, dynamic>;
            row.add(DoubleCellValue((data['ut1'] ?? 0).toDouble()));
            row.add(DoubleCellValue((data['ut2'] ?? 0).toDouble()));
            row.add(DoubleCellValue((data['sem_exam'] ?? 0).toDouble()));
          } else {
            row.add(IntCellValue(0));
            row.add(IntCellValue(0));
            row.add(IntCellValue(0));
          }
        }
        sheetObject.appendRow(row);
      }

      // 5. Save and Share
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/Marks_Division_$division.xlsx';
      final File file = File(filePath);
      
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Student Marks - Division $division');
      }

    } catch (e) {
      if (context.mounted) {
        String msg = e.toString().contains('resource-exhausted') || e.toString().contains('Quota exceeded')
            ? 'Database limit exceeded. Please try again tomorrow.'
            : 'Export failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> exportOverallAttendanceToExcel(BuildContext context, String division, List<String> subjects, List<Map<String, dynamic>> reportData) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Attendance - Div $division'];
      excel.delete('Sheet1');

      // Header Row
      List<String> headers = ['Roll No', 'Student Name'];
      headers.addAll(subjects);
      headers.add('Overall %');
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // Data Rows
      for (var data in reportData) {
        final rollNo = data['rollNo']?.toString() ?? '';
        final name = data['name'] ?? '';
        final subCounts = data['subjectCounts'] as Map<String, int>? ?? {};
        final percentage = data['percentage'] as double? ?? 0.0;

        List<CellValue?> row = [TextCellValue(rollNo), TextCellValue(name)];
        
        for (var sub in subjects) {
          int count = subCounts[sub] ?? 0;
          row.add(IntCellValue(count));
        }
        
        row.add(DoubleCellValue(double.parse(percentage.toStringAsFixed(1))));
        sheetObject.appendRow(row);
      }

      // Save and Share
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/Attendance_Div_$division.xlsx';
      final File file = File(filePath);
      
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Overall Attendance - Div $division');
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> importMarksFromExcel(BuildContext context, String division) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) return;

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // Assume the first sheet is the one we want
      String sheetName = excel.tables.keys.first;
      var sheet = excel.tables[sheetName]!;

      if (sheet.maxRows < 1) {
        throw 'Sheet is empty';
      }

      // Parse Header to find subject columns
      var headerRow = sheet.rows.first;
      Map<int, Map<String, String>> colMapping = {}; // colIndex -> {subject: "", type: ""}
      
      for (int i = 2; i < headerRow.length; i++) {
        var cellValue = headerRow[i]?.value?.toString() ?? '';
        if (cellValue.contains('(')) {
          String subName = cellValue.split('(')[0].trim();
          String type = '';
          if (cellValue.contains('UT-I')) type = 'ut1';
          else if (cellValue.contains('UT-II')) type = 'ut2';
          else if (cellValue.contains('Sem Exam')) type = 'sem_exam';
          
          if (type.isNotEmpty) {
            colMapping[i] = {'subject': subName, 'type': type};
          }
        }
      }

      int count = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Process Data Rows
      for (int r = 1; r < sheet.maxRows; r++) {
        var row = sheet.rows[r];
        if (row.isEmpty || row[0] == null) continue;

        String rollNo = row[0]!.value.toString();
        
        // Group marks by subject for this student
        Map<String, Map<String, double>> studentMarks = {};

        colMapping.forEach((colIndex, info) {
          if (colIndex < row.length && row[colIndex] != null) {
            double val = double.tryParse(row[colIndex]!.value.toString()) ?? 0;
            String sub = info['subject']!;
            String type = info['type']!;
            
            studentMarks.putIfAbsent(sub, () => {});
            studentMarks[sub]![type] = val;
          }
        });

        // Upsert marks into Firestore
        for (var entry in studentMarks.entries) {
          String subject = entry.key;
          Map<String, double> values = entry.value;

          // Find existing doc or create new one
          // To be efficient, we'd ideally query first, but for bulk import, 
          // we can use a deterministic ID like "roll_subject" or just add and let user manage duplicates.
          // Let's use a deterministic ID to avoid duplicates.
          String docId = '${division}_${rollNo}_${subject.replaceAll(' ', '_')}';
          
          DocumentReference ref = FirebaseFirestore.instance.collection('exam_marks').doc(docId);
          batch.set(ref, {
            'roll_no': rollNo,
            'division': division,
            'subject': subject,
            'ut1': values['ut1'] ?? 0,
            'ut2': values['ut2'] ?? 0,
            'sem_exam': values['sem_exam'] ?? 0,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          count++;
          if (count % 400 == 0) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
          }
        }
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count marks!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (context.mounted) {
        String msg = e.toString().contains('resource-exhausted') || e.toString().contains('Quota exceeded')
            ? 'Database limit exceeded. Please try again tomorrow.'
            : 'Import failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }
}
