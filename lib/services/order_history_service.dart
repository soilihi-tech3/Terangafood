import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Represents one entry in the local order history.
class HistoryOrder {
  final String id;
  final String itemsSummary;
  final double total;
  final String date;
  String status; // "en_cours" | "livree" | "annulee"
  double? rating;
  String? review;
  final String paymentMethod; // "cash" | "wave" | "omoney"
  final String deliveryMethod; // "moto" | "voiture" | "retrait"
  final String departure;
  final String destination;

  HistoryOrder({
    required this.id,
    required this.itemsSummary,
    required this.total,
    required this.date,
    required this.status,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.departure,
    required this.destination,
    this.rating,
    this.review,
  });
}

/// Singleton service managing order history.
class OrderHistoryService {
  static final OrderHistoryService _instance =
      OrderHistoryService._internal();
  factory OrderHistoryService() => _instance;
  OrderHistoryService._internal();

  final List<HistoryOrder> _history = [];

  Future<void> fetchHistory(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/history/$email'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        _history.clear();
        for (var item in decoded) {
          final val = item as Map<String, dynamic>;
          _history.add(
            HistoryOrder(
              id: val['id'] ?? '',
              itemsSummary: val['itemsSummary'] ?? '',
              total: (val['total'] as num).toDouble(),
              date: val['date'] ?? '',
              status: val['status'] ?? '',
              rating: val['rating'] != null ? (val['rating'] as num).toDouble() : null,
              review: val['review'],
              paymentMethod: val['paymentMethod'] ?? 'cash',
              deliveryMethod: val['deliveryMethod'] ?? 'moto',
              departure: val['departure'] ?? '',
              destination: val['destination'] ?? '',
            ),
          );
        }
      }
    } catch (_) {}
  }

  /// Inserts a new order (just placed) at the top of the history.
  Future<void> addOrder({
    required String id,
    required Map<FoodItem, int> cart,
    required double total,
    required String paymentMethod,
    required String deliveryMethod,
    required String departure,
    required String destination,
  }) async {
    final summary =
        cart.entries.map((e) => "${e.key.name} × ${e.value}").join(", ");
    final now = DateTime.now();
    const months = [
      "Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
      "Juil", "Août", "Sep", "Oct", "Nov", "Déc"
    ];
    final date = "${now.day} ${months[now.month - 1]} ${now.year}";
    final newOrder = HistoryOrder(
      id: id,
      itemsSummary: summary,
      total: total,
      date: date,
      status: "en_cours",
      paymentMethod: paymentMethod,
      deliveryMethod: deliveryMethod,
      departure: departure,
      destination: destination,
    );
    _history.insert(0, newOrder);

    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': AuthService().email,
          'order': {
            'id': newOrder.id,
            'itemsSummary': newOrder.itemsSummary,
            'total': newOrder.total,
            'date': newOrder.date,
            'status': newOrder.status,
            'paymentMethod': newOrder.paymentMethod,
            'deliveryMethod': newOrder.deliveryMethod,
            'departure': newOrder.departure,
            'destination': newOrder.destination,
          }
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  void updateStatus(String id, String status) {
    final idx = _history.indexWhere((o) => o.id == id);
    if (idx >= 0) {
      _history[idx].status = status;
    }
  }

  Future<void> addRating(String id, double rating, String? review) async {
    final idx = _history.indexWhere((o) => o.id == id);
    if (idx >= 0) {
      _history[idx].rating = rating;
      _history[idx].review = review;
      try {
        await http.put(
          Uri.parse('${ApiService.baseUrl}/history/rate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': AuthService().email,
            'id': id,
            'rating': rating,
            'review': review,
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }

  List<HistoryOrder> get all => List.from(_history);
  List<HistoryOrder> get inProgress =>
      _history.where((o) => o.status == "en_cours").toList();
  List<HistoryOrder> get delivered =>
      _history.where((o) => o.status == "livree").toList();
}
