import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  /// Called once at startup after [ApiClient.init]. Tries a silent refresh
  /// using the persisted refresh-token cookie so a returning user lands
  /// straight on the dashboard instead of the login screen.
  Future<void> bootstrap() async {
    final refreshed = await ApiClient.instance.trySilentRefresh();
    status = refreshed ? AuthStatus.authenticated : AuthStatus.unauthenticated;
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
  }) async {
    user = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
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
