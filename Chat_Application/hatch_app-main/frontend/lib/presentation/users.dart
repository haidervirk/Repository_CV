import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/users.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User> {
  UserNotifier() : super(User.default_());

  Future<void> fetchUserData() async {
    String uid = auth.FirebaseAuth.instance.currentUser!.uid;
    String apiendpointUser = "${dotenv.env['base_url']}/api/user/$uid/";

    try {
      final response = await http.get(
        Uri.parse(apiendpointUser),
      );

      if (response.statusCode == 200) {
        state = User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load user data");
      }
    } catch (e) {
      print(e);
    }
  }
}
