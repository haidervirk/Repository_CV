import 'package:frontend/models/chat_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

// Chat service to handle API calls
class ChatService {
  static Future<List<ChatItem>> fetchChatItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AuthException('Please sign in to continue');
    }

    final token = await user.getIdToken();

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['base_url']}/api/chat/direct-messages/recent/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'uid': user.uid,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedJson = json.decode(response.body);
        return decodedJson.map((jsonItem) => ChatItem.fromJson(jsonItem)).toList();
      } else if (response.statusCode == 403) {
        throw AuthException('Your session has expired. Please sign in again.');
      } else {
        throw NetworkException('Unable to load your chats. Please check your connection and try again.');
      }
    } catch (e) {
      if (e is AuthException || e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Something went wrong. Please try again later.');
    }
  }
}

// Custom exceptions
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}
