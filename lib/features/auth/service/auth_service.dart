import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      'http://192.168.100.113:2340/auth'; // Change for production

  Future<String?> register(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'profile_picture': '', // Optional
      }),
    );

    if (res.statusCode == 200) {
      return login(username, password); // Login right after register
    }

    return null;
  }

  Future<String?> login(String username, String password) async {
    log("heyoo");
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    log(res.body);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['token']; // Token returned from backend
    }

    return null;
  }
}
