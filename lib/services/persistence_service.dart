import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'order_history_service.dart';
import 'notification_service.dart';
import 'favorites_service.dart';

class PersistenceService {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load data into singletons
    AuthService().loadFromPrefs(prefs);
    OrderHistoryService().loadFromPrefs(prefs);
    NotificationService().loadFromPrefs(prefs);
    FavoritesService().loadFromPrefs(prefs);
  }
}
