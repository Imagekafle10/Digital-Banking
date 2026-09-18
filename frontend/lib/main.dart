import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/balance_visibility_provider.dart';
import 'providers/favourite_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const NepalBankApp());
}

class NepalBankApp extends StatelessWidget {
  const NepalBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => BalanceVisibilityProvider()),
      ],
      child: MaterialApp(
        title: 'Image Bank',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
