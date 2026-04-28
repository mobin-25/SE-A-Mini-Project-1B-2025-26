import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/transaction.dart';
import 'api.dart';

class CategoryService {
  // ✅ Fetch All Categories (Dashboard + Manage Screen)
  static Future<List<CategoryModel>> fetchCategories(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/categories/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  // ✅ Create Category
  static Future<void> createCategory({
    required int userId,
    required String name,
    required double budget,
    required String icon,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/categories");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "name": name,
        "total_budget": budget,
        "icon": icon,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to create category");
    }
  }

  // ✅ Delete Category
  static Future<void> deleteCategory(int categoryId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/category/$categoryId");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to delete category");
    }
  }

  // ✅ Update Category Emoji
  static Future<void> updateCategoryEmoji(int categoryId, String emoji) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/category/$categoryId/emoji");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"icon": emoji}),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to update emoji");
    }
  }

  // ✅ Fetch Transactions of Single Category
  static Future<List<TransactionModel>> fetchCategoryTransactions(
    int categoryId,
  ) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/transactions/category/$categoryId",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load category transactions");
    }
  }
}
