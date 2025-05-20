import 'package:flutter/material.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/presentation/screens/auth/login_screen.dart';
import 'package:pwd_verification_app/presentation/screens/auth/register_screen.dart';
import 'package:pwd_verification_app/presentation/screens/home/home_screen.dart';
import 'package:pwd_verification_app/presentation/screens/scan/scan_history_screen.dart';
import 'package:pwd_verification_app/presentation/screens/scan/scan_screen.dart';
import 'package:pwd_verification_app/presentation/screens/scan/verification_result_screen.dart';
import 'package:pwd_verification_app/presentation/screens/scan/manual_entry_screen.dart';
import 'package:pwd_verification_app/presentation/screens/settings/settings_screen.dart';
import 'package:pwd_verification_app/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
        
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case '/scan':
        return MaterialPageRoute(builder: (_) => const ScanScreen());
        
      case '/scan_history':
        return MaterialPageRoute(builder: (_) => const ScanHistoryScreen());
        
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
        
      case '/manual_entry':
        return MaterialPageRoute(builder: (_) => const ManualEntryScreen());
      
      case '/verification_result':
        final scanResult = settings.arguments as ScanResult;
        return MaterialPageRoute(
          builder: (_) => VerificationResultScreen(scanResult: scanResult),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

// Custom RouteObserver for navigation tracking
class AppRouteObserver {
  static final navigatorObserver = RouteObserver<PageRoute>();
}