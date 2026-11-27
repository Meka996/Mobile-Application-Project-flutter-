import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../models/product.dart';

class CatalogFilters extends StatelessWidget {
  const CatalogFilters({
    super.key,
    required this.controller,
    required this.category,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    this.showCategoryHeading = false,
  });

  static const allCategories = 'All';
  static const _categories = [
    allCategories,
    'Dresses',
    'Jackets',
    'Shoes',
    'Bags',
    'Tops',
    'Pants',
  ];

  final TextEditingController controller;
  final String category;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final bool showCategoryHeading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VeloraTextField(
            controller: controller,
            hint: 'Search products...',
            icon: Icons.search,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
          ),
          SizedBox(
            height: showCategoryHeading ? AppLayout.page : AppLayout.medium,
          ),
          if (showCategoryHeading) ...[
            Text(
              'Shop by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppLayout.small),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: AppLayout.small,
              children: [
                for (final value in _categories)
                  ChoiceChip(
                    label: Text(value),
                    selected: category == value,
                    onSelected: (_) => onCategoryChanged(value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Product> filterProducts(
  List<Product> products,
  String search,
  String category,
) {
  final query = search.trim().toLowerCase();
  final selected = category.toLowerCase();

  return products.where((product) {
    final productCategory = product.category.toLowerCase();
    final matchesSearch =
        product.name.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query) ||
        productCategory.contains(query);
    final matchesCategory =
        category == CatalogFilters.allCategories || productCategory == selected;
    return matchesSearch && matchesCategory;
  }).toList();
}
