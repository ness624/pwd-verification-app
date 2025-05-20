import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/di/service_locator.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_event.dart';
import 'package:pwd_verification_app/presentation/bloc/auth/auth_state.dart';
import 'package:pwd_verification_app/presentation/widgets/common/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _organizationTypeController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final AuthBloc _authBloc;

  final List<String> _organizationTypes = [
    'Restaurant',
    'Hotel',
    'Mall',
    'Transportation',
    'Government Office',
    'Public Establishment',
    'Private Establishment',
    'Other'
  ];

  String _selectedOrganizationType = 'Restaurant';

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _organizationTypeController.text = _selectedOrganizationType;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _organizationNameController.dispose();
    _organizationTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: BlocProvider.value(
        value: _authBloc,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              AppLogger.info('RegisterScreen', 'Registration successful: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                ),
              );
              // Navigate to login page after successful registration
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushReplacementNamed(context, '/login');
              });
            } else if (state is AuthFailure) {
              AppLogger.warning('RegisterScreen', 'Registration failed: ${state.message}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRegisterForm(context, isLoading),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
              helperText: 'Enter a valid email address (e.g. example@domain.com)',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          // Full Name field
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              helperText: 'Enter your complete name',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your full name';
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          // Phone Number field
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              helperText: 'Enter a valid 10-15 digit phone number',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your phone number';
              if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) return 'Please enter a valid phone number';
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          // Organization Name field
          TextFormField(
            controller: _organizationNameController,
            decoration: const InputDecoration(
              labelText: 'Organization Name',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
              helperText: 'Enter the full name of your organization',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your organization name';
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          // Organization Type dropdown
          DropdownButtonFormField<String>(
            value: _selectedOrganizationType,
            decoration: const InputDecoration(
              labelText: 'Organization Type',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
              helperText: 'Select your organization type',
            ),
            items: _organizationTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: isLoading ? null : (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedOrganizationType = newValue;
                  _organizationTypeController.text = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please select an organization type';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              helperText: 'Minimum 10 characters with 1 uppercase letter, 1 number, and 1 symbol',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 10) {
                return 'Password must be at least 10 characters';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Password must contain at least one uppercase letter';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Password must contain at least one number';
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Password must contain at least one symbol';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              helperText: 'Retype your password to confirm',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) {
              if (!isLoading) _attemptRegister(context);
            },
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),

          // Register button
          AppButton(
            label: isLoading ? 'Registering...' : 'Register',
            onPressed: isLoading ? () {} : () => _attemptRegister(context),
            icon: isLoading ? null : Icons.app_registration,
          ),
          const SizedBox(height: 16),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?'),
              TextButton(
                onPressed: isLoading ? null : () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _attemptRegister(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        RegisterEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          organizationName: _organizationNameController.text.trim(),
          organizationType: _organizationTypeController.text.trim(),
        ),
      );
    }
  }
} 