class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final double totalBudget;
  final double remainingBudget;
  final double usedPercent;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.totalBudget,
    required this.remainingBudget,
    required this.usedPercent,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"],
      name: json["name"],

      // ✅ If icon is missing, use 📁
      icon: json["icon"] ?? "📁",

      totalBudget: (json["total_budget"] ?? 0).toDouble(),
      remainingBudget: (json["remaining_budget"] ?? 0).toDouble(),

      // ✅ If used_percent missing, use 0
      usedPercent: (json["used_percent"] ?? 0).toDouble(),
    );
  }
}
