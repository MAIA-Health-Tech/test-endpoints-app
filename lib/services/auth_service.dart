import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final String baseUrl = 'http://maia.clinic/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['accessToken']);
      await prefs.setString('refresh_token', data['refreshToken']);
      await prefs.setString('user_id', data['user']['id']);
      await prefs.setString('user_email', data['user']['email']);

      return data;
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
