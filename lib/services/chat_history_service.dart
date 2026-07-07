import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatConversation {
  final String id;
  final String title;
  final List<Map<String, dynamic>> messages;

  ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages,
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        id: json['id'] as String,
        title: json['title'] as String,
        messages: List<Map<String, dynamic>>.from(
          (json['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)),
        ),
      );
}

class ChatHistoryService {
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  static const String _prefKey = 'teranga_chat_conversations';

  Future<List<ChatConversation>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_prefKey);
    if (data == null) return [];
    return data.map((item) => ChatConversation.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> saveConversation(ChatConversation conversation) async {
    final list = await getConversations();
    final idx = list.indexWhere((c) => c.id == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation;
    } else {
      list.insert(0, conversation);
    }
    await _saveAll(list);
  }

  Future<void> deleteConversation(String id) async {
    final list = await getConversations();
    list.removeWhere((c) => c.id == id);
    await _saveAll(list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  Future<void> _saveAll(List<ChatConversation> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_prefKey, data);
  }
}
