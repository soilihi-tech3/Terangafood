import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Singleton service to track the user's favourite food items.
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<String> _favoriteIds = {};
  final Map<String, FoodItem> _favoriteItems = {};

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> fetchFavorites(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/favorites/$email'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        _favoriteIds.clear();
        _favoriteItems.clear();
        for (var raw in decoded) {
          final item = raw as Map<String, dynamic>;
          final food = FoodItem(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            price: (item['price'] as num).toDouble(),
            imageUrl: item['imageUrl'] ?? item['image'] ?? '',
            category: item['category'] ?? '',
            rating: (item['rating'] as num).toDouble(),
            description: item['description'] ?? '',
            ingredients: List<String>.from(item['ingredients'] ?? []),
          );
          _favoriteIds.add(food.id);
          _favoriteItems[food.id] = food;
        }
      }
    } catch (_) {}
  }

  /// Toggles favourite state. Returns true when item is now a favourite.
  Future<bool> toggle(FoodItem item) async {
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

    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': AuthService().email,
          'item': {
            'id': item.id,
            'name': item.name,
            'price': item.price,
            'imageUrl': item.imageUrl,
            'category': item.category,
            'rating': item.rating,
            'description': item.description,
            'ingredients': item.ingredients,
          }
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return res;
  }

  List<FoodItem> get favorites => _favoriteItems.values.toList();
  int get count => _favoriteIds.length;
}
