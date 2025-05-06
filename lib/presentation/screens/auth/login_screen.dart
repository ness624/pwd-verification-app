import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/di/service_locator.dart';
// --- ADD IMPORTS ---
import 'package:pwd_verification_app/presentation/bloc/auth/auth_bloc.dart'; // Import BLoC
import 'package:pwd_verification_app/presentation/bloc/auth/auth_event.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_state.dart';
// --- END IMPORTS ---
import 'package:pwd_verification_app/presentation/widgets/common/app_button.dart'; // Assuming AppButton is defined here

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    // Initial check is now done in main.dart via MultiBlocProvider
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider.value(
        value: _authBloc,
        child: BlocConsumer<AuthBloc, AuthState>( // AuthBloc should be recognized
          listener: (context, state) { /* Keep listener logic as is */
            if (state is AuthAuthenticated) { AppLogger.info('LoginScreen', 'User authenticated, navigating to home'); Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false); }
            else if (state is AuthFailure) { AppLogger.warning('LoginScreen', 'Authentication failed: ${state.message}'); if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text(state.message), backgroundColor: Colors.red, duration: const Duration(seconds: 3), ), ); } }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading; // Determine loading state
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 48),
                          _buildLoginForm(context, isLoading), // Pass loading state
                        ],
                      ),
                    ),
                  ),
                ),
                 if (isLoading) Container( color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator()), ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() { /* Keep as is */
     return Column( children: [ Icon( Icons.qr_code_scanner, size: 80, color: Theme.of(context).primaryColor, ), const SizedBox(height: 16), Text( 'PWD Verification', style: Theme.of(context).textTheme.headlineMedium?.copyWith( fontWeight: FontWeight.bold, ), ), const SizedBox(height: 8), Text( 'Establishment Portal', style: Theme.of(context).textTheme.titleMedium?.copyWith( color: Colors.grey[600], ), ), ], );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField( controller: _emailController, decoration: const InputDecoration( labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(), ), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: (value) { if (value == null || value.isEmpty) return 'Please enter your email'; if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email'; return null; }, enabled: !isLoading, ),
          const SizedBox(height: 16),
          TextFormField( controller: _passwordController, decoration: InputDecoration( labelText: 'Password', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(), suffixIcon: IconButton( icon: Icon( _obscurePassword ? Icons.visibility : Icons.visibility_off, ), onPressed: () => setState(() => _obscurePassword = !_obscurePassword), ), ), obscureText: _obscurePassword, textInputAction: TextInputAction.done, validator: (value) { if (value == null || value.isEmpty) return 'Please enter your password'; return null; }, onFieldSubmitted: (_) { if (!isLoading) _attemptLogin(context); }, enabled: !isLoading, ),
          const SizedBox(height: 24),
          AppButton( // This line uses AppButton
            label: isLoading ? 'Logging In...' : 'Login',
            // The error might be here if AppButton doesn't accept null onPressed
            onPressed: isLoading ? () {} : () => _attemptLogin(context),
            icon: isLoading ? null : Icons.login,
          ),
          const SizedBox(height: 16),
          TextButton( onPressed: isLoading ? null : () { /* TODO: Implement forgot password */ }, child: const Text('Forgot Password?'), ),
        ],
      ),
    );
  }

  void _attemptLogin(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      // Ensure context.read<AuthBloc>() is correct if BlocProvider is used
      context.read<AuthBloc>().add(
        LoginEvent(_emailController.text.trim(), _passwordController.text),
      );
    }
  }
}