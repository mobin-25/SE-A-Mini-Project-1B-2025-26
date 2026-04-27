import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'demnckgtw';
  static const String uploadPreset = 'reusex_preset';

  static String get _uploadUrl =>
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

  static Future<String?> uploadImage(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final resStr = await response.stream.bytesToString();

      debugPrint("Cloudinary mobile status: ${response.statusCode}");
      debugPrint("Cloudinary mobile response: $resStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(resStr);
        return data['secure_url'];
      }

      return null;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  static Future<String?> uploadWebImage(Uint8List bytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

      final response = await request.send();
      final resStr = await response.stream.bytesToString();

      debugPrint("Cloudinary web status: ${response.statusCode}");
      debugPrint("Cloudinary web response: $resStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(resStr);
        return data['secure_url'];
      }

      return null;
    } catch (e) {
      debugPrint("Web Upload Error: $e");
      return null;
    }
  }
}