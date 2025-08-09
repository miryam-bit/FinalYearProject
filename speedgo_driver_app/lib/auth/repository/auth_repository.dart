import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final String _baseUrl = "http://192.168.10.60:8000/api/auth";

  Future<void> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'phone': phone, 'password': password}),
    );
    final responseBody = jsonDecode(response.body);

    if (responseBody['status'] == true &&
        responseBody['user']['role'] == 'driver') {
      final token = responseBody['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else if (responseBody['status'] == true) {
      throw Exception('Not a driver account');
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        // Call backend logout endpoint
        final response = await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        // Even if backend call fails, we still want to clear local token
        print('Logout response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Logout error: $e');
      // Continue with local logout even if backend call fails
    } finally {
      // Always clear local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }
}
