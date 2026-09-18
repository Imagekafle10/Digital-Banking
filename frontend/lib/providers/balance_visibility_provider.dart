import 'package:flutter/foundation.dart';

/// Whether account balances are currently obscured, shared across every
/// BalanceCard in the app. Toggling it on one screen (Dashboard, Send
/// Money, anywhere else the card appears) updates all of them at once,
/// the same way a real banking app remembers you already chose to reveal
/// your balance.
class BalanceVisibilityProvider extends ChangeNotifier {
  // Hidden by default, like a real card never shows your balance at a glance.
  bool _obscured = true;

  bool get obscured => _obscured;

  void toggle() {
    _obscured = !_obscured;
    notifyListeners();
  }
}
