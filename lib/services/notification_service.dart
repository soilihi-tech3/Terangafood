import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  List<NotificationItem> get notifications => notificationsNotifier.value;

  int get unreadCount =>
      notificationsNotifier.value.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications/$email'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final List<NotificationItem> list = [];
        for (var item in decoded) {
          final val = item as Map<String, dynamic>;
          list.add(
            NotificationItem(
              id: val['id'] ?? '',
              title: val['title'] ?? '',
              body: val['body'] ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(val['timestamp'] as int),
              isRead: val['isRead'] ?? false,
            ),
          );
        }
        notificationsNotifier.value = list;
      }
    } catch (_) {}
  }

  Future<void> addNotification({required String title, required String body}) async {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    notificationsNotifier.value = [newItem, ...notificationsNotifier.value];

    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': AuthService().email,
          'title': title,
          'body': body,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    for (var n in notificationsNotifier.value) {
      n.isRead = true;
    }
    notificationsNotifier.value = List.from(notificationsNotifier.value);

    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/notifications/read-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': AuthService().email,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> clearAll() async {
    notificationsNotifier.value = [];
    try {
      await http.delete(
        Uri.parse('${ApiService.baseUrl}/notifications/${AuthService().email}'),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
