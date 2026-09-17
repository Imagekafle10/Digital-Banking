import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for every backend URL the app talks to.
///
/// The Node/Express backend exposes everything under `/api`, mounted as
/// `/api/auth`, `/api/banking`, `/api/payment`.
class ApiConstants {
  ApiConstants._();

  /// Flip this to switch the whole app between your local backend and the
  /// live Render deployment. Set to `true` once you're testing against
  /// real data / before a release build; keep `false` for day-to-day local
  /// development against `npm run dev` on your PC.
  static const bool useProduction = false;

  /// Your live Render deployment.
  static const String _productionUrl =
      'https://digital-banking-7mgs.onrender.com';

  /// Your PC's LAN IP (from `ipconfig` / `ifconfig`) - used when a real
  /// phone or an Android emulator needs to reach the backend running on
  /// this machine. Update this if your PC's IP changes (e.g. new WiFi).
  static const String _lanIp = '192.168.18.201';

  static String get _host {
    if (kIsWeb) {
      // Reuse whatever host the page itself was loaded from - so
      // localhost:8888 on your PC talks to localhost:5000, and
      // 192.168.18.201:8888 on your phone talks to 192.168.18.201:5000.
      return Uri.base.host;
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the Android emulator's special alias for the host
      // machine's localhost. A real device can't reach 127.0.0.1 or
      // 10.0.2.2 (those point at the phone/emulator itself), so it
      // needs the PC's actual LAN IP instead. If you're on a real
      // device, set isPhysicalDevice to true below.
      const isPhysicalDevice = true;
      return isPhysicalDevice ? _lanIp : '10.0.2.2';
    }
    if (Platform.isIOS) {
      // iOS simulator can reach the host machine via localhost; a real
      // iPhone needs the PC's LAN IP, same as a real Android device.
      const isPhysicalDevice = true;
      return isPhysicalDevice ? _lanIp : '127.0.0.1';
    }
    // Windows/macOS/Linux desktop and the Node backend are on the same
    // machine here, so talk to it over loopback.
    return '127.0.0.1';
  }

  /// Matches the backend's default PORT (see backend/.env / src/config/index.ts).
  static const int port = 5000;

  static String get baseUrl =>
      useProduction ? '$_productionUrl/api' : 'http://$_host:$port/api';

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
