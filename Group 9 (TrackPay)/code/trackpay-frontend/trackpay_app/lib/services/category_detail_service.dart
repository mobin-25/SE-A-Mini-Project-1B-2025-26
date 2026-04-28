import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import 'api.dart';

class CategoryDetailService {
  static Future<CategoryModel> fetchCategoryDetail(int categoryId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/category/$categoryId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CategoryModel.fromJson(data);
    } else {
      throw Exception("Failed to load category detail");
    }
  }
}
