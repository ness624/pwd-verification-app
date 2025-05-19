import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:pwd_verification_app/core/utils/logger.dart';
// Import AuthBloc and its states
import 'package:pwd_verification_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_state.dart'; // Use your prefixed state if needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // Use super.key

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Slightly faster animation
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // No fixed delay navigation here anymore. Navigation will be handled by BlocListener.
    // The AuthBloc's CheckAuthStatusEvent is dispatched from main.dart
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // This method is no longer directly called by a timer
  // void _navigateToNextScreen(String routeName) {
  //   if (mounted) { // Check if the widget is still in the tree
  //     Navigator.of(context).pushReplacementNamed(routeName);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use BlocListener to react to AuthState changes and navigate
      body: BlocListener<AuthBloc, AuthState>( // Use local_auth_state.AuthState if you have the prefix
        listener: (context, state) {
          AppLogger.info('SplashScreen', 'AuthBloc state changed: $state');
          // Add a small delay after animation completes before navigating,
          // or navigate immediately based on state.
          // For a smoother experience, wait for animation.
          _animationController.addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (mounted) { // Check if mounted before navigating
                if (state is AuthAuthenticated) {
                  AppLogger.info('SplashScreen', 'User Authenticated. Navigating to /home.');
                  Navigator.of(context).pushReplacementNamed('/home');
                } else if (state is AuthUnauthenticated) {
                  AppLogger.info('SplashScreen', 'User Unauthenticated. Navigating to /login.');
                  Navigator.of(context).pushReplacementNamed('/login');
                } else if (state is AuthFailure) {
                  AppLogger.warning('SplashScreen', 'AuthFailure during splash. Navigating to /login. Error: ${state.message}');
                  // Navigate to login on failure as well, LoginScreen can show error
                  Navigator.of(context).pushReplacementNamed('/login');
                }
                // If AuthLoading or AuthInitial, we just show the splash UI until a definitive state is reached.
              }
            }
          });
          // If animation is already completed when state changes, navigate immediately
           if (_animationController.status == AnimationStatus.completed) {
               if (mounted) {
                 if (state is AuthAuthenticated) {
                   AppLogger.info('SplashScreen', 'User Authenticated (animation done). Navigating to /home.');
                   Navigator.of(context).pushReplacementNamed('/home');
                 } else if (state is AuthUnauthenticated) {
                   AppLogger.info('SplashScreen', 'User Unauthenticated (animation done). Navigating to /login.');
                   Navigator.of(context).pushReplacementNamed('/login');
                 } else if (state is AuthFailure) {
                   AppLogger.warning('SplashScreen', 'AuthFailure (animation done). Navigating to /login.');
                   Navigator.of(context).pushReplacementNamed('/login');
                 }
               }
           }
        },
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded, // Changed icon slightly
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'PWD Verification',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Removed "Development Mode" text as it's now a real flow
                // const SizedBox(height: 48),
                Padding( // Added padding for loader
                  padding: const EdgeInsets.only(top: 48.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}