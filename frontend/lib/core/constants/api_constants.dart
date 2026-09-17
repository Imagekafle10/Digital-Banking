import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for every backend URL the app talks to.
///
/// The Node/Express backend exposes everything under `/api`, mounted as
/// `/api/auth`, `/api/banking`, `/api/payment`.
class ApiConstants {
  ApiConstants._();

  static String get _host {
    if (kIsWeb) {
      // Reuse whatever host the page itself was loaded from - so
      // localhost:8888 on your PC talks to localhost:5000, and
      // 192.168.18.201:8888 on your phone talks to 192.168.18.201:5000.
      return Uri.base.host;
    }
    return '192.168.18.201';
  }

  /// Matches the backend's default PORT (see backend/.env / src/config/index.ts).
  static const int port = 5000;

  static String get baseUrl => 'http://$_host:$port/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Banking
  static const String createAccount = '/banking/account';
  static const String myAccount = '/banking/account/me';
  static const String deposit = '/banking/deposit';
  static const String withdraw = '/banking/withdraw';
  static const String transfer = '/banking/transfer';
  static String transactions(String accountId) =>
      '/banking/transactions/$accountId';

  // Looks up an account by number, returning basic public info (holder's
  // name) so the sender can verify the recipient before transferring -
  // adjust this path to match your backend's actual route.
  static String accountLookup(String accountNumber) =>
      '/banking/account/lookup/$accountNumber';

  // Payment
  static const String paymentInitiate = '/payment/initiate';
  static const String khaltiReturn = '/payment/khalti/return';
  static const String esewaReturn = '/payment/esewa/return';
}
