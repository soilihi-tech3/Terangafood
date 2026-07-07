import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import 'details_screen.dart';
import 'cart_screen.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import 'chatbot_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final Function(FoodItem, int) onUpdateCart;
  final Function(int, {String searchQuery}) onSwitchTab;
  final String selectedStreet;
  final double selectedLat;
  final double selectedLng;
  final Function(String, double, double) onStreetChanged;

  const HomeScreen({
    super.key,
    required this.cart,
    required this.onUpdateCart,
    required this.onSwitchTab,
    required this.selectedStreet,
    required this.selectedLat,
    required this.selectedLng,
    required this.onStreetChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FavoritesService _favService = FavoritesService();
  final AuthService _authService = AuthService();

  // Promo carousel
  final PageController _promoPageCtrl = PageController();
  int _currentPromoPage = 0;
  Timer? _promoTimer;

  List<FoodItem> _menuItems = [];
  String _selectedCategory = "Tous";



  // 3 promo card definitions
  static const _promos = [
    {
      "tag": "🎉 Offre du Jour",
      "title": "50% de réduction\nsur votre 1ère\ncommande",
      "btn": "Commander",
      "color1": Color(0xFFE8612C),
      "color2": Color(0xFFFF9A5C),
      "image":
          "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&auto=format&fit=crop",
    },
    {
      "tag": "🚀 Livraison Express",
      "title": "Livraison en\n30 min\ngarantie",
      "btn": "Voir le menu",
      "color1": Color(0xFF4A00E0),
      "color2": Color(0xFF8E2DE2),
      "image":
          "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&auto=format&fit=crop",
    },
    {
      "tag": "⭐ Best-Sellers",
      "title": "Nos plats les\nmieux notés\nde Dakar",
      "btn": "Explorer",
      "color1": Color(0xFF11998E),
      "color2": Color(0xFF38EF7D),
      "image":
          "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&auto=format&fit=crop",
    },
  ];

  static const _secondaryImages = {
    "Plats Sénégalais":
        "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500&auto=format&fit=crop",
    "Burgers":
        "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=500&auto=format&fit=crop",
    "Pizza":
        "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500&auto=format&fit=crop",
    "Boissons":
        "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=500&auto=format&fit=crop",
    "Desserts":
        "https://images.unsplash.com/photo-1551024506-0bccd828d307?w=500&auto=format&fit=crop",
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPromoAutoScroll();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoPageCtrl.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_promoPageCtrl.hasClients) {
        final next = (_currentPromoPage + 1) % _promos.length;
        _promoPageCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    try {
      await _apiService.getLocations();
      final menu = await _apiService.getMenu();
      if (mounted) {
        setState(() {
          _menuItems = menu;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: widget.cart,
          selectedStreet: widget.selectedStreet,
          selectedLat: widget.selectedLat,
          selectedLng: widget.selectedLng,
          onUpdateCart: widget.onUpdateCart,
          onClearCart: () => setState(() => widget.cart.clear()),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamically reload data to pick up custom items added in the profile admin panel
    _loadData();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8612C)),
        ),
      );
    }

    final filteredItems = _selectedCategory == "Tous"
        ? _menuItems
        : _menuItems.where((item) => item.category == _selectedCategory).toList();
        
    // Filter popular items by current category (or all if Tous) and limit to exactly 4 items max
    final categoryPopular = _selectedCategory == "Tous"
        ? _menuItems.where((i) => i.rating >= 4.7).toList()
        : _menuItems.where((i) => i.category == _selectedCategory && i.rating >= 4.5).toList();
    final popularItems = categoryPopular.take(4).toList();
    
    final totalCartItems =
        widget.cart.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header + Search ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark, totalCartItems),
                    const SizedBox(height: 16),
                    _buildSearchBar(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Promo Carousel (full width) ─────────────────
            SliverToBoxAdapter(
              child: _buildPromoCarousel(isDark),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // ── Categories title ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Catégories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Category pills ──────────────────────────────
            SliverToBoxAdapter(
                child: _buildCategoryPills(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // ── Popular today ───────────────────────────────
            if (popularItems.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.whatshot_rounded,
                              color: Color(0xFFE8612C), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "Populaires du Jour",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onSwitchTab(1); // Switch to Explore tab
                        },
                        child: const Text(
                          "Voir tout",
                          style: TextStyle(
                            color: Color(0xFFE8612C),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                  child: _buildPopularSection(
                      popularItems, isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],

            // ── Menu title ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  filteredItems.isEmpty
                      ? "Aucun résultat"
                      : "Tous nos Plats (${filteredItems.length})",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Menu grid ───────────────────────────────────
            if (filteredItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 40, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          "Aucun plat trouvé",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildFoodCard(filteredItems[index], isDark),
                    childCount: filteredItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatbot_fab',
        onPressed: _showChatbotDialog,
        backgroundColor: const Color(0xFFE8612C),
        mini: true,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  void _showChatbotDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, int totalCartItems) {
    return Row(
      children: [
        // Profile picture avatar on the left
        GestureDetector(
          onTap: () {
            widget.onSwitchTab(3); // Switch to Profile tab
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8612C),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(_authService.avatarUrl),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFE8612C), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Livrer à",
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final searchCtrl = TextEditingController();
                      List<Map<String, dynamic>> suggestions = [];
                      bool searching = false;

                      return StatefulBuilder(
                        builder: (dialogCtx, setDialogState) {
                          return SimpleDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            title: Row(
                              children: [
                                const Icon(Icons.location_searching_rounded, color: Color(0xFFE8612C)),
                                const SizedBox(width: 8),
                                Text(
                                  "Adresse de livraison",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.all(20),
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    widget.onStreetChanged(
                                      "Avenue Cheikh Anta Diop, Dakar",
                                      14.6890,
                                      -17.4690,
                                    );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("📍 Position détectée : Avenue Cheikh Anta Diop !"),
                                        backgroundColor: Color(0xFFE8612C),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.my_location_rounded, size: 16),
                                  label: const Text("Détecter ma position", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8612C).withOpacity(0.12),
                                    foregroundColor: const Color(0xFFE8612C),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: searchCtrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Rechercher une rue...",
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: searching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8612C)),
                                          ),
                                        )
                                      : null,
                                ),
                                onChanged: (val) async {
                                  if (val.trim().length > 2) {
                                    setDialogState(() => searching = true);
                                    final res = await _apiService.searchAddress(val.trim());
                                    if (!dialogCtx.mounted) return;
                                    setDialogState(() {
                                      suggestions = res;
                                      searching = false;
                                    });
                                  } else {
                                     if (!dialogCtx.mounted) return;
                                     setDialogState(() {
                                       suggestions = [];
                                       searching = false;
                                     });
                                   }
                                },
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220),
                                child: Container(
                                  width: 280,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: suggestions.length,
                                    itemBuilder: (c, idx) {
                                      final item = suggestions[idx];
                                      final displayName = item['display_name'] as String;
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          displayName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onTap: () {
                                          widget.onStreetChanged(
                                            displayName,
                                            item['lat'] as double,
                                            item['lon'] as double,
                                          );
                                          Navigator.pop(ctx);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.selectedStreet.contains(",") ? widget.selectedStreet.split(",").first : widget.selectedStreet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Color(0xFFE8612C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildTopIcon(
          onTap: _navigateToCart,
          isDark: isDark,
          child: totalCartItems > 0
              ? Badge(
                  label: Text(
                    "$totalCartItems",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFFE8612C),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Color(0xFFE8612C)),
                )
              : Icon(Icons.shopping_bag_outlined,
                  color: isDark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<List<NotificationItem>>(
          valueListenable: NotificationService().notificationsNotifier,
          builder: (context, notifs, _) {
            final unread = notifs.where((n) => !n.isRead).length;
            return _buildTopIcon(
              onTap: () => _showNotificationsBottomSheet(context, notifs),
              isDark: isDark,
              child: unread > 0
                  ? Badge(
                      label: Text(
                        "$unread",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFE8612C),
                      child: const Icon(Icons.notifications_none_rounded,
                          color: Color(0xFFE8612C)),
                    )
                  : Icon(Icons.notifications_none_rounded,
                      color: isDark ? Colors.white70 : Colors.black87),
            );
          },
        ),
      ],
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, List<NotificationItem> notifs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(onUpdateCart: widget.onUpdateCart),
      ),
    );
  }

  Widget _buildTopIcon(
      {required Widget child,
      bool isDark = false,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    final searchController = TextEditingController();
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onSwitchTab(1, searchQuery: value.trim());
          }
        },
        decoration: InputDecoration(
          hintText: "Rechercher un plat ou un ingrédient...",
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFE8612C), size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFE8612C)),
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                widget.onSwitchTab(1, searchQuery: searchController.text.trim());
              }
            },
          ),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PROMO CAROUSEL — 3 beautiful full-width cards
  // ─────────────────────────────────────────────────────────────
  Widget _buildPromoCarousel(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _promoPageCtrl,
            itemCount: _promos.length,
            onPageChanged: (i) => setState(() => _currentPromoPage = i),
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return _buildPromoCard(promo, isDark);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promos.length, (i) {
            return GestureDetector(
              onTap: () => _promoPageCtrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPromoPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPromoPage == i
                      ? (_promos[i]["color1"] as Color)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo, bool isDark) {
    final c1 = promo["color1"] as Color;
    final c2 = promo["color2"] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: c1.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 60,
              top: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Food image (right side, fills the card)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 160,
              child: Stack(
                children: [
                  Image.network(
                    promo["image"] as String,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                  // Gradient overlay to blend into card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c1, Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      promo["tag"] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    promo["title"] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  // CTA button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            promo["btn"] as String,
                            style: TextStyle(
                              color: c1,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: c1, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORY PILLS
  // ─────────────────────────────────────────────────────────────
  Widget _buildCategoryPills(bool isDark) {
    final dynamicCategories = CategoryService().categories;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dynamicCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = dynamicCategories[index];
          final name = cat["name"] as String;
          final icon = cat["icon"] as IconData;
          final isSelected = _selectedCategory == name;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8612C)
                    : (isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE8612C)
                              .withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                children: [
                  Icon(icon,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  Text(
                    name,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // POPULAR SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildPopularSection(List<FoodItem> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildPopularCard(items[index], isDark),
      ),
    );
  }

  Widget _buildPopularCard(FoodItem item, bool isDark) {
    final isFav = _favService.isFavorite(item.id);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: () => _goToDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22)),
                  child: Image.network(
                    item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xFFFFF0E6),
                      child: const Icon(Icons.fastfood_rounded,
                          color: Color(0xFFE8612C), size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await _favService.toggle(item);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isFav
                            ? const Color(0xFFE8612C)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav
                            ? Colors.white
                            : const Color(0xFFE8612C),
                        size: 14,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
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
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.price.toStringAsFixed(0)} FCFA",
                    style: const TextStyle(
                      color: Color(0xFFE8612C),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FOOD CARD (Grid)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFoodCard(FoodItem item, bool isDark) {
    final isFav = _favService.isFavorite(item.id);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cartQty = widget.cart[item] ?? 0;

    return GestureDetector(
      onTap: () => _goToDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(isDark ? 0.35 : 0.07),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _favService.toggle(item);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isFav
                              ? const Color(0xFFE8612C)
                              : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.12),
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
                  if (cartQty > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8612C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "×$cartQty",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                        color:
                            isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                            final cur =
                                widget.cart[item] ?? 0;
                            widget.onUpdateCart(item, cur + 1);
                            setState(() {});
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content:
                                    Text("${item.name} ajouté !"),
                                backgroundColor:
                                    const Color(0xFFE8612C),
                                duration:
                                    const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ));
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8612C),
                              borderRadius:
                                  BorderRadius.circular(10),
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

  void _goToDetails(FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          item: item,
          cartCount: widget.cart[item] ?? 0,
          onUpdateCart: widget.onUpdateCart,
          secondaryImageUrl: _secondaryImages[item.category],
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
