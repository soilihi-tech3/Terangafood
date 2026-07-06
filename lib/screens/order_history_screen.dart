import 'package:flutter/material.dart';
import '../services/order_history_service.dart';
import '../services/api_service.dart';
import '../models/food_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final Function(FoodItem, int) onUpdateCart;

  const OrderHistoryScreen({
    super.key,
    required this.cart,
    required this.onUpdateCart,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final OrderHistoryService _historyService = OrderHistoryService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Mes Commandes 📦",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE8612C),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE8612C),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Toutes"),
            Tab(text: "En cours ⏳"),
            Tab(text: "Livrées ✓"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(_historyService.all, isDark),
          _buildOrderList(_historyService.inProgress, isDark),
          _buildOrderList(_historyService.delivered, isDark),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<HistoryOrder> orders, bool isDark) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8612C).withOpacity(0.15),
                    const Color(0xFFE8612C).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: Color(0xFFE8612C),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "Aucune commande ici",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Vos commandes apparaîtront ici.",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Summary stats
    final totalSpent = orders
        .where((o) => o.status == "livree")
        .fold<double>(0, (sum, o) => sum + o.total);

    return Column(
      children: [
        // Stats header
        if (orders.any((o) => o.status == "livree"))
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8612C), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  "${orders.where((o) => o.status == 'livree').length}",
                  "Commandes",
                  Icons.check_circle_outline,
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStat(
                  "${totalSpent.toStringAsFixed(0)} F",
                  "Total dépensé",
                  Icons.payments_outlined,
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStat(
                  "${orders.where((o) => o.rating != null).length}",
                  "Évalués",
                  Icons.star_outline,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index], isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(HistoryOrder order, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final isDelivered = order.status == "livree";
    final isInProgress = order.status == "en_cours";

    Color statusColor;
    Color statusBg;
    String statusText;

    if (isDelivered) {
      statusColor = Colors.green.shade700;
      statusBg = const Color(0xFFE8F5E9);
      statusText = "✓ Livrée";
    } else if (isInProgress) {
      statusColor = Colors.amber.shade800;
      statusBg = const Color(0xFFFFF8E1);
      statusText = "⏳ En cours";
    } else {
      statusColor = Colors.red.shade700;
      statusBg = const Color(0xFFFFEBEE);
      statusText = "✗ Annulée";
    }

    return GestureDetector(
      onTap: () => _showOrderDetailsBottomSheet(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8612C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFE8612C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Commande ${order.id}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.date,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  height: 1),
              const SizedBox(height: 14),

              // Items summary
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fastfood_rounded,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total + Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          color: Color(0xFFE8612C), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${order.total.toStringAsFixed(0)} FCFA",
                        style: const TextStyle(
                          color: Color(0xFFE8612C),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (order.rating != null)
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < order.rating!.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                ],
              ),

              // Review text if exists
              if (order.review != null && order.review!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.review!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(BuildContext context, HistoryOrder order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localOrder = ApiService.localOrders[order.id];

    // Parse items
    final parsed = <Map<String, dynamic>>[];
    final parts = order.itemsSummary.split(', ');
    for (final part in parts) {
      final subParts = part.split(' × ');
      if (subParts.length == 2) {
        final name = subParts[0];
        final qty = int.tryParse(subParts[1]) ?? 1;
        FoodItem? found;
        for (final item in ApiService.fallbackMenu) {
          if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
            found = item;
            break;
          }
        }
        parsed.add({
          'name': name,
          'quantity': qty,
          'item': found,
        });
      }
    }

    final dateTimeStr = localOrder != null
        ? "${localOrder.createdAt.day}/${localOrder.createdAt.month}/${localOrder.createdAt.year} à ${localOrder.createdAt.hour.toString().padLeft(2, '0')}:${localOrder.createdAt.minute.toString().padLeft(2, '0')}"
        : order.date;

    final payMethodStr = order.paymentMethod == "wave"
        ? "Wave 🟦"
        : (order.paymentMethod == "omoney" ? "Orange Money 🟧" : "Espèces (Cash) 💵");

    final methodStr = order.deliveryMethod == "moto"
        ? "Livreur à Moto 🛵"
        : (order.deliveryMethod == "voiture" ? "Livreur en Voiture 🚗" : "Retrait au Restaurant 🏪");

    final deliveryFee = order.deliveryMethod == "moto" ? 800.0 : (order.deliveryMethod == "voiture" ? 1500.0 : 0.0);

    final subtotal = order.total - deliveryFee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool downloading = false;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (scrollCtx, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Détails Commande",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: order.status == "livree" ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status == "livree" ? "✓ Livrée" : "⏳ En cours",
                              style: TextStyle(
                                color: order.status == "livree" ? Colors.green.shade700 : Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${order.id} · Le $dateTimeStr",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Articles Commandés",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...parsed.map((p) {
                        final item = p['item'] as FoodItem?;
                        final name = p['name'] as String;
                        final qty = p['quantity'] as int;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item != null
                                    ? Image.network(
                                        item.imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 50,
                                          height: 50,
                                          color: const Color(0xFFFFF0E6),
                                          child: const Icon(Icons.fastfood_rounded, color: Color(0xFFE8612C)),
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: const Color(0xFFFFF0E6),
                                        child: const Icon(Icons.fastfood_rounded, color: Color(0xFFE8612C)),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Quantité : $qty",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item != null)
                                Text(
                                  "${(item.price * qty).toStringAsFixed(0)} F",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFFE8612C),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text(
                        "Détails de Livraison",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delivery_dining_rounded, color: Color(0xFFE8612C), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Livreur",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      const Text(
                                        "Abdoulaye Diallo",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.payments_rounded, color: Color(0xFFE8612C), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Mode de paiement",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        payMethodStr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(order.deliveryMethod == "retrait" ? Icons.storefront_rounded : (order.deliveryMethod == "voiture" ? Icons.directions_car_rounded : Icons.motorcycle_rounded), color: const Color(0xFFE8612C), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Mode de livraison",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        methodStr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.storefront_rounded, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Point de départ (Restaurant)",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        order.departure,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Destination (Client)",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        order.destination,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Résumé Financier",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Sous-total", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                Text("${subtotal.toStringAsFixed(0)} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Frais de livraison", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                Text(deliveryFee == 0 ? "Gratuit" : "${deliveryFee.toStringAsFixed(0)} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total payé", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  "${order.total.toStringAsFixed(0)} F",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE8612C)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: downloading
                                  ? null
                                  : () async {
                                      setSheetState(() => downloading = true);
                                      await Future.delayed(const Duration(milliseconds: 1500));
                                      if (ctx.mounted) {
                                        setSheetState(() => downloading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("✓ Reçu de la commande téléchargé ! (PDF)"),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                              icon: downloading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download_rounded, size: 18),
                              label: const Text("Télécharger Reçu", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8612C).withOpacity(0.12),
                                foregroundColor: const Color(0xFFE8612C),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                for (final p in parsed) {
                                  final item = p['item'] as FoodItem?;
                                  final qty = p['quantity'] as int;
                                  if (item != null) {
                                    widget.onUpdateCart(item, qty);
                                  }
                                }
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✓ Commande ajoutée à votre panier !"),
                                    backgroundColor: Color(0xFFE8612C),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text("Recommander", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8612C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
