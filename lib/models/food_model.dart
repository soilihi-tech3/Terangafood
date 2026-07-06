class LocationStreet {
  final String name;
  final double lat;
  final double lng;

  LocationStreet({required this.name, required this.lat, required this.lng});

  factory LocationStreet.fromJson(Map<String, dynamic> json) {
    return LocationStreet(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class LocationNeighborhood {
  final String name;
  final List<LocationStreet> streets;

  LocationNeighborhood({required this.name, required this.streets});

  factory LocationNeighborhood.fromJson(Map<String, dynamic> json) {
    var streetList = json['streets'] as List;
    return LocationNeighborhood(
      name: json['name'] as String,
      streets: streetList.map((s) => LocationStreet.fromJson(s)).toList(),
    );
  }
}

class LocationRegion {
  final String region;
  final List<LocationNeighborhood> neighborhoods;

  LocationRegion({required this.region, required this.neighborhoods});

  factory LocationRegion.fromJson(Map<String, dynamic> json) {
    var neighList = json['neighborhoods'] as List;
    return LocationRegion(
      region: json['region'] as String,
      neighborhoods: neighList.map((n) => LocationNeighborhood.fromJson(n)).toList(),
    );
  }
}

class FoodItem {
  final String id;
  String name;
  String category;
  String description;
  double price;
  double rating;
  String imageUrl;
  List<String> ingredients;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.ingredients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      ingredients: List<String>.from(json['ingredients']),
    );
  }
}

class OrderItem {
  final FoodItem foodItem;
  int quantity;

  OrderItem({required this.foodItem, this.quantity = 1});

  double get totalPrice => foodItem.price * quantity;
}

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final String address;
  final String deliveryMethod; // "moto" or "voiture"
  final DateTime createdAt;
  String status; // "confirmée", "en_preparation", "en_chemin", "livree"
  MapCoordinates driverLocation;
  MapCoordinates restaurantLocation;
  MapCoordinates destinationLocation;

  OrderModel({
    required this.id,
    required this.items,
    required this.address,
    required this.deliveryMethod,
    required this.createdAt,
    required this.status,
    required this.driverLocation,
    required this.restaurantLocation,
    required this.destinationLocation,
  });

  double get totalAmount {
    double foodTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    double deliveryFee = deliveryMethod == "moto" ? 800.0 : 1500.0;
    return foodTotal + deliveryFee;
  }
}

class MapCoordinates {
  final double lat;
  final double lng;

  MapCoordinates({required this.lat, required this.lng});

  factory MapCoordinates.fromJson(Map<String, dynamic> json) {
    return MapCoordinates(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
