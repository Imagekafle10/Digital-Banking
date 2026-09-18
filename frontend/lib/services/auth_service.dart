import '../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _client = ApiClient.instance;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.register,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
      },
    );
    final data = response.data['data'];
    await _client.setAccessToken(data['accessToken'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'];
    await _client.setAccessToken(data['accessToken'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> getMe() async {
    final response = await _client.dio.get(ApiConstants.me);
    final data = response.data['data'];
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } finally {
      await _client.clearAccessToken();
    }
  }
}
