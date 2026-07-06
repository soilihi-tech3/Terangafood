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

  List<LocationRegion> _regions = [];
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
      final locs = await _apiService.getLocations();
      final menu = await _apiService.getMenu();
      if (mounted) {
        setState(() {
          _regions = locs;
          _menuItems = menu;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _getAllStreets() {
    final streets = <String>[];
    for (final reg in _regions) {
      for (final neigh in reg.neighborhoods) {
        for (final street in neigh.streets) {
          streets.add(street.name);
        }
      }
    }
    return streets.isEmpty ? ["Route de la Pointe des Almadies"] : streets;
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
        onPressed: _showChatbotDialog,
        backgroundColor: const Color(0xFFE8612C),
        mini: true,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  void _showChatbotDialog() {
    final List<Map<String, dynamic>> messages = [
      {
        'isBot': true,
        'text': "Salam ! Je suis TerangaBot 🤖, votre assistant virtuel. Comment puis-je vous aider aujourd'hui ?",
      }
    ];
    final inputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              curve: Curves.decelerate,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE8612C).withOpacity(0.12),
                            radius: 20,
                            child: const Icon(Icons.smart_toy_rounded, color: Color(0xFFE8612C), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TerangaBot 🤖",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "En ligne · Réponses instantanées",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Suggestions at the top
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildChatOption("📦 Où est ma commande ?", () {
                              setModalState(() {
                                messages.add({'isBot': false, 'text': "Où est ma commande ?"});
                                messages.add({
                                  'isBot': true,
                                  'text': "Vous pouvez suivre vos commandes en cours en temps réel dans l'onglet 'Commandes' 📦. Si une livraison est en route, vous verrez même la position de votre livreur sur la carte !",
                                });
                              });
                            }, isDark),
                            const SizedBox(width: 8),
                            _buildChatOption("💵 Modes de paiement", () {
                              setModalState(() {
                                messages.add({'isBot': false, 'text': "Modes de paiement"});
                                messages.add({
                                  'isBot': true,
                                  'text': "Nous acceptons Wave 🟦, Orange Money 🟧, et le paiement en Espèces (Cash) 💵 à la livraison.",
                                });
                              });
                            }, isDark),
                            const SizedBox(width: 8),
                            _buildChatOption("🛵 Comment marche la livraison ?", () {
                              setModalState(() {
                                messages.add({'isBot': false, 'text': "Comment marche la livraison ?"});
                                messages.add({
                                  'isBot': true,
                                  'text': "Nous livrons par Moto 🛵 (800 F) ou par Voiture 🚗 (1500 F) partout à Dakar. Vous pouvez aussi choisir le retrait gratuit au restaurant 🏪.",
                                });
                              });
                            }, isDark),
                            const SizedBox(width: 8),
                            _buildChatOption("📞 Contacter le support", () {
                              setModalState(() {
                                messages.add({'isBot': false, 'text': "Contacter le support"});
                                messages.add({
                                  'isBot': true,
                                  'text': "Notre service client est disponible 24/7. Vous pouvez nous appeler directement au +221 77 261 38 81 ou nous écrire à support@teranga.sn 📞.",
                                });
                              });
                            }, isDark),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isBot = msg['isBot'] as bool;
                          return Align(
                            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isBot
                                    ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100)
                                    : const Color(0xFFE8612C),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                                  bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Text(
                                msg['text'],
                                style: TextStyle(
                                  color: isBot
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Message text input at the bottom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: inputCtrl,
                                decoration: InputDecoration(
                                  hintText: "Écrivez votre message...",
                                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE8612C),
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                onPressed: () {
                                  final text = inputCtrl.text.trim();
                                  if (text.isNotEmpty) {
                                    setModalState(() {
                                      messages.add({'isBot': false, 'text': text});
                                      inputCtrl.clear();

                                      // Respond based on message text
                                      final query = text.toLowerCase();
                                      String response = "Désolé, je n'ai pas bien compris votre demande. N'hésitez pas à utiliser nos questions rapides en haut ou contactez le support client.";

                                      if (query.contains("commande") || query.contains("suiv") || query.contains("trouv")) {
                                        response = "Vous pouvez suivre vos commandes en cours en temps réel dans l'onglet 'Commandes' 📦. Si une livraison est en route, vous verrez même la position de votre livreur sur la carte !";
                                      } else if (query.contains("pay") || query.contains("argent") || query.contains("wave") || query.contains("orange") || query.contains("cash")) {
                                        response = "Nous acceptons Wave 🟦, Orange Money 🟧, et le paiement en Espèces (Cash) 💵 à la livraison.";
                                      } else if (query.contains("livr") || query.contains("moto") || query.contains("voiture") || query.contains("prix") || query.contains("tarif")) {
                                        response = "Nous livrons par Moto 🛵 (800 F) ou par Voiture 🚗 (1500 F) partout à Dakar. Vous pouvez aussi choisir le retrait gratuit au restaurant 🏪.";
                                      } else if (query.contains("support") || query.contains("aide") || query.contains("contact") || query.contains("téléphone") || query.contains("telephone") || query.contains("numero")) {
                                        response = "Notre service client est disponible 24/7. Vous pouvez nous appeler directement au +221 77 261 38 81 ou nous écrire à support@teranga.sn 📞.";
                                      }

                                      messages.add({'isBot': true, 'text': response});
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatOption(String label, VoidCallback onTap, bool isDark) {
    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE8612C)),
      ),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, int totalCartItems) {
    final streets = _getAllStreets();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    NotificationService().markAllAsRead();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final list = NotificationService().notifications;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Notifications 🔔",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (list.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            NotificationService().clearAll();
                            setSheetState(() {});
                          },
                          child: const Text(
                            "Tout effacer",
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              "Aucune notification pour le moment",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (c, idx) {
                          final n = list[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }
        );
      },
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
                    onTap: () =>
                        setState(() => _favService.toggle(item)),
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
                      onTap: () =>
                          setState(() => _favService.toggle(item)),
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
