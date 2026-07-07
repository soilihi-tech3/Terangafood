import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import '../services/pdf_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final HistoryOrder order;
  final Function(FoodItem, int) onUpdateCart;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.onUpdateCart,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _downloading = false;
  late final List<Map<String, dynamic>> _parsedItems;
  late final double _deliveryFee;
  late final double _subtotal;
  late final String _dateTimeStr;
  late final String _payMethodStr;
  late final String _methodStr;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    final localOrder = ApiService.localOrders[order.id];

    // Parse items
    _parsedItems = <Map<String, dynamic>>[];
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
        _parsedItems.add({
          'name': name,
          'quantity': qty,
          'item': found,
        });
      }
    }

    _dateTimeStr = localOrder != null
        ? "${localOrder.createdAt.day}/${localOrder.createdAt.month}/${localOrder.createdAt.year} à ${localOrder.createdAt.hour.toString().padLeft(2, '0')}:${localOrder.createdAt.minute.toString().padLeft(2, '0')}"
        : order.date;

    _payMethodStr = order.paymentMethod == "wave"
        ? "Wave 🟦"
        : (order.paymentMethod == "omoney" ? "Orange Money 🟧" : "Espèces (Cash) 💵");

    _methodStr = order.deliveryMethod == "moto"
        ? "Livreur à Moto 🛵"
        : (order.deliveryMethod == "voiture" ? "Livreur en Voiture 🚗" : "Retrait au Restaurant 🏪");

    _deliveryFee = order.deliveryMethod == "moto" ? 800.0 : (order.deliveryMethod == "voiture" ? 1500.0 : 0.0);
    _subtotal = order.total - _deliveryFee;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;

    Color statusColor;
    Color statusBg;
    if (order.status == "livree") {
      statusColor = Colors.green.shade700;
      statusBg = const Color(0xFFE8F5E9);
    } else if (order.status == "en_cours" || order.status == "confirmée" || order.status == "en_preparation" || order.status == "en_chemin") {
      statusColor = Colors.amber.shade800;
      statusBg = const Color(0xFFFFF8E1);
    } else {
      statusColor = Colors.red.shade700;
      statusBg = const Color(0xFFFFEBEE);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Détails Commande",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order general details header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Commande ${order.id}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Le $_dateTimeStr",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status == "livree" ? "✓ Livrée" : (order.status == "annulee" ? "✗ Annulée" : "⏳ En cours"),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ordered Articles List
              Text(
                "Articles Commandés",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ..._parsedItems.map((p) {
                final item = p['item'] as FoodItem?;
                final name = p['name'] as String;
                final qty = p['quantity'] as int;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
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

              // Delivery details info
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
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
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
                    const SizedBox(height: 14),
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
                                _payMethodStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                                _methodStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
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

              // Financial summary info
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
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Sous-total", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        Text("${_subtotal.toStringAsFixed(0)} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Frais de livraison", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        Text(_deliveryFee == 0 ? "Gratuit" : "${_deliveryFee.toStringAsFixed(0)} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
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
              const SizedBox(height: 32),

              // Recommander & PDF download actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _downloading
                          ? null
                          : () async {
                              setState(() => _downloading = true);
                              try {
                                await PdfService.generateAndPrintReceipt(order, _parsedItems);
                              } catch (_) {}
                              if (mounted) {
                                setState(() => _downloading = false);
                              }
                            },
                      icon: _downloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text("Générer Reçu", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        for (final p in _parsedItems) {
                          final item = p['item'] as FoodItem?;
                          final qty = p['quantity'] as int;
                          if (item != null) {
                            widget.onUpdateCart(item, qty);
                          }
                        }
                        Navigator.pop(context);
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
        ),
      ),
    );
  }
}
