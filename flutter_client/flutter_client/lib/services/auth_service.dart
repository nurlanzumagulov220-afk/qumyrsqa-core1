import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  final String userId;
  final String name;
  final String email;
  final String token;

  const UserInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
  });

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        userId: j['user_id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        token: j['token'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'user_id': userId, 'name': name, 'email': email, 'token': token};
}

class AuthService {
  static const _base = 'http://localhost:8000';
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_info';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<UserInfo?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_userKey);
    if (s == null) return null;
    return UserInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  static Future<void> _save(UserInfo u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, u.token);
    await prefs.setString(_userKey, jsonEncode(u.toJson()));
  }

  static Future<UserInfo> register(String name, String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final u = UserInfo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
      await _save(u);
      return u;
    }
    final detail = (jsonDecode(resp.body) as Map<String, dynamic>)['detail'];
    throw Exception(detail ?? 'Registration failed');
  }

  static Future<UserInfo> login(String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final u = UserInfo.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
      await _save(u);
      return u;
    }
    final detail = (jsonDecode(resp.body) as Map<String, dynamic>)['detail'];
    throw Exception(detail ?? 'Login failed');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, dynamic>> getCabinet() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final resp = await http.get(
      Uri.parse('$_base/cabinet'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load cabinet');
  }
}
