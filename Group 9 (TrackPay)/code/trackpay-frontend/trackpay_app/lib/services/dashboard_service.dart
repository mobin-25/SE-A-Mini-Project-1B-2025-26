import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/transaction.dart';
import 'api.dart';

class DashboardService {
  // Fetch Categories
  static Future<List<CategoryModel>> fetchCategories(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/categories/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;

      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  // Fetch Transactions
  static Future<List<TransactionModel>> fetchTransactions(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/transactions/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;

      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load transactions");
    }
  }
}
