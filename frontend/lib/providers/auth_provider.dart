import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  Future<void> bootstrap() async {
    final refreshed = await ApiClient.instance.trySilentRefresh();
    if (!refreshed) {
      user = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _authService.getMe();
      status = AuthStatus.authenticated;
    } catch (_) {
      user = null;
      status = AuthStatus.unauthenticated;
      await ApiClient.instance.clearAccessToken();
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    user = await _authService.login(email: email, password: password);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    user = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
