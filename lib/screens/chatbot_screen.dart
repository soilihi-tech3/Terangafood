import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chatbot_service.dart';
import '../services/chat_history_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final ChatHistoryService _historyService = ChatHistoryService();
  final ImagePicker _imagePicker = ImagePicker();

  String _conversationId = DateTime.now().millisecondsSinceEpoch.toString();
  String _conversationTitle = "Nouvelle conversation";

  List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': "Salam ! Je suis TerangaBot 🤖, votre assistant virtuel. Comment puis-je vous aider aujourd'hui ?",
    }
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;
  List<ChatConversation> _savedConversations = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryList();
  }

  Future<void> _loadHistoryList() async {
    final list = await _historyService.getConversations();
    setState(() {
      _savedConversations = list;
    });
  }

  Future<void> _saveCurrentConversation() async {
    final convo = ChatConversation(
      id: _conversationId,
      title: _conversationTitle,
      messages: _messages,
    );
    await _historyService.saveConversation(convo);
    await _loadHistoryList();
  }

  void _startNewConversation() {
    setState(() {
      _conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      _conversationTitle = "Nouvelle conversation";
      _messages = [
        {
          'isBot': true,
          'text': "Salam ! Je suis TerangaBot 🤖, votre assistant virtuel. Comment puis-je vous aider aujourd'hui ?",
        }
      ];
    });
  }

  Future<void> _loadConversation(ChatConversation convo) async {
    setState(() {
      _conversationId = convo.id;
      _conversationTitle = convo.title;
      _messages = List.from(convo.messages);
    });
    Navigator.pop(context); // Close Drawer
    _scrollToBottom();
  }

  Future<void> _deleteConvo(String id) async {
    await _historyService.deleteConversation(id);
    await _loadHistoryList();
    if (_conversationId == id) {
      _startNewConversation();
    }
  }

  Future<void> _clearAllConvos() async {
    await _historyService.clearAll();
    await _loadHistoryList();
    _startNewConversation();
  }

  Future<void> _sendUserMessage(String userText) async {
    if (userText.isEmpty || _isTyping) return;

    if (_messages.length == 1 && _conversationTitle == "Nouvelle conversation") {
      _conversationTitle = userText.length > 25 ? "${userText.substring(0, 22)}..." : userText;
    }

    setState(() {
      _messages.add({'isBot': false, 'text': userText});
      _isTyping = true;
    });

    _scrollToBottom();
    await _saveCurrentConversation();

    final response = await _chatbotService.getChatResponse(_messages);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add({'isBot': true, 'text': response});
    });

    _scrollToBottom();
    await _saveCurrentConversation();
  }

  Future<void> _analyzePhoto() async {
    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final path = file.path;
      final name = file.name.toLowerCase();

      setState(() {
        _messages.add({
          'isBot': false,
          'text': "Photo envoyée pour analyse 📸",
          'imagePath': path,
        });
        _isTyping = true;
      });

      _scrollToBottom();
      await _saveCurrentConversation();

      // Simulate AI Vision analysis delay
      await Future.delayed(const Duration(seconds: 2));

      String responseText = "";
      final isAvailable = name.contains("thieb") ||
          name.contains("poulet") ||
          name.contains("yassa") ||
          name.contains("mafe") ||
          name.contains("beef") ||
          name.contains("boeuf") ||
          name.contains("burger") ||
          name.contains("pizza") ||
          name.contains("thiakry") ||
          name.contains("bissap") ||
          name.contains("bouye") ||
          name.contains("plat") ||
          name.contains("food") ||
          name.contains("dessert");

      if (isAvailable) {
        String foodName = "ce plat";
        if (name.contains("thieb")) foodName = "notre célèbre Thiéboudienne Penda Mbaye";
        if (name.contains("yassa")) foodName = "notre délicieux Yassa au Poulet";
        if (name.contains("mafe")) foodName = "notre Mafé au Boeuf crémeux";
        if (name.contains("burger")) foodName = "notre Double Teranga Burger";
        if (name.contains("pizza")) foodName = "notre Pizza Teranga Spéciale";
        if (name.contains("thiakry")) foodName = "notre Thiakry Onctueux";
        if (name.contains("bissap")) foodName = "notre Bissap Royal glacé";
        if (name.contains("bouye")) foodName = "notre succulent Jus de Bouye";

        responseText = "🔍 **Analyse de la photo terminée :**\n"
            "D'après l'analyse visuelle de cette image, il s'agit de **$foodName**.\n\n"
            "✅ **Ce plat est disponible dans notre restaurant !**\n"
            "Vous pouvez le retrouver dès maintenant dans le menu de notre application pour passer commande.";
      } else {
        responseText = "🔍 **Analyse de la photo terminée :**\n"
            "Je détecte un plat sur cette image, mais il ne semble pas correspondre à l'un de nos plats au menu de TerangaFood.\n\n"
            "❌ **Ce plat n'est pas disponible dans notre restaurant.**\n"
            "N'hésitez pas à jeter un œil à nos spécialités sénégalaises (Thiéboudienne, Yassa, Mafé) ou nos pizzas et burgers faits maison !";
      }

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({'isBot': true, 'text': responseText});
      });

      _scrollToBottom();
      await _saveCurrentConversation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isBot': true,
          'text': "Désolé, je n'ai pas pu charger ou analyser cette photo. Assurez-vous qu'elle soit au bon format.",
        });
      });
    }
  }

  void _triggerVoiceRecording() {
    // Pulse wave simulation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFE8612C).withOpacity(0.12),
                child: const Icon(Icons.mic_rounded, color: Color(0xFFE8612C), size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enregistrement vocal...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Dites ce que vous souhaitez commander ou demandez de l'aide.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              // Pulse/wave indicator row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: 15.0 + (index % 2 == 0 ? 10 : 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8612C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close recording dialog

                  // Transcribe a random food query to simulate Speech to Text
                  final voiceQueries = [
                    "Je voudrais commander une Thiéboudienne Penda Mbaye s'il vous plaît.",
                    "Est-ce que vous livrez aux Almadies actuellement ?",
                    "Est-ce que je peux payer par Wave à la livraison ?",
                    "Quels sont vos desserts traditionnels du Sénégal ?",
                  ];
                  final randomQuery = (voiceQueries..shuffle()).first;

                  _sendUserMessage(randomQuery);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8612C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text("Terminer", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatOption(String label, String query, bool isDark) {
    return ActionChip(
      onPressed: () => _sendUserMessage(query),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE8612C)),
      ),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: "Historique des conversations",
            );
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8612C).withOpacity(0.12),
              radius: 16,
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFFE8612C), size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "TerangaBot 🤖 · En ligne",
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: _startNewConversation,
            tooltip: "Nouvelle conversation",
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
            tooltip: "Retour",
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Conversations",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (_savedConversations.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Tout supprimer"),
                              content: const Text("Voulez-vous supprimer tout votre historique de conversations ?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _clearAllConvos();
                                  },
                                  child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: "Effacer tout l'historique",
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _savedConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "Aucun historique",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _savedConversations.length,
                        itemBuilder: (context, index) {
                          final convo = _savedConversations[index];
                          final isCurrent = convo.id == _conversationId;
                          return ListTile(
                            leading: Icon(
                              Icons.chat_rounded,
                              color: isCurrent ? const Color(0xFFE8612C) : Colors.grey,
                              size: 20,
                            ),
                            title: Text(
                              convo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent
                                    ? const Color(0xFFE8612C)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            onTap: () => _loadConversation(convo),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                              onPressed: () => _deleteConvo(convo.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Suggestions Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.5) : Colors.grey.shade50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildChatOption("📦 Où est ma commande ?", "Où est ma commande ?", isDark),
                    const SizedBox(width: 8),
                    _buildChatOption("💵 Modes de paiement", "Quels sont les modes de paiement ?", isDark),
                    const SizedBox(width: 8),
                    _buildChatOption("🛵 Comment marche la livraison ?", "Comment marche la livraison ?", isDark),
                    const SizedBox(width: 8),
                    _buildChatOption("📞 Contacter le support", "Comment contacter le support ?", isDark),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Chat history
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8612C)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "TerangaBot réfléchit...",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = _messages[index];
                  final isBot = msg['isBot'] as bool;
                  final imagePath = msg['imagePath'] as String?;

                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isBot
                            ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100)
                            : const Color(0xFFE8612C),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                          bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(imagePath),
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SelectableText(
                            msg['text'],
                            style: TextStyle(
                              color: isBot
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Message input with Attachment, Microphone and Send actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFE8612C)),
                    onPressed: _analyzePhoto,
                    tooltip: "Ajouter une photo à analyser",
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: Color(0xFFE8612C)),
                    onPressed: _triggerVoiceRecording,
                    tooltip: "Faire un message vocal",
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: InputDecoration(
                        hintText: "Écrivez votre message...",
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                      onSubmitted: (val) {
                        final text = val.trim();
                        if (text.isNotEmpty) {
                          _inputCtrl.clear();
                          _sendUserMessage(text);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE8612C),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      onPressed: () {
                        final text = _inputCtrl.text.trim();
                        if (text.isNotEmpty) {
                          _inputCtrl.clear();
                          _sendUserMessage(text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
