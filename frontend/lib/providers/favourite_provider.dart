import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favourite_account.dart';

class FavouriteProvider extends ChangeNotifier {
  static const _prefsKey = 'favourite_accounts_v1';

  List<FavouriteAccount> favourites = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        favourites = [];
      } else {
        final list = jsonDecode(raw) as List<dynamic>;
        favourites = list
            .map((e) => FavouriteAccount.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      favourites = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(favourites.map((f) => f.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> add({
    required String name,
    required String accountNumber,
  }) async {
    final trimmedName = name.trim();
    final trimmedNumber = accountNumber.trim();
    if (trimmedName.isEmpty || trimmedNumber.isEmpty) return;

    // Avoid duplicate account numbers
    final exists = favourites.any((f) => f.accountNumber == trimmedNumber);
    if (exists) {
      // Update name if already saved
      favourites = favourites
          .map(
            (f) => f.accountNumber == trimmedNumber
                ? FavouriteAccount(
                    id: f.id,
                    name: trimmedName,
                    accountNumber: f.accountNumber,
                  )
                : f,
          )
          .toList();
    } else {
      favourites = [
        FavouriteAccount(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: trimmedName,
          accountNumber: trimmedNumber,
        ),
        ...favourites,
      ];
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    favourites = favourites.where((f) => f.id != id).toList();
    notifyListeners();
    await _persist();
  }

  bool isFavourite(String accountNumber) {
    return favourites.any((f) => f.accountNumber == accountNumber.trim());
  }
}
