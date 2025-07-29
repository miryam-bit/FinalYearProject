import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final String _baseUrl = "http://192.168.10.81:8000/api/auth";

  Future<void> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'phone': phone,
        'password': password,
      }),
    );
    final responseBody = jsonDecode(response.body);

    if (responseBody['status'] == true && responseBody['user']['role'] == 'driver') {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
} 