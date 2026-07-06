import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/favorites_service.dart';

class DetailsScreen extends StatefulWidget {
  final FoodItem item;
  final int cartCount;
  final Function(FoodItem, int) onUpdateCart;
  final String? secondaryImageUrl;

  const DetailsScreen({
    super.key,
    required this.item,
    required this.cartCount,
    required this.onUpdateCart,
    this.secondaryImageUrl,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final FavoritesService _favService = FavoritesService();
  late int _quantity;
  int _activeImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.cartCount > 0 ? widget.cartCount : 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final imgs = [widget.item.imageUrl];
    if (widget.secondaryImageUrl != null &&
        widget.secondaryImageUrl != widget.item.imageUrl) {
      imgs.add(widget.secondaryImageUrl!);
    }
    return imgs;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = _favService.isFavorite(widget.item.id);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Stack(
        children: [
          // ── Image Gallery ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.44,
            child: Stack(
              children: [
                // PageView of images
                PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  onPageChanged: (i) =>
                      setState(() => _activeImageIndex = i),
                  itemBuilder: (_, i) {
                    return Image.network(
                      _images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFF0E6),
                        child: const Icon(Icons.fastfood_rounded,
                            size: 80, color: Color(0xFFE8612C)),
                      ),
                    );
                  },
                ),
                // Page indicator dots
                if (_images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_images.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _activeImageIndex == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _activeImageIndex == i
                                ? const Color(0xFFE8612C)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          // ── Top Controls ───────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back
                _buildIconButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.black87, size: 18),
                ),
                // Favourite
                _buildIconButton(
                  onTap: () => setState(() => _favService.toggle(widget.item)),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav
                        ? const Color(0xFFE8612C)
                        : Colors.black87,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Sheet ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.62,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title + Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8612C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFE8612C), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFFE8612C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Star display
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < widget.item.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 17,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          "${(widget.item.rating * 20).toInt()} avis",
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: Colors.grey.shade400, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          "Dakar Central Kitchen",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded,
                            color: Colors.grey.shade400, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          "20-35 min",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Metrics Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade100,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetric("198", "kcal", Icons.local_fire_department_rounded, Colors.orange),
                          _buildDivider(isDark),
                          _buildMetric("25g", "Protéines", Icons.fitness_center_rounded, Colors.blue),
                          _buildDivider(isDark),
                          _buildMetric("14g", "Lipides", Icons.water_drop_rounded, Colors.purple),
                          _buildDivider(isDark),
                          _buildMetric("24g", "Glucides", Icons.grain_rounded, Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ingredients
                    Text(
                      "Ingrédients",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.item.ingredients
                          .map((ing) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ing,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 28),

                    // ── Action Row ──────────────────────────────
                    Row(
                      children: [
                        // Quantity selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildQtyBtn(
                                icon: Icons.remove_rounded,
                                onTap: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                isDark: isDark,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  "$_quantity",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              _buildQtyBtn(
                                icon: Icons.add_rounded,
                                onTap: () => setState(() => _quantity++),
                                isDark: isDark,
                                active: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Add to cart button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onUpdateCart(widget.item, _quantity);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "✓ ${widget.item.name} ajouté au panier !"),
                                  backgroundColor: const Color(0xFFE8612C),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8612C),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                              shadowColor: const Color(0xFFE8612C)
                                  .withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_rounded,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Ajouter · ${(widget.item.price * _quantity).toStringAsFixed(0)} F",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 8)
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildMetric(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? Colors.white12 : Colors.grey.shade200,
    );
  }

  Widget _buildQtyBtn(
      {required IconData icon,
      VoidCallback? onTap,
      required bool isDark,
      bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE8612C)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? Colors.white
              : (onTap != null
                  ? (isDark ? Colors.white70 : Colors.black87)
                  : Colors.grey.shade400),
        ),
      ),
    );
  }
}
