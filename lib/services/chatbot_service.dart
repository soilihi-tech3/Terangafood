import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String _apiKey = 'PLXkPaOIbmxUlUGVPK3l40tiV9JuVgvhBgWEnDC3';
  final String _apiUrl = 'https://api.cohere.com/v2/chat';

  /// Sends the conversation history to Cohere and returns the assistant's reply.
  /// The chat history is expected to be a list of maps with 'isBot' (bool) and 'text' (String).
  Future<String> getChatResponse(List<Map<String, dynamic>> conversationHistory) async {
    try {
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': 'Tu es TerangaBot 🤖, l\'assistant virtuel du restaurant TerangaFood à Dakar, Sénégal. '
              'Sois accueillant, chaleureux et professionnel. Réponds principalement en français et utilise des émojis. '
              'Tu peux aussi comprendre et utiliser un peu de wolof. '
              'Aide l\'utilisateur à trouver des plats du menu (Thiéboudienne, Yassa, Mafé, Burgers, Pizzas, Thiakry, Bissap, Bouye), '
              'des informations de livraison (Moto: 800 F, Voiture: 1500 F, partout à Dakar), '
              'et de paiement (Wave, Orange Money, Espèces à la livraison). '
              'Sois concis dans tes réponses.'
        }
      ];

      for (final msg in conversationHistory) {
        messages.add({
          'role': msg['isBot'] == true ? 'assistant' : 'user',
          'content': msg['text'] as String,
        });
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': 'command-r-plus-08-2024',
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['message']?['content'];
        if (content is List && content.isNotEmpty) {
          return content[0]['text'] as String? ?? "Je n'ai pas pu générer de réponse.";
        } else if (content is String) {
          return content;
        } else if (data['text'] != null) {
          return data['text'] as String;
        }
      }
      
      // Fallback response in case of API failure
      return "Désolé, je rencontre des difficultés pour me connecter à mon serveur. Comment puis-je vous aider d'autre ?";
    } catch (e) {
      return "Une erreur est survenue lors de la communication avec l'assistant. Veuillez réessayer.";
    }
  }
}
