import 'package:flutter/material.dart';

/// Singleton service to manage categories dynamically.
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final List<Map<String, dynamic>> _categories = [
    {"name": "Tous", "icon": Icons.grid_view_rounded},
    {"name": "Plats Sénégalais", "icon": Icons.rice_bowl_rounded},
    {"name": "Burgers", "icon": Icons.lunch_dining_rounded},
    {"name": "Pizza", "icon": Icons.local_pizza_rounded},
    {"name": "Boissons", "icon": Icons.local_drink_rounded},
    {"name": "Desserts", "icon": Icons.cake_rounded},
  ];

  List<Map<String, dynamic>> get categories => List.from(_categories);

  List<String> get categoryNames =>
      _categories.map((c) => c["name"] as String).toList();

  void addCategory(String name, IconData icon) {
    if (!_categories.any((c) => c["name"].toString().toLowerCase() == name.toLowerCase())) {
      _categories.add({"name": name, "icon": icon});
    }
  }

  void deleteCategory(String name) {
    if (name != "Tous") {
      _categories.removeWhere((c) => c["name"] == name);
    }
  }
}
