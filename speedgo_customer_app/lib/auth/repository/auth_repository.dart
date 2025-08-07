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

    if (responseBody['status'] == true) {
      final token = responseBody['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (responseBody['status'] == true) {
      // Success
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to register');
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify-otp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'phone': phone, 'otp': otp}),
    );

    final responseBody = jsonDecode(response.body);

    if (responseBody['status'] == true) {
      final token = responseBody['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to verify OTP');
    }
  }
}
