import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../widgets/app_top_bar.dart';
import '../../core/utils/logger.dart';
import '../controllers/login_controller.dart';

/// A page that handles user authentication through a login form.
/// Provides username and password fields with validation and error handling.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form and input controllers
  final _formKey = GlobalKey<FormState>();
  final _controller = LoginController();
  final _logger = AppLogger('LoginPage');

  @override
  void initState() {
    super.initState();
    _logger.debug('LoginPage initialized');
  }

  @override
  void dispose() {
    _controller.dispose();
    _logger.debug('LoginPage disposed');
    super.dispose();
  }

  /// Handles the login process when the user submits the form
  /// Validates the form, attempts to log in, and handles success/failure
  Future<void> _handleLogin() async {
    try {
      _logger.debug('Login form submission started');
      _logger.debug('Username: ${_controller.usernameController.text}');
      _logger.debug(
        'Password length: ${_controller.passwordController.text.length}',
      );

      if (!_formKey.currentState!.validate()) {
        _logger.warning('Login form validation failed');
        return;
      }

      _logger.debug('Form validation passed, proceeding with login');
      setState(() {});
      await _controller.handleLogin(context);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logger.error('Error in _handleLogin', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('LoginPage building');
      return Scaffold(
        appBar: const AppTopBar(),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            // Use currentLanguage to force rebuilds
            final currentLanguage = appState.currentLanguage;

            _logger.debug(
              'LoginPage - Building with language: $currentLanguage',
            );

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  onChanged: () {
                    _logger.debug('Form changed - validating');
                    _formKey.currentState?.validate();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App title
                      Text(
                        translate('app.title'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Username field
                      _buildUsernameField(),
                      const SizedBox(height: 16),
                      // Password field
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      // Login button
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building LoginPage', e, stackTrace);
      return const Scaffold(
        body: Center(child: Text('Error loading login page')),
      );
    }
  }

  /// Builds the username input field with validation
  /// Returns a TextFormField with username validation
  Widget _buildUsernameField() {
    try {
      return TextFormField(
        controller: _controller.usernameController,
        decoration: InputDecoration(
          labelText: translate('auth.username'),
          border: const OutlineInputBorder(),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        validator: (value) {
          final error = _controller.validateUsername(value);
          if (error != null) {
            _logger.debug('Username validation error: $error');
          }
          return error;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error building username field', e, stackTrace);
      return const TextField(
        decoration: InputDecoration(
          labelText: 'Username',
          errorText: 'Error loading field',
        ),
      );
    }
  }

  /// Builds the password input field with validation
  /// Returns a TextFormField with password validation
  Widget _buildPasswordField() {
    try {
      return TextFormField(
        controller: _controller.passwordController,
        decoration: InputDecoration(
          labelText: translate('auth.password'),
          border: const OutlineInputBorder(),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        obscureText: true,
        validator: (value) {
          final error = _controller.validatePassword(value);
          if (error != null) {
            _logger.debug('Password validation error: $error');
          }
          return error;
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error building password field', e, stackTrace);
      return const TextField(
        decoration: InputDecoration(
          labelText: 'Password',
          errorText: 'Error loading field',
        ),
      );
    }
  }

  /// Builds the login button with loading state
  /// Returns an ElevatedButton that triggers the login process
  Widget _buildLoginButton() {
    try {
      return ElevatedButton(
        onPressed: () {
          _logger.debug('Login button pressed - direct callback');
          _handleLogin();
        },
        child: Text(translate('auth.login')),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building login button', e, stackTrace);
      return ElevatedButton(onPressed: null, child: const Text('Login'));
    }
  }
}
