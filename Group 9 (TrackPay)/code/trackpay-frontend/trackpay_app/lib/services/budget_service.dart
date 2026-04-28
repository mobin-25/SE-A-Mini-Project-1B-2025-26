import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class BudgetService {
  // ✅ Reset All Budgets (Monthly Reset)
  static Future<void> resetAllBudgets(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/reset-budgets/$userId");

    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to reset monthly budgets");
    }
  }

  // ✅ Update Single Category Budget
  static Future<void> updateCategoryBudget(
    int categoryId,
    double newBudget,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/category/$categoryId/budget");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"new_total_budget": newBudget}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update category budget");
    }
  }
}
