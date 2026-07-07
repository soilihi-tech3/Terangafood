import 'auth_service.dart';
import 'order_history_service.dart';
import 'notification_service.dart';
import 'favorites_service.dart';

class PersistenceService {
  static Future<void> init() async {
    // Load initial data for default user from the backend server
    final email = AuthService().email;
    await Future.wait([
      OrderHistoryService().fetchHistory(email),
      NotificationService().fetchNotifications(email),
      FavoritesService().fetchFavorites(email),
    ]);
  }
}
