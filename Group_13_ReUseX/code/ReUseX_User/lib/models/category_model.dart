import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String iconPath;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
          name: 'Phone', iconPath: 'assets/images/phone.webp', boxColor: Color(0xFF4CAF50)
      )
    );

    categories.add(
        CategoryModel(
            name: 'Laptop', iconPath: 'assets/images/laptop.png', boxColor: Color(0xFF4CAF50)
        )
    );

    categories.add(
        CategoryModel(
            name: 'RAM', iconPath: 'assets/images/ram.webp', boxColor: Color(0xFF4CAF50)
        )
    );

    categories.add(
        CategoryModel(
            name: 'SSD', iconPath: 'assets/images/ssd.png', boxColor: Color(0xFF4CAF50)
        )
    );

    categories.add(
        CategoryModel(
            name: 'Others', iconPath: 'assets/images/others.png', boxColor: Color(0xFF4CAF50)
        )
    );
    return categories;
  }
}