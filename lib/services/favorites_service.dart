import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';

/// Singleton service to track the user's favourite food items.
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<String> _favoriteIds = {};
  final Map<String, FoodItem> _favoriteItems = {};

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favoriteItems.values.map((item) => {
      'id': item.id,
      'name': item.name,
      'price': item.price,
      'image': item.image,
      'category': item.category,
      'rating': item.rating,
      'description': item.description,
    }).toList();
    await prefs.setString('favorites_json', jsonEncode(jsonList));
  }

  void loadFromPrefs(SharedPreferences prefs) {
    final favStr = prefs.getString('favorites_json');
    if (favStr != null) {
      try {
        final decoded = jsonDecode(favStr) as List<dynamic>;
        _favoriteIds.clear();
        _favoriteItems.clear();
        for (var raw in decoded) {
          final item = raw as Map<String, dynamic>;
          final food = FoodItem(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            price: (item['price'] as num).toDouble(),
            image: item['image'] ?? '',
            category: item['category'] ?? '',
            rating: (item['rating'] as num).toDouble(),
            description: item['description'] ?? '',
          );
          _favoriteIds.add(food.id);
          _favoriteItems[food.id] = food;
        }
      } catch (_) {}
    }
  }

  /// Toggles favourite state. Returns true when item is now a favourite.
  bool toggle(FoodItem item) {
    bool res;
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
      _favoriteItems.remove(item.id);
      res = false;
    } else {
      _favoriteIds.add(item.id);
      _favoriteItems[item.id] = item;
      res = true;
    }
    saveToPrefs();
    return res;
  }

  List<FoodItem> get favorites => _favoriteItems.values.toList();
  int get count => _favoriteIds.length;
}
