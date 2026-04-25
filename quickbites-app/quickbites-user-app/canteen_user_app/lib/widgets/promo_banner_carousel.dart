import 'package:flutter/material.dart';

/// Legacy carousel widget - functionality moved to home_screen.dart with sticky header design
@Deprecated('Use category chips from home_screen.dart instead')
class PromoBannerCarousel extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const PromoBannerCarousel({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
