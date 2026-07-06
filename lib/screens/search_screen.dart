import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final Function(FoodItem, int) onUpdateCart;

  const SearchScreen({
    super.key,
    required this.cart,
    required this.onUpdateCart,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  List<FoodItem> _allItems = [];
  List<FoodItem> _filteredItems = [];
  String _query = "";
  bool _isLoading = true;

  // Filters
  String _selectedCategory = "Tous";
  double _maxPrice = 6000.0;
  double _minRating = 4.0;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final menu = await _apiService.getMenu();
      setState(() {
        _allItems = menu;
        _filteredItems = menu;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesQuery = item.name.toLowerCase().contains(_query.toLowerCase()) ||
            item.description.toLowerCase().contains(_query.toLowerCase());
        final matchesCategory = _selectedCategory == "Tous" || item.category == _selectedCategory;
        final matchesPrice = item.price <= _maxPrice;
        final matchesRating = item.rating >= _minRating;

        return matchesQuery && matchesCategory && matchesPrice && matchesRating;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text("Recherche & Filtres", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFE8612C)),
            onPressed: () => _showFilterSheet(context),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8612C)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        _query = val;
                        _applyFilters();
                      },
                      decoration: const InputDecoration(
                        hintText: "Plat, ingrédient ou cuisine...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Category Pills for quick filtering
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ["Tous", "Plats Sénégalais", "Burgers", "Pizza", "Desserts"].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            _applyFilters();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFF0E6) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE8612C) : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFE8612C) : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Results list
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? const Center(child: Text("Aucun plat ne correspond à vos critères."))
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade100),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 2),
                                          Text(item.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          Text("${item.price.toInt()} FCFA", style: const TextStyle(color: Color(0xFFE8612C), fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailsScreen(
                                          item: item,
                                          cartCount: widget.cart[item] ?? 0,
                                          onUpdateCart: widget.onUpdateCart,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrer la recherche", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Price Filter
                  Text("Prix maximum : ${_maxPrice.toInt()} FCFA", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxPrice,
                    min: 1000,
                    max: 10000,
                    divisions: 18,
                    activeColor: const Color(0xFFE8612C),
                    inactiveColor: Colors.orange.shade100,
                    onChanged: (val) {
                      setModalState(() {
                        _maxPrice = val;
                      });
                      setState(() {
                        _maxPrice = val;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rating Filter
                  Text("Note minimum : $_minRating ★", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 3.0,
                    max: 5.0,
                    divisions: 4,
                    activeColor: const Color(0xFFE8612C),
                    inactiveColor: Colors.orange.shade100,
                    onChanged: (val) {
                      setModalState(() {
                        _minRating = val;
                      });
                      setState(() {
                        _minRating = val;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8612C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Appliquer les filtres", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
