import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import 'tracking_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final String selectedStreet;
  final double selectedLat;
  final double selectedLng;
  final Function(FoodItem, int) onUpdateCart;
  final VoidCallback onClearCart;

  const CartScreen({
    super.key,
    required this.cart,
    required this.selectedStreet,
    required this.selectedLat,
    required this.selectedLng,
    required this.onUpdateCart,
    required this.onClearCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  final OrderHistoryService _historyService = OrderHistoryService();
  String _deliveryMethod = "moto";
  String _paymentMethod = "cash";
  bool _isPlacingOrder = false;

  double get _foodTotal => widget.cart.entries
      .fold(0.0, (sum, e) => sum + (e.key.price * e.value));

  double get _deliveryFee {
    if (_deliveryMethod == "retrait") return 0.0;
    return _deliveryMethod == "moto" ? 800.0 : 1500.0;
  }

  double get _grandTotal => _foodTotal + _deliveryFee;

  Future<bool> _showMobilePaymentDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneCtrl = TextEditingController();
    bool paying = false;
    bool paid = false;
    String methodTitle = _paymentMethod == "wave" ? "Wave" : "Orange Money";
    Color methodColor = _paymentMethod == "wave" ? const Color(0xFF1E88E5) : const Color(0xFFEF6C00);

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    _paymentMethod == "wave" ? Icons.qr_code_scanner_rounded : Icons.phone_android_rounded,
                    color: methodColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Paiement $methodTitle",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!paying && !paid) ...[
                    Text(
                      "Veuillez saisir votre numéro de téléphone pour valider la transaction de ${_grandTotal.toStringAsFixed(0)} F via $methodTitle.",
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        hintText: "Ex: 77 123 45 67",
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ] else if (paying) ...[
                    const SizedBox(height: 10),
                    CircularProgressIndicator(color: methodColor),
                    const SizedBox(height: 16),
                    Text(
                      "Demande de paiement envoyée sur votre téléphone...\nVeuillez valider la transaction.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                    ),
                  ] else if (paid) ...[
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Paiement effectué avec succès ! ✓",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!paying && !paid) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: const Text("Annuler"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (phoneCtrl.text.trim().isNotEmpty) {
                        setDialogState(() => paying = true);
                        await Future.delayed(const Duration(seconds: 2));
                        if (!dialogCtx.mounted) return;
                        setDialogState(() {
                          paying = false;
                          paid = true;
                        });
                        await Future.delayed(const Duration(seconds: 1));
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx, true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: methodColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Payer d'abord"),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
    return res ?? false;
  }

  Future<void> _placeOrder() async {
    if (_paymentMethod == "cash") {
      await _executeOrderPlacement();
    } else {
      final success = await _showMobilePaymentDialog();
      if (success) {
        await _executeOrderPlacement();
      }
    }
  }

  Future<void> _executeOrderPlacement() async {
    setState(() => _isPlacingOrder = true);
    try {
      final items = widget.cart.entries
          .map((e) => OrderItem(foodItem: e.key, quantity: e.value))
          .toList();
      final address = _deliveryMethod == "retrait"
          ? "Retrait au Restaurant Central"
          : widget.selectedStreet;

      final order = await _apiService.createOrder(
        items,
        address,
        _deliveryMethod,
        lat: widget.selectedLat,
        lng: widget.selectedLng,
      );

      // Save to local order history
      _historyService.addOrder(
        id: order.id,
        cart: Map.from(widget.cart),
        total: _grandTotal,
        paymentMethod: _paymentMethod,
        deliveryMethod: _deliveryMethod,
        departure: "Restaurant Le Teranga, Plateau",
        destination: address,
      );

      widget.onClearCart();

      if (mounted) {
        // Show confirmation dialog
        await _showConfirmationDialog(order.id);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => TrackingScreen(orderId: order.id)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de la commande : $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _showConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8612C), Color(0xFFFF9A5C)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                "Commande confirmée ! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Votre commande $orderId a bien été enregistrée.\n\nVous pouvez suivre votre commande en temps réel. Notre livreur est en route ! 🛵",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8612C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Suivre ma commande →",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          "Mon Panier",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: widget.cart.isEmpty
          ? _buildEmptyCart(isDark)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart items
                        Text(
                          "Articles (${widget.cart.length})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.cart.entries.map(
                          (e) => _buildCartItem(e.key, e.value, isDark),
                        ),
                        const SizedBox(height: 20),

                        // Delivery method
                        Text(
                          "Mode de livraison",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDeliveryOptions(isDark),
                        const SizedBox(height: 24),

                        // Payment method
                        _buildPaymentOptions(isDark),
                        const SizedBox(height: 24),

                        // Price summary
                        _buildPriceSummary(isDark),
                      ],
                    ),
                  ),
                ),
                // Order button
                _buildOrderButton(isDark),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8612C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Color(0xFFE8612C),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Votre panier est vide",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez des plats pour passer commande",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(FoodItem item, int qty, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFFFF0E6),
                    child: const Icon(Icons.fastfood_rounded,
                        color: Color(0xFFE8612C)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "${item.price.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(
                            color: Color(0xFFE8612C),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            widget.onUpdateCart(item, 0);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quantity controls
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _smallBtn(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          widget.onUpdateCart(item, qty - 1);
                          setState(() {});
                        },
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "$qty",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      _smallBtn(
                        icon: Icons.add_rounded,
                        onTap: () {
                          widget.onUpdateCart(item, qty + 1);
                          setState(() {});
                        },
                        isDark: isDark,
                        active: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "= ${(item.price * qty).toStringAsFixed(0)} F",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _smallBtn(
      {required IconData icon,
      required VoidCallback onTap,
      required bool isDark,
      bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE8612C)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16,
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54)),
      ),
    );
  }

  Widget _buildDeliveryOptions(bool isDark) {
    return Column(
      children: [
        _deliveryOption(
          "moto",
          "Livraison Moto",
          "Rapide · 20-30 min · +800 FCFA",
          Icons.motorcycle_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _deliveryOption(
          "voiture",
          "Livraison Voiture",
          "Confort · 30-45 min · +1500 FCFA",
          Icons.directions_car_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _deliveryOption(
          "retrait",
          "Retrait au restaurant",
          "Gratuit · Prêt en 20 min",
          Icons.storefront_rounded,
          isDark,
        ),
      ],
    );
  }

  Widget _deliveryOption(
      String value, String title, String subtitle, IconData iconData, bool isDark) {
    final isSelected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8612C).withOpacity(0.1)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE8612C)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _deliveryMethod,
              onChanged: (v) => setState(() => _deliveryMethod = v!),
              activeColor: const Color(0xFFE8612C),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Icon(iconData, color: isSelected ? const Color(0xFFE8612C) : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
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

  Widget _buildPriceSummary(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceLine("Sous-total",
              "${_foodTotal.toStringAsFixed(0)} FCFA", isDark),
          const SizedBox(height: 10),
          _priceLine(
              "Frais de livraison",
              _deliveryFee == 0
                  ? "Gratuit"
                  : "${_deliveryFee.toStringAsFixed(0)} FCFA",
              isDark),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                "${_grandTotal.toStringAsFixed(0)} FCFA",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFFE8612C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceLine(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8612C),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Passer la commande · ${_grandTotal.toStringAsFixed(0)} F",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mode de paiement",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _paymentOption("cash", "Espèces", Icons.payments_rounded, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _paymentOption("wave", "Wave", Icons.qr_code_scanner_rounded, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _paymentOption("omoney", "Orange Money", Icons.phone_android_rounded, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _paymentOption(String value, String title, IconData icon, bool isDark) {
    final isSelected = _paymentMethod == value;
    final primaryColor = value == "wave"
        ? const Color(0xFF1E88E5)
        : (value == "omoney" ? const Color(0xFFEF6C00) : const Color(0xFFE8612C));

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.08)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
