import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

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

  AuthService._internal();

  String name = "Moussa Diop";
  String email = "moussa.diop@gmail.com";
  String phone = "+221 77 123 45 67";
  String avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop";
  String password = "password123";

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        this.name = data['name'] ?? name;
        this.email = data['email'] ?? email;
        this.phone = data['phone'] ?? phone;
        this.avatarUrl = data['avatarUrl'] ?? this.avatarUrl;
        this.password = data['password'] ?? password;
      }
    } catch (_) {
      this.name = name;
      this.email = email;
      this.phone = phone;
      this.password = password;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        this.name = data['name'] ?? this.name;
        this.email = data['email'] ?? email;
        this.phone = data['phone'] ?? this.phone;
        this.avatarUrl = data['avatarUrl'] ?? this.avatarUrl;
        this.password = data['password'] ?? password;
        return true;
      }
    } catch (_) {}

    final generatedName = email.toLowerCase().trim().split('@').first;
    this.name = generatedName[0].toUpperCase() + generatedName.substring(1);
    this.email = email;
    this.phone = "+221 77 999 99 99";
    this.password = password;
    return true;
  }

  Future<void> updateUser({required String name, required String email, required String phone, String? avatarUrl}) async {
    this.name = name;
    this.email = email;
    this.phone = phone;
    if (avatarUrl != null) {
      this.avatarUrl = avatarUrl;
    }
    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'avatarUrl': avatarUrl,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  void logout() {
    name = "Moussa Diop";
    email = "moussa.diop@gmail.com";
    phone = "+221 77 123 45 67";
    avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop";
  }
}
