import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthApiService {

  static Future<String> getHealthTrend() async {

    final response = await http.get(
      Uri.parse("https://disease.sh/v3/covid-19/all"),
    );

    final data = jsonDecode(response.body);

    int todayCases = data["todayCases"];

    if (todayCases > 50000) {

      return "⚠ High infection trend today.\n"
          "Precautions:\n"
          "• Wear a mask in crowded areas\n"
          "• Wash hands frequently\n"
          "• Avoid large gatherings";

    } else if (todayCases > 10000) {

      return "⚠ Moderate infection trend.\n"
          "Precautions:\n"
          "• Maintain hygiene\n"
          "• Avoid sick individuals";

    } else {

      return "✅ Infection levels are currently stable.\n"
          "Stay healthy:\n"
          "• Maintain good hygiene\n"
          "• Stay physically active";
    }
  }
}