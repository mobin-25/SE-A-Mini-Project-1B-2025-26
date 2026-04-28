import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api.dart';

class PaymentService {
  static Future<Map<String, dynamic>> makePayment({
    required int userId,
    required int bankId,
    required int categoryId,
    required String receiver,
    required double amount,
    required String pin,
    required bool override,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/pay");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "bank_id": bankId,
        "category_id": categoryId,
        "receiver_name": receiver,
        "amount": amount,
        "pin": pin,
        "override": override,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"error": true, "message": jsonDecode(response.body)["detail"]};
    }
  }
}
