import 'package:flutter/material.dart';
import 'models/food_model.dart';
import 'services/theme_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/cart_screen.dart';
import 'services/persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersistenceService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData get _lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8612C),
          primary: const Color(0xFFE8612C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF8F4),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFE8612C),
          unselectedItemColor: Color(0xFFB0B0B0),
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      );

  ThemeData get _darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8612C),
          primary: const Color(0xFFE8612C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFFE8612C),
          unselectedItemColor: Color(0xFF666666),
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'TerangaFood',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Main container — 5-tab bottom navigation
//   0: Accueil   1: Explorer   2: Favoris
//   3: Commandes 4: Profil
// ─────────────────────────────────────────────
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final Map<FoodItem, int> _cart = {};
  String _initialSearchQuery = "";

  String _selectedStreet = "Route de la Pointe des Almadies, Dakar";
  double _selectedLat = 14.7465;
  double _selectedLng = -17.5258;

  void _updateCart(FoodItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(item);
      } else {
        _cart[item] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(
        cart: _cart,
        onUpdateCart: _updateCart,
        onSwitchTab: (index, {String searchQuery = ""}) {
          setState(() {
            _currentIndex = index;
            _initialSearchQuery = searchQuery;
          });
        },
        selectedStreet: _selectedStreet,
        selectedLat: _selectedLat,
        selectedLng: _selectedLng,
        onStreetChanged: (street, lat, lng) {
          setState(() {
            _selectedStreet = street;
            _selectedLat = lat;
            _selectedLng = lng;
          });
        },
      ),
      ExploreScreen(
        cart: _cart,
        onUpdateCart: _updateCart,
        initialSearchQuery: _initialSearchQuery,
        onSearchQueryConsumed: () {
          _initialSearchQuery = "";
        },
      ),
      OrderHistoryScreen(cart: _cart, onUpdateCart: _updateCart),
      ProfileScreen(cart: _cart, onUpdateCart: _updateCart),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartScreen(
                cart: _cart,
                selectedStreet: _selectedStreet,
                selectedLat: _selectedLat,
                selectedLng: _selectedLng,
                onUpdateCart: _updateCart,
                onClearCart: () => setState(() => _cart.clear()),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFFE8612C),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28),
            if (_cart.values.fold(0, (a, b) => a + b) > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700), // Bright Yellow color for clear readability
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    "${_cart.values.fold(0, (a, b) => a + b)}",
                    style: const TextStyle(
                      color: Colors.black, // High contrast text on yellow background
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomAppBar(
          notchMargin: 6,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: const CircularNotchedRectangle(),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Accueil
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                      size: 26,
                      color: _currentIndex == 0 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Accueil",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        color: _currentIndex == 0 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              // Explorer
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 1 ? Icons.explore_rounded : Icons.explore_outlined,
                      size: 26,
                      color: _currentIndex == 1 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Explorer",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        color: _currentIndex == 1 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 44), // Space for floating button
              // Commandes
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 2 ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
                      size: 26,
                      color: _currentIndex == 2 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Commandes",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                        color: _currentIndex == 2 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              // Profil
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
                      size: 26,
                      color: _currentIndex == 3 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Profil",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: _currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                        color: _currentIndex == 3 ? const Color(0xFFE8612C) : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
