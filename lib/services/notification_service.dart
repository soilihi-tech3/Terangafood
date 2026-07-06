import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notificationsNotifier.value.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'timestamp': n.timestamp.millisecondsSinceEpoch,
      'isRead': n.isRead,
    }).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  void loadFromPrefs(SharedPreferences prefs) {
    final notifsStr = prefs.getString('notifications');
    if (notifsStr != null) {
      try {
        final decoded = jsonDecode(notifsStr) as List<dynamic>;
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
      } catch (_) {}
    }
  }

  void addNotification({required String title, required String body}) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    notificationsNotifier.value = [newItem, ...notificationsNotifier.value];
    saveToPrefs();
  }

  void markAllAsRead() {
    for (var n in notificationsNotifier.value) {
      n.isRead = true;
    }
    notificationsNotifier.value = List.from(notificationsNotifier.value);
    saveToPrefs();
  }

  void clearAll() {
    notificationsNotifier.value = [];
    saveToPrefs();
  }
}
