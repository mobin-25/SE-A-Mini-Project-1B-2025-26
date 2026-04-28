import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "demnckgtw";
  static const String uploadPreset = "reusex_preset";

  static Future<String?> uploadImage(dynamic image) async {
    try {
      final url = Uri.parse(
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          image,
          filename: "upload.jpg",
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
        ));
      }

      var response = await request.send();
      final res = await http.Response.fromStream(response);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${res.body}");

      if (response.statusCode == 200) {
        final data = json.decode(res.body);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      print("UPLOAD ERROR: $e");
      return null;
    }
  }
}