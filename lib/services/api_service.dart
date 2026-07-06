import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/food_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  // Local Static Data for Fallback
  static final List<LocationRegion> fallbackLocations = [
    LocationRegion(
      region: "Dakar",
      neighborhoods: [
        LocationNeighborhood(
          name: "Almadies",
          streets: [
            LocationStreet(name: "Route de la Pointe des Almadies", lat: 14.7465, lng: -17.5258),
            LocationStreet(name: "Rue des Mamelles", lat: 14.7238, lng: -17.5112),
            LocationStreet(name: "Avenue du Plateau", lat: 14.7390, lng: -17.5190)
          ]
        ),
        LocationNeighborhood(
          name: "Plateau",
          streets: [
            LocationStreet(name: "Avenue Léopold Sédar Senghor", lat: 14.6678, lng: -17.4344),
            LocationStreet(name: "Rue Carnot", lat: 14.6712, lng: -17.4367),
            LocationStreet(name: "Boulevard de la République", lat: 14.6645, lng: -17.4390)
          ]
        ),
        LocationNeighborhood(
          name: "Médina",
          streets: [
            LocationStreet(name: "Avenue Blaise Diagne", lat: 14.6822, lng: -17.4485),
            LocationStreet(name: "Rue 22", lat: 14.6845, lng: -17.4510)
          ]
        ),
        LocationNeighborhood(
          name: "Fann / Mermoz",
          streets: [
            LocationStreet(name: "Avenue Cheikh Anta Diop", lat: 14.6890, lng: -17.4690),
            LocationStreet(name: "Route de la Corniche Ouest", lat: 14.6925, lng: -17.4780)
          ]
        )
      ]
    ),
    LocationRegion(
      region: "Thiès",
      neighborhoods: [
        LocationNeighborhood(
          name: "Randoulène",
          streets: [
            LocationStreet(name: "Avenue de Caen", lat: 14.7935, lng: -16.9242),
            LocationStreet(name: "Rue Foch", lat: 14.7912, lng: -16.9210)
          ]
        ),
        LocationNeighborhood(
          name: "Grand Standing",
          streets: [
            LocationStreet(name: "Route de Dakar", lat: 14.7820, lng: -16.9405)
          ]
        )
      ]
    ),
    LocationRegion(
      region: "Saint-Louis",
      neighborhoods: [
        LocationNeighborhood(
          name: "Île de Saint-Louis",
          streets: [
            LocationStreet(name: "Rue Blaise Diagne", lat: 15.0255, lng: -16.5050),
            LocationStreet(name: "Quai Henry Jay", lat: 15.0220, lng: -16.5042)
          ]
        )
      ]
    )
  ];

  static final MapCoordinates restaurantLocation = MapCoordinates(lat: 14.6812, lng: -17.4435);

  static final List<FoodItem> fallbackMenu = [
    FoodItem(
      id: "1",
      name: "Thiéboudienne Penda Mbaye",
      category: "Plats Sénégalais",
      description: "Le plat national emblématique du Sénégal. Riz cassé rouge cuit dans un bouillon de poisson savoureux, accompagné de poisson farci, manioc, carotte, chou et aubergine.",
      price: 3500,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop",
      ingredients: ["Riz cassé", "Poisson Dorade", "Légumes", "Piment", "Guedj", "Yet"]
    ),
    FoodItem(
      id: "2",
      name: "Yassa au Poulet",
      category: "Plats Sénégalais",
      description: "Poulet mariné au citron, à la moutarde et à l'ail, braisé puis mijoté dans une généreuse sauce aux oignons caramélisés. Servi avec du riz blanc parfumé.",
      price: 3000,
      rating: 4.8,
      imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop",
      ingredients: ["Poulet fermier", "Oignons", "Citron vert", "Moutarde", "Olives", "Riz parfumé"]
    ),
    FoodItem(
      id: "3",
      name: "Mafé au Boeuf",
      category: "Plats Sénégalais",
      description: "Un ragoût onctueux originaire de l'Afrique de l'Ouest, composé de morceaux de bœuf mijotés dans une sauce riche à base de pâte d'arachide et de tomates.",
      price: 3200,
      rating: 4.7,
      imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&auto=format&fit=crop",
      ingredients: ["Viande de bœuf", "Pâte d'arachide", "Pommes de terre", "Carottes", "Huile de palme"]
    ),
    FoodItem(
      id: "4",
      name: "Double Teranga Burger",
      category: "Burgers",
      description: "Double steak de bœuf grillé, fromage cheddar fondu, oignons caramélisés au yassa, laitue fraîche et sauce spéciale Teranga dans un pain brioché.",
      price: 4500,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop",
      ingredients: ["Pain brioché", "Double Steak de Boeuf", "Cheddar", "Sauce Yassa", "Laitue", "Frites"]
    ),
    FoodItem(
      id: "burger_2",
      name: "Cheese Delivo Burger",
      category: "Burgers",
      description: "Single steak de bœuf juteux, cheddar fondu, cornichons craquants, oignons frais et notre sauce burger maison.",
      price: 3500,
      rating: 4.8,
      imageUrl: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500&auto=format&fit=crop",
      ingredients: ["Pain sésame", "Steak Haché", "Cheddar", "Cornichons", "Sauce Maison"]
    ),
    FoodItem(
      id: "burger_3",
      name: "BBQ Bacon Crispy Burger",
      category: "Burgers",
      description: "Steak de bœuf grillé à la flamme, bacon croustillant, rondelles d'oignon frites, fromage suisse et sauce barbecue fumée.",
      price: 4800,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=500&auto=format&fit=crop",
      ingredients: ["Pain Artisanal", "Steak de Boeuf", "Bacon", "Rings d'Oignon", "Sauce BBQ"]
    ),
    FoodItem(
      id: "burger_4",
      name: "Spicy Chicken Zinger",
      category: "Burgers",
      description: "Filet de poulet croustillant et épicé, laitue croquante, fromage fondu et sauce mayonnaise piquante dans un pain doré.",
      price: 4000,
      rating: 4.7,
      imageUrl: "https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?w=500&auto=format&fit=crop",
      ingredients: ["Pain Brioché", "Poulet Frit Épicé", "Laitue", "Fromage", "Mayo Piquante"]
    ),
    FoodItem(
      id: "5",
      name: "Pizza Teranga Spéciale",
      category: "Pizza",
      description: "Sauce tomate maison, mozzarella premium, lanières de poulet yassa, oignons doux, olives noires et un filet d'huile épicée.",
      price: 5000,
      rating: 4.6,
      imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop",
      ingredients: ["Pâte à pizza fine", "Poulet grillé", "Oignons caramélisés", "Mozzarella", "Origan"]
    ),
    FoodItem(
      id: "pizza_2",
      name: "Pizza Margherita Classic",
      category: "Pizza",
      description: "La traditionnelle italienne : sauce tomate mijotée, double mozzarella fondante, basilic frais et un filet d'huile d'olive extra vierge.",
      price: 4000,
      rating: 4.8,
      imageUrl: "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=500&auto=format&fit=crop",
      ingredients: ["Pâte à pizza", "Sauce Tomate", "Mozzarella", "Basilic frais"]
    ),
    FoodItem(
      id: "pizza_3",
      name: "Pizza Pepperoni & Cheese",
      category: "Pizza",
      description: "Une pizza généreuse garnie de tranches de pepperoni boeuf épicé, mozzarella abondante et sauce tomate sur pâte croustillante.",
      price: 4800,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=500&auto=format&fit=crop",
      ingredients: ["Pâte épaisse", "Double Pepperoni", "Mozzarella", "Origan"]
    ),
    FoodItem(
      id: "pizza_4",
      name: "Pizza Quatre Fromages",
      category: "Pizza",
      description: "Pour les amateurs de fromage : alliance fondante de mozzarella, gorgonzola crémeux, parmesan râpé et chèvre doux sur base sauce tomate ou crème.",
      price: 5500,
      rating: 4.7,
      imageUrl: "https://images.unsplash.com/photo-1573821663912-569905455b1c?w=500&auto=format&fit=crop",
      ingredients: ["Pâte fine", "Mozzarella", "Gorgonzola", "Parmesan", "Chèvre"]
    ),
    FoodItem(
      id: "6",
      name: "Thiakry Onctueux",
      category: "Desserts",
      description: "Le dessert traditionnel sénégalais à base de semoule de mil mélangée avec un yaourt sucré aromatisé à la fleur d'oranger et à la muscade.",
      price: 1500,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&auto=format&fit=crop",
      ingredients: ["Mil", "Yaourt concentré (sow)", "Sucre", "Vanille", "Fleur d'oranger", "Raisins secs"]
    ),
    FoodItem(
      id: "7",
      name: "Bissap Royal Glacé",
      category: "Boissons",
      description: "Boisson rafraîchissante traditionnelle sénégalaise préparée à partir d'infusion de fleurs d'hibiscus rouge séchées, aromatisée à la menthe fraîche.",
      price: 1000,
      rating: 4.9,
      imageUrl: "https://images.unsplash.com/photo-1497534446932-c925b458314e?w=500&auto=format&fit=crop",
      ingredients: ["Fleurs d'Hibiscus", "Sucre", "Menthe fraîche", "Arôme de fraise"]
    ),
    FoodItem(
      id: "8",
      name: "Jus de Bouye (Pain de Singe)",
      category: "Boissons",
      description: "Jus traditionnel épais et velouté à base de pulpe de fruit du baobab sauvage du Sénégal, mélangé avec un peu de lait concentré sucré.",
      price: 1200,
      rating: 4.8,
      imageUrl: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500&auto=format&fit=crop",
      ingredients: ["Pain de singe (Baobab)", "Lait concentré", "Sucre vanillé", "Eau"]
    )
  ];

  // In-memory simulation fallback database
  static final Map<String, OrderModel> localOrders = {};

  // Search Address on OSM Nominatim
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=5&countrycodes=sn';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TerangaFoodApp/1.0.0 (contact@terangafood.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'] as String,
          'lat': double.tryParse(item['lat'] ?? '') ?? 0.0,
          'lon': double.tryParse(item['lon'] ?? '') ?? 0.0,
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // Fetch locations
  Future<List<LocationRegion>> getLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var locList = data['locations'] as List;
        return locList.map((l) => LocationRegion.fromJson(l)).toList();
      }
    } catch (_) {
      // Fallback
    }
    return fallbackLocations;
  }

  static final List<FoodItem> customMenuItems = [];

  // Fetch food menu
  Future<List<FoodItem>> getMenu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        final list = data.map((item) => FoodItem.fromJson(item)).toList();
        return [...list, ...customMenuItems];
      }
    } catch (_) {
      // Fallback
    }
    return [...fallbackMenu, ...customMenuItems];
  }

  // Create order
  Future<OrderModel> createOrder(List<OrderItem> items, String address, String deliveryMethod, {double? lat, double? lng}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': items.map((item) => {
            'id': item.foodItem.id,
            'name': item.foodItem.name,
            'price': item.foodItem.price,
            'quantity': item.quantity
          }).toList(),
          'address': address,
          'deliveryMethod': deliveryMethod,
          if (lat != null && lng != null) ...{
            'lat': lat,
            'lng': lng,
          }
        })
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        return OrderModel(
          id: data['id'],
          items: items,
          address: data['address'],
          deliveryMethod: data['deliveryMethod'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
          status: data['status'],
          driverLocation: MapCoordinates.fromJson(data['driverLocation']),
          restaurantLocation: MapCoordinates.fromJson(data['restaurantLocation']),
          destinationLocation: MapCoordinates.fromJson(data['destinationLocation']),
        );
      }
    } catch (_) {
      // Fallback
    }

    // Local Order Creation Simulation
    final orderId = 'TF-${100000 + (localOrders.length * 17) % 899999}';
    
    // Find destination
    MapCoordinates destCoords = lat != null && lng != null 
        ? MapCoordinates(lat: lat, lng: lng)
        : MapCoordinates(lat: 14.7238, lng: -17.5112);
    if (lat == null || lng == null) {
      for (var reg in fallbackLocations) {
        for (var neigh in reg.neighborhoods) {
          for (var street in neigh.streets) {
            if (street.name == address) {
              destCoords = MapCoordinates(lat: street.lat, lng: street.lng);
              break;
            }
          }
        }
      }
    }

    final newOrder = OrderModel(
      id: orderId,
      items: List.from(items),
      address: address,
      deliveryMethod: deliveryMethod,
      createdAt: DateTime.now(),
      status: "confirmée",
      driverLocation: restaurantLocation,
      restaurantLocation: restaurantLocation,
      destinationLocation: destCoords,
    );

    localOrders[orderId] = newOrder;
    return newOrder;
  }

  // Get order updates
  Future<OrderModel> getOrder(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$orderId')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Find matching items from local or standard models
        return OrderModel(
          id: data['id'],
          items: [], // Simplification for remote fetch mapping details
          address: data['address'],
          deliveryMethod: data['deliveryMethod'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
          status: data['status'],
          driverLocation: MapCoordinates.fromJson(data['driverLocation']),
          restaurantLocation: MapCoordinates.fromJson(data['restaurantLocation']),
          destinationLocation: MapCoordinates.fromJson(data['destinationLocation']),
        );
      }
    } catch (_) {
      // Fallback
    }

    // Local simulation update
    final order = localOrders[orderId];
    if (order == null) throw Exception("Order not found locally");

    final elapsed = DateTime.now().difference(order.createdAt).inSeconds;

    if (elapsed < 10) {
      order.status = "confirmée";
      order.driverLocation = order.restaurantLocation;
    } else if (elapsed < 25) {
      order.status = "en_preparation";
      order.driverLocation = order.restaurantLocation;
    } else if (elapsed < 60) {
      order.status = "en_chemin";
      final fraction = (elapsed - 25) / 35.0; // Interpolate 0.0 -> 1.0
      order.driverLocation = MapCoordinates(
        lat: order.restaurantLocation.lat + (order.destinationLocation.lat - order.restaurantLocation.lat) * fraction,
        lng: order.restaurantLocation.lng + (order.destinationLocation.lng - order.restaurantLocation.lng) * fraction,
      );
    } else {
      order.status = "livree";
      order.driverLocation = order.destinationLocation;
    }

    return order;
  }
}
