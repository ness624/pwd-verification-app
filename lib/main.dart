import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'di/service_locator.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/scan/scan_bloc.dart';
import 'presentation/bloc/connectivity/connectivity_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
// --- Correct Import for Connectivity Event ---
import 'presentation/bloc/connectivity/connectivity_event.dart'; // Ensure this has ConnectivityStartMonitoring
// --- Correct Import for Routes ---
import 'config/routes.dart' as routes; // Keep alias if you use AppRouter from it

// Remove splash screen import if initial route is '/'
// import 'presentation/screens/splash_screen.dart';
import 'config/theme.dart'; // Ensure this import is correct

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lydwpymimktiqqroeexb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5ZHdweW1pbWt0aXFxcm9lZXhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjUwMzEsImV4cCI6MjA2MTQ0MTAzMX0.wrg7yIcJ31peiGrccbEy8VX2ZQLIDgLDZBwgvS-Nkp4',
  );

  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(CheckAuthStatusEvent()),
          lazy: false,
        ),
        BlocProvider<ScanBloc>(
          create: (context) => getIt<ScanBloc>(),
        ),
        BlocProvider<ConnectivityBloc>(
          // --- Use CORRECT Event Name ---
          create: (context) => getIt<ConnectivityBloc>()..add(ConnectivityStartMonitoring()), // Use the correct event name
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'PWD Verification App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // --- Use String Literals for Routes ---
        // Use '/' which maps to SplashScreen in your AppRouter
        initialRoute: '/', // Use the actual string route name for splash
        // Use the AppRouter class directly via the 'routes' alias
        onGenerateRoute: routes.AppRouter.generateRoute,
      ),
    );
  }
}