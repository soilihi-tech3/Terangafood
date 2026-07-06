import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';

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

/// Singleton service managing order history (pre-seeded with mock data).
class OrderHistoryService {
  static final OrderHistoryService _instance =
      OrderHistoryService._internal();
  factory OrderHistoryService() => _instance;
  OrderHistoryService._internal();

  final List<HistoryOrder> _history = [
    HistoryOrder(
      id: "TF-498172",
      itemsSummary:
          "Thiéboudienne Penda Mbaye × 1, Bissap Royal Glacé × 2",
      total: 5500,
      date: "28 Juin 2026",
      status: "livree",
      rating: 4.5,
      paymentMethod: "wave",
      deliveryMethod: "moto",
      departure: "Restaurant Le Teranga, Plateau",
      destination: "Route de la Pointe des Almadies, Dakar",
    ),
    HistoryOrder(
      id: "TF-124098",
      itemsSummary:
          "Double Teranga Burger × 2, Pizza Teranga Spéciale × 1",
      total: 14000,
      date: "15 Juin 2026",
      status: "livree",
      rating: 5.0,
      paymentMethod: "cash",
      deliveryMethod: "voiture",
      departure: "Restaurant Le Teranga, Plateau",
      destination: "Avenue Cheikh Anta Diop, Dakar",
    ),
    HistoryOrder(
      id: "TF-039281",
      itemsSummary: "Yassa au Poulet × 1, Thiakry Onctueux × 1",
      total: 4500,
      date: "10 Juin 2026",
      status: "livree",
      rating: 4.0,
      paymentMethod: "omoney",
      deliveryMethod: "retrait",
      departure: "Restaurant Le Teranga, Plateau",
      destination: "Retrait au Restaurant Central",
    ),
  ];

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _history.map((o) => {
      'id': o.id,
      'itemsSummary': o.itemsSummary,
      'total': o.total,
      'date': o.date,
      'status': o.status,
      'rating': o.rating,
      'review': o.review,
      'paymentMethod': o.paymentMethod,
      'deliveryMethod': o.deliveryMethod,
      'departure': o.departure,
      'destination': o.destination,
    }).toList();
    await prefs.setString('order_history', jsonEncode(jsonList));
  }

  void loadFromPrefs(SharedPreferences prefs) {
    final historyStr = prefs.getString('order_history');
    if (historyStr != null) {
      try {
        final decoded = jsonDecode(historyStr) as List<dynamic>;
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
      } catch (_) {}
    }
  }

  /// Inserts a new order (just placed) at the top of the history.
  void addOrder({
    required String id,
    required Map<FoodItem, int> cart,
    required double total,
    required String paymentMethod,
    required String deliveryMethod,
    required String departure,
    required String destination,
  }) {
    final summary =
        cart.entries.map((e) => "${e.key.name} × ${e.value}").join(", ");
    final now = DateTime.now();
    const months = [
      "Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
      "Juil", "Août", "Sep", "Oct", "Nov", "Déc"
    ];
    final date = "${now.day} ${months[now.month - 1]} ${now.year}";
    _history.insert(
      0,
      HistoryOrder(
        id: id,
        itemsSummary: summary,
        total: total,
        date: date,
        status: "en_cours",
        paymentMethod: paymentMethod,
        deliveryMethod: deliveryMethod,
        departure: departure,
        destination: destination,
      ),
    );
    saveToPrefs();
  }

  void updateStatus(String id, String status) {
    final idx = _history.indexWhere((o) => o.id == id);
    if (idx >= 0) {
      _history[idx].status = status;
      saveToPrefs();
    }
  }

  void addRating(String id, double rating, String? review) {
    final idx = _history.indexWhere((o) => o.id == id);
    if (idx >= 0) {
      _history[idx].rating = rating;
      _history[idx].review = review;
      saveToPrefs();
    }
  }

  List<HistoryOrder> get all => List.from(_history);
  List<HistoryOrder> get inProgress =>
      _history.where((o) => o.status == "en_cours").toList();
  List<HistoryOrder> get delivered =>
      _history.where((o) => o.status == "livree").toList();
}
