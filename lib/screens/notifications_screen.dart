import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/notification_service.dart';
import '../services/order_history_service.dart';
import 'order_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final Function(FoodItem, int) onUpdateCart;

  const NotificationsScreen({
    super.key,
    required this.onUpdateCart,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _currentFilter = 'tout'; // 'tout' | 'lu' | 'non_lu'

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8612C)
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF3E0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : const Color(0xFFE8612C),
          ),
        ),
      ),
    );
  }

  void _handleNotificationClick(NotificationItem n) {
    // Mark as read
    setState(() {
      n.isRead = true;
    });

    // Extract Order ID if present in body or title (e.g. TF-211425)
    final match = RegExp(r'TF-\d{6}').firstMatch(n.body) ?? RegExp(r'TF-\d{6}').firstMatch(n.title);
    if (match != null) {
      final orderId = match.group(0);
      try {
        final order = OrderHistoryService().all.firstWhere((o) => o.id == orderId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(
              order: order,
              onUpdateCart: widget.onUpdateCart,
            ),
          ),
        );
      } catch (_) {
        // If order not found in history
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de trouver la commande $orderId dans l'historique."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNotifications = NotificationService().notifications;

    // Filter list
    final filteredList = allNotifications.where((n) {
      if (_currentFilter == 'lu') {
        return n.isRead;
      } else if (_currentFilter == 'non_lu') {
        return !n.isRead;
      }
      return true;
    }).toList();

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
          "Notifications 🔔",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          if (allNotifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  NotificationService().clearAll();
                });
              },
              child: const Text(
                "Tout effacer",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.5) : Colors.grey.shade50,
              child: Row(
                children: [
                  _buildFilterChip("Toutes", "tout"),
                  _buildFilterChip("Lues", "lu"),
                  _buildFilterChip("Non lues", "non_lu"),
                  const Spacer(),
                  if (allNotifications.any((n) => !n.isRead))
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      onPressed: () {
                        setState(() {
                          NotificationService().markAllAsRead();
                        });
                      },
                      child: const Text(
                        "Tout lire",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE8612C)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Notification list
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8612C).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_off_rounded,
                              size: 64,
                              color: Color(0xFFE8612C),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Aucune notification trouvée",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final n = filteredList[index];
                        final hasOrderLink = RegExp(r'TF-\d{6}').hasMatch(n.body) || RegExp(r'TF-\d{6}').hasMatch(n.title);

                        return GestureDetector(
                          onTap: () => _handleNotificationClick(n),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50)
                                  : (isDark ? const Color(0xFF35221B) : const Color(0xFFFFF6F0)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !n.isRead
                                    ? const Color(0xFFE8612C).withOpacity(0.3)
                                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8612C).withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_rounded,
                                        color: Color(0xFFE8612C),
                                        size: 20,
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Positioned(
                                        right: 0,
                                        top: 0,
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
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (hasOrderLink)
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 12,
                                              color: Color(0xFFE8612C),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        n.body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
