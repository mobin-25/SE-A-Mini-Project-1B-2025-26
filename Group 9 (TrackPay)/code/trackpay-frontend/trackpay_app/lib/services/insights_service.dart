import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class InsightsService {
  static Future<Map<String, dynamic>> fetchInsights(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/insights/$userId");

    final response = await http.get(url);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load insights");
    }
  }
}
