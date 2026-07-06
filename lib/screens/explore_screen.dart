import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/category_service.dart';
import 'details_screen.dart';

class ExploreScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final Function(FoodItem, int) onUpdateCart;

  final String initialSearchQuery;
  final VoidCallback onSearchQueryConsumed;

  const ExploreScreen({
    super.key,
    required this.cart,
    required this.onUpdateCart,
    this.initialSearchQuery = "",
    required this.onSearchQueryConsumed,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _apiService = ApiService();
  final FavoritesService _favService = FavoritesService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<FoodItem> _allItems = [];
  bool _isLoading = true;
  String _selectedCategory = "Tous";
  String _sortBy = "Popularité";
  double _minRating = 0;
  RangeValues _priceRange = const RangeValues(0, 10000);



  static const _sortOptions = [
    "Popularité",
    "Prix croissant",
    "Prix décroissant",
    "Mieux notés",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery.isNotEmpty) {
      _searchCtrl.text = widget.initialSearchQuery;
      widget.onSearchQueryConsumed();
    }
    _loadMenu();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchQuery.isNotEmpty) {
      setState(() {
        _searchCtrl.text = widget.initialSearchQuery;
      });
      widget.onSearchQueryConsumed();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    try {
      final menu = await _apiService.getMenu();
      if (mounted) {
        setState(() {
          _allItems = menu;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FoodItem> get _filteredItems {
    List<FoodItem> items = _allItems.where((item) {
      final matchesCat =
          _selectedCategory == "Tous" || item.category == _selectedCategory;
      final q = _searchCtrl.text.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.ingredients.any((i) => i.toLowerCase().contains(q));
      final matchesRating = item.rating >= _minRating;
      final matchesPrice =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      return matchesCat && matchesSearch && matchesRating && matchesPrice;
    }).toList();

    switch (_sortBy) {
      case "Prix croissant":
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case "Prix décroissant":
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case "Mieux notés":
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        items.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return items;
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double tempMinRating = _minRating;
    RangeValues tempPriceRange = _priceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Filtres & Tri",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Sort by
                Text(
                  "Trier par",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _sortOptions.map((option) {
                    final isSelected = _sortBy == option;
                    return GestureDetector(
                      onTap: () => setLocal(() => _sortBy = option),
                      child: Chip(
                        label: Text(option),
                        backgroundColor: isSelected
                            ? const Color(0xFFE8612C)
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Min rating
                Text(
                  "Note minimum",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [0.0, 4.0, 4.5, 4.8].map((rating) {
                    final isSelected = tempMinRating == rating;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setLocal(() => tempMinRating = rating),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8612C)
                                : (isDark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (rating > 0)
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 14),
                              if (rating > 0) const SizedBox(width: 4),
                              Text(
                                rating == 0 ? "Tous" : "$rating+",
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Price range
                Text(
                  "Fourchette de prix : ${tempPriceRange.start.toInt()} – ${tempPriceRange.end.toInt()} FCFA",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                RangeSlider(
                  values: tempPriceRange,
                  min: 0,
                  max: 10000,
                  divisions: 20,
                  activeColor: const Color(0xFFE8612C),
                  inactiveColor: const Color(0xFFE8612C).withOpacity(0.2),
                  onChanged: (v) => setLocal(() => tempPriceRange = v),
                ),
                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minRating = tempMinRating;
                        _priceRange = tempPriceRange;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8612C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Appliquer les filtres",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamically reload menu list to reflect newly added custom items in Profile Screen dialogs
    _loadMenu();
    
    final results = _filteredItems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        title: Text(
          "Explorer 🔍",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                onPressed: _showFilterSheet,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8612C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Color(0xFFE8612C), size: 20),
                ),
                tooltip: "Filtres",
              ),
              if (_minRating > 0 || _priceRange != const RangeValues(0, 10000))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8612C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style:
                    TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText:
                      "Rechercher plat, ingrédient, catégorie...",
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFE8612C), size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400, size: 18),
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Category filter pills ───────────────────────────
          Builder(
            builder: (context) {
              final dynamicCategories = CategoryService().categoryNames;
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dynamicCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = dynamicCategories[i];
                    final isSelected = _selectedCategory == cat;
                    final count = cat == "Tous"
                        ? _allItems.length
                        : _allItems.where((item) => item.category == cat).length;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE8612C)
                              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE8612C).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        isDark ? 0.3 : 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : const Color(0xFFE8612C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$count",
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFE8612C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          ),
          const SizedBox(height: 12),

          // ── Results count + sort info ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${results.length} plat${results.length > 1 ? 's' : ''} trouvé${results.length > 1 ? 's' : ''}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded,
                          size: 16, color: const Color(0xFFE8612C)),
                      const SizedBox(width: 4),
                      Text(
                        _sortBy,
                        style: const TextStyle(
                          color: Color(0xFFE8612C),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Grid ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE8612C)))
                : results.isEmpty
                    ? _buildEmptyState(isDark)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: results.length,
                        itemBuilder: (_, i) =>
                            _buildExploreCard(results[i], isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Aucun plat trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Essayez d'autres mots-clés\nou modifiez vos filtres",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _selectedCategory = "Tous";
                _sortBy = "Popularité";
                _minRating = 0;
                _priceRange = const RangeValues(0, 10000);
              });
            },
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFFE8612C)),
            label: const Text("Réinitialiser les filtres",
                style: TextStyle(
                    color: Color(0xFFE8612C),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(FoodItem item, bool isDark) {
    final isFav = _favService.isFavorite(item.id);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cartQty = widget.cart[item] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsScreen(
              item: item,
              cartCount: cartQty,
              onUpdateCart: widget.onUpdateCart,
            ),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFF0E6),
                        child: const Icon(Icons.fastfood_rounded,
                            color: Color(0xFFE8612C), size: 48),
                      ),
                    ),
                  ),
                  // Fav button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _favService.toggle(item)),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isFav
                              ? const Color(0xFFE8612C)
                              : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4)
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? Colors.white
                              : const Color(0xFFE8612C),
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  // Rating
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category tag
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.category.split(" ").first,
                        style: const TextStyle(
                          color: Color(0xFFE8612C),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (cartQty > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8612C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "×$cartQty",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item.price.toStringAsFixed(0)} F",
                              style: const TextStyle(
                                color: Color(0xFFE8612C),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < item.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 11,
                                );
                              }),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            final cur = widget.cart[item] ?? 0;
                            widget.onUpdateCart(item, cur + 1);
                            setState(() {});
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content: Text("${item.name} ajouté !"),
                                backgroundColor: const Color(0xFFE8612C),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ));
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8612C),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE8612C)
                                      .withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
