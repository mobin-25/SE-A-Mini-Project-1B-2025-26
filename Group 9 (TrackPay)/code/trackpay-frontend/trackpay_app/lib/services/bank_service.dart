import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/bank.dart';
import 'api.dart';

class BankService {
  // ✅ Fetch Banks
  static Future<List<BankModel>> fetchBanks(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/banks/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => BankModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load banks");
    }
  }

  // ✅ Add Bank
  static Future<void> addBank({
    required int userId,
    required String bankName,
    required String accountNumber,
    required double balance,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/banks");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "bank_name": bankName,
        "account_number": accountNumber,
        "balance": balance,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to add bank");
    }
  }

  // ✅ Delete Bank
  static Future<void> deleteBank(int bankId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/bank/$bankId");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to delete bank");
    }
  }

  // ✅ Deposit Money (Correct as per backend)
  static Future<void> depositMoney(
    int userId,
    int bankId,
    double amount,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/bank/deposit");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "bank_id": bankId,
        "amount": amount,
      }),
    );

    print("Deposit Status: ${response.statusCode}");
    print("Deposit Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Deposit failed");
    }
  }
}
