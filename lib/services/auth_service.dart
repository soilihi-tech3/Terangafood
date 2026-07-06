import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String name;
  String email;
  String phone;
  String avatarUrl;
  String password;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.password,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    // Seed default user
    _users[email.toLowerCase().trim()] = UserProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      password: password,
    );
  }

  String name = "Moussa Diop";
  String email = "moussa.diop@gmail.com";
  String phone = "+221 77 123 45 67";
  String avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop";
  String password = "password123";

  final Map<String, UserProfile> _users = {};

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_name', name);
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_phone', phone);
    await prefs.setString('auth_avatarUrl', avatarUrl);
    await prefs.setString('auth_password', password);

    final usersJson = _users.map((k, v) => MapEntry(k, {
      'name': v.name,
      'email': v.email,
      'phone': v.phone,
      'avatarUrl': v.avatarUrl,
      'password': v.password,
    }));
    await prefs.setString('auth_users', jsonEncode(usersJson));
  }

  void loadFromPrefs(SharedPreferences prefs) {
    name = prefs.getString('auth_name') ?? name;
    email = prefs.getString('auth_email') ?? email;
    phone = prefs.getString('auth_phone') ?? phone;
    avatarUrl = prefs.getString('auth_avatarUrl') ?? avatarUrl;
    password = prefs.getString('auth_password') ?? password;

    final usersStr = prefs.getString('auth_users');
    if (usersStr != null) {
      try {
        final decoded = jsonDecode(usersStr) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          final val = v as Map<String, dynamic>;
          _users[k] = UserProfile(
            name: val['name'] ?? '',
            email: val['email'] ?? '',
            phone: val['phone'] ?? '',
            avatarUrl: val['avatarUrl'] ?? '',
            password: val['password'] ?? '',
          );
        });
      } catch (_) {}
    }
  }

  void registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    final newUser = UserProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop",
      password: password,
    );
    _users[email.toLowerCase().trim()] = newUser;
    saveToPrefs();
  }

  bool loginUser(String email, String password) {
    final cleanedEmail = email.toLowerCase().trim();
    if (_users.containsKey(cleanedEmail)) {
      final user = _users[cleanedEmail]!;
      this.name = user.name;
      this.email = user.email;
      this.phone = user.phone;
      this.avatarUrl = user.avatarUrl;
      this.password = user.password;
      saveToPrefs();
      return true;
    }
    // If not registered, create user dynamically so they can login directly
    final generatedName = cleanedEmail.split('@').first;
    final capitalizedName = generatedName[0].toUpperCase() + generatedName.substring(1);
    final newUser = UserProfile(
      name: capitalizedName,
      email: cleanedEmail,
      phone: "+221 77 999 99 99",
      avatarUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop",
      password: password,
    );
    _users[cleanedEmail] = newUser;
    this.name = newUser.name;
    this.email = newUser.email;
    this.phone = newUser.phone;
    this.avatarUrl = newUser.avatarUrl;
    this.password = newUser.password;
    saveToPrefs();
    return true;
  }

  void updateUser({required String name, required String email, required String phone, String? avatarUrl}) {
    this.name = name;
    this.email = email;
    this.phone = phone;
    if (avatarUrl != null) {
      this.avatarUrl = avatarUrl;
    }
    // Sync inside map
    final cleaned = email.toLowerCase().trim();
    if (_users.containsKey(cleaned)) {
      _users[cleaned]!.name = name;
      _users[cleaned]!.phone = phone;
      if (avatarUrl != null) {
        _users[cleaned]!.avatarUrl = avatarUrl;
      }
    }
    saveToPrefs();
  }

  void logout() {
    name = "Moussa Diop";
    email = "moussa.diop@gmail.com";
    phone = "+221 77 123 45 67";
    avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop";
    saveToPrefs();
  }
}
