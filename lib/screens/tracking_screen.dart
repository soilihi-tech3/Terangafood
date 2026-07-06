import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';
import '../services/order_history_service.dart';
import '../services/notification_service.dart';

class DriverInfo {
  final String name;
  final String phone;
  final String imageUrl;
  final double rating;
  final int deliveryCount;

  DriverInfo({
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.rating,
    required this.deliveryCount,
  });
}

class TrackingScreen extends StatefulWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final OrderHistoryService _historyService = OrderHistoryService();

  OrderModel? _order;
  Timer? _timer;
  bool _isLoading = true;
  String _errorMsg = "";
  bool _hasShownDeliveredDialog = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String? _lastStatus;
  late final DriverInfo _driver;

  DriverInfo _getDriverForOrder(String orderId) {
    final list = [
      DriverInfo(
        name: "Abdoulaye Diallo",
        phone: "772613881",
        imageUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop",
        rating: 4.9,
        deliveryCount: 124,
      ),
      DriverInfo(
        name: "Moussa Ndiaye",
        phone: "773412589",
        imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop",
        rating: 4.8,
        deliveryCount: 89,
      ),
      DriverInfo(
        name: "Fatou Diop",
        phone: "774895623",
        imageUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop",
        rating: 4.95,
        deliveryCount: 156,
      ),
      DriverInfo(
        name: "Amadou Sow",
        phone: "775123456",
        imageUrl: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop",
        rating: 4.75,
        deliveryCount: 62,
      ),
    ];
    final index = orderId.hashCode.abs() % list.length;
    return list[index];
  }

  @override
  void initState() {
    super.initState();
    _driver = _getDriverForOrder(widget.orderId);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchUpdates();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchUpdates());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerStatusNotification(String orderId, String status) {
    final notificationService = NotificationService();
    String title = "";
    String body = "";

    if (status == "confirmée") {
      title = "Commande Confirmée 📦";
      body = "Votre commande $orderId a été validée par le restaurant.";
    } else if (status == "en_preparation") {
      title = "Préparation en cours 👨‍🍳";
      body = "Le chef prépare vos délicieux plats pour la commande $orderId.";
    } else if (status == "en_chemin") {
      title = "Commande en route ! 🛵";
      body = "Votre livreur a récupéré votre commande $orderId et se dirige vers vous.";
    } else if (status == "livree") {
      title = "Votre commande est arrivée ! 🔔";
      body = "Le livreur est devant votre porte avec la commande $orderId.";
    } else if (status == "recupere") {
      title = "Commande Récupérée 🎉";
      body = "Merci d'avoir commandé chez TerangaFood. Bon appétit !";
    }

    if (title.isNotEmpty) {
      notificationService.addNotification(title: title, body: body);
    }
  }

  Future<void> _fetchUpdates() async {
    try {
      final updated = await _apiService.getOrder(widget.orderId);
      if (!mounted) return;

      if (_lastStatus != updated.status) {
        _lastStatus = updated.status;
        _triggerStatusNotification(updated.id, updated.status);
      }

      setState(() {
        _order = updated;
        _isLoading = false;
      });

      // Show delivered dialog once
      if (updated.status == "livree" && !_hasShownDeliveredDialog) {
        _hasShownDeliveredDialog = true;
        _timer?.cancel();
        // Update history
        _historyService.updateStatus(widget.orderId, "livree");
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _showDeliveredDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = "Erreur lors du suivi : $e";
          _isLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Delivered + Rating Dialog
  // ─────────────────────────────────────────────────────────────
  void _showDeliveredDialog() {
    double selectedRating = 0;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confetti-style icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8612C), Color(0xFFFF9A5C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8612C).withOpacity(0.35),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "🎉 Commande livrée !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Merci pour votre confiance en TerangaFood !\n\nVotre commande a bien été livrée. Nous espérons que vous avez savouré chaque bouchée 🍽️",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Stars rating
                  const Text(
                    "Évaluez votre expérience",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setLocalState(() => selectedRating = i + 1.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Optional review text
                  TextField(
                    controller: reviewCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          "Laissez un commentaire (optionnel)...",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedRating > 0) {
                          _historyService.addRating(
                            widget.orderId,
                            selectedRating,
                            reviewCtrl.text.trim().isEmpty
                                ? null
                                : reviewCtrl.text.trim(),
                          );
                        }
                        try {
                          ApiService.localOrders[widget.orderId]?.status = "recupere";
                          _triggerStatusNotification(widget.orderId, "recupere");
                        } catch (_) {}
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Go back to home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8612C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        selectedRating > 0
                            ? "Envoyer l'évaluation ⭐"
                            : "Fermer",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8612C)),
        ),
      );
    }

    if (_errorMsg.isNotEmpty || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Suivi de commande"),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: Center(
            child: Text(
                _errorMsg.isNotEmpty ? _errorMsg : "Commande introuvable")),
      );
    }

    final order = _order!;
    final isMoto = order.deliveryMethod == "moto";

    int activeStep = 0;
    if (order.status == "en_preparation") activeStep = 1;
    if (order.status == "en_chemin") activeStep = 2;
    if (order.status == "livree") activeStep = 3;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Suivi ${order.id}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              order.status == "livree"
                  ? "✓ Livrée"
                  : "En cours · mise à jour en temps réel",
              style: TextStyle(
                fontSize: 11,
                color: order.status == "livree"
                    ? Colors.green
                    : const Color(0xFFE8612C),
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Map ──────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Map painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MapPainter(
                          restaurant: order.restaurantLocation,
                          destination: order.destinationLocation,
                          driver: order.driverLocation,
                          status: order.status,
                          isDark: isDark,
                          isMoto: isMoto,
                        ),
                      ),
                    ),
                    // Address overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFFE8612C), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Adresse de livraison",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    order.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Driver card overlay (bottom of map)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.85)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.08),
                                blurRadius: 12)
                          ],
                        ),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    const Color(0xFFE8612C)
                                        .withOpacity(0.1),
                                child: Icon(
                                  isMoto
                                      ? Icons.motorcycle_rounded
                                      : Icons.directions_car_rounded,
                                  color: const Color(0xFFE8612C),
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMoto
                                        ? "Livreur à Moto (Rapide)"
                                        : "Livreur en Voiture",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.status == "livree"
                                        ? "✅ Votre repas est arrivé !"
                                        : (order.status == "en_chemin"
                                            ? "🛵 En route vers vous..."
                                            : "👨‍🍳 Préparation en cours..."),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: order.status == "livree"
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF8E1),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status == "livree"
                                    ? "Livré"
                                    : (order.status == "en_chemin"
                                        ? "12 min"
                                        : "20 min"),
                                style: TextStyle(
                                  color: order.status == "livree"
                                      ? Colors.green.shade700
                                      : Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Status Stepper ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Suivi de livraison",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.status == "livree"
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status == "livree"
                            ? "✓ Terminée"
                            : "⏳ En cours",
                        style: TextStyle(
                          color: order.status == "livree"
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Steps
                Row(
                  children: [
                    _buildStep(
                        0, activeStep, "Confirmée", Icons.check_circle_outline),
                    _buildStepDivider(0, activeStep),
                    _buildStep(1, activeStep, "Préparation",
                        Icons.soup_kitchen_outlined),
                    _buildStepDivider(1, activeStep),
                    _buildStep(2, activeStep, "En route",
                        Icons.motorcycle_rounded),
                    _buildStepDivider(2, activeStep),
                    _buildStep(
                        3, activeStep, "Livré", Icons.home_rounded),
                  ],
                ),
                const SizedBox(height: 20),
                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(_driver.imageUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driver.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text("${_driver.rating} · ${_driver.deliveryCount} livraisons",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Appeler le livreur"),
                              content: Text("Voulez-vous appeler ${_driver.name} au ${_driver.phone} ?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Appel du ${_driver.phone} en cours...")),
                                    );
                                  },
                                  child: const Text("Appeler", style: TextStyle(color: Color(0xFFE8612C))),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded,
                            color: Colors.green, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
      int stepIndex, int activeStep, String label, IconData icon) {
    final isDone = stepIndex <= activeStep;
    final isActive = stepIndex == activeStep;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE8612C)
                  : (isDone
                      ? const Color(0xFFE8612C).withOpacity(0.1)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive || isDone
                    ? const Color(0xFFE8612C)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : (isDone
                      ? const Color(0xFFE8612C)
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone
                  ? const Color(0xFFE8612C)
                  : (isDark ? Colors.grey.shade500 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int stepIndex, int activeStep) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      color: stepIndex < activeStep
          ? const Color(0xFFE8612C)
          : Colors.grey.shade300,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Map Painter
// ─────────────────────────────────────────────────────────────
class MapPainter extends CustomPainter {
  final MapCoordinates restaurant;
  final MapCoordinates destination;
  final MapCoordinates driver;
  final String status;
  final bool isDark;
  final bool isMoto;

  const MapPainter({
    required this.restaurant,
    required this.destination,
    required this.driver,
    required this.status,
    required this.isMoto,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color =
            isDark ? const Color(0xFF1A2332) : const Color(0xFFECF0F5),
    );

    // Road borders
    final borderPaint = Paint()
      ..color =
          isDark ? Colors.grey.shade800 : Colors.grey.shade300
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Roads
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF2A3A4A) : Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final List<Path> roads = [
      _makePath([(50, size.height * 0.7), (size.width * 0.4, size.height * 0.5),
          (size.width * 0.7, size.height * 0.6), (size.width * 0.9, size.height * 0.3)]),
      _makePath([(size.width * 0.2, 50), (size.width * 0.4, size.height * 0.5),
          (size.width * 0.3, size.height * 0.9)]),
      _makePath([(size.width * 0.6, size.height * 0.9), (size.width * 0.7, size.height * 0.6),
          (size.width * 0.8, 50)]),
    ];

    for (final road in roads) {
      canvas.drawPath(road, borderPaint);
      canvas.drawPath(road, roadPaint);
    }

    final restOffset = Offset(50, size.height * 0.7);
    final destOffset =
        Offset(size.width * 0.9, size.height * 0.3);

    double pct = 0.0;
    final latDiff = destination.lat - restaurant.lat;
    final lngDiff = destination.lng - restaurant.lng;
    if (latDiff != 0 || lngDiff != 0) {
      pct = ((driver.lat - restaurant.lat) / latDiff).clamp(0.0, 1.0);
    }

    final driverOffset = Offset(
      restOffset.dx + (destOffset.dx - restOffset.dx) * pct,
      restOffset.dy + (destOffset.dy - restOffset.dy) * pct,
    );

    // Route line
    canvas.drawLine(
      restOffset,
      destOffset,
      Paint()
        ..color = const Color(0xFFE8612C).withOpacity(0.7)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Restaurant pin (blue)
    _drawPin(canvas, restOffset, Colors.blue);
    // Destination pin (red)
    _drawPin(canvas, destOffset, Colors.red);

    // Draw driver card/icon on canvas using TextPainter
    final iconData = isMoto ? Icons.motorcycle_rounded : Icons.directions_car_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 22,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: const Color(0xFFE8612C),
      ),
    );
    textPainter.layout();

    // Draw white background circle for the icon
    canvas.drawCircle(driverOffset, 18, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(driverOffset, 18, Paint()..color = const Color(0xFFE8612C)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    textPainter.paint(
      canvas,
      Offset(driverOffset.dx - 11, driverOffset.dy - 11),
    );
  }

  Path _makePath(List<(double, double)> points) {
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final (x, y) = points[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  void _drawPin(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 14, Paint()..color = color);
    canvas.drawCircle(
        center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) =>
      oldDelegate.driver.lat != driver.lat || oldDelegate.driver.lng != driver.lng || oldDelegate.isMoto != isMoto;
}
