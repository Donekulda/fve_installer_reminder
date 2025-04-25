import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../widgets/language_selector.dart';
import '../../../core/utils/logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _logger = AppLogger('LoginPage');

  @override
  void initState() {
    super.initState();
    _logger.debug('LoginPage initialized');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _logger.debug('LoginPage disposed');
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try {
      _logger.debug('Login attempt started');
      if (!_formKey.currentState!.validate()) {
        _logger.warning('Login form validation failed');
        return;
      }

      _logger.debug('Login attempt in progress');
      setState(() => _isLoading = true);

      try {
        final success = await context.read<AppState>().login(
          _usernameController.text,
          _passwordController.text,
        );

        if (!mounted) {
          _logger.warning(
            'Login attempt completed but widget is no longer mounted',
          );
          return;
        }

        if (!success) {
          _logger.warning('Login attempt failed - Invalid credentials');
          _logger.warning('Login attempt failed');
          _showErrorSnackBar(translate('auth.loginError'));
        } else {
          _logger.info('Login successful');
        }
      } catch (e, stackTrace) {
        _logger.error('Login attempt failed with error', e, stackTrace);
        if (mounted) {
          _showErrorSnackBar(translate('auth.loginError'));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          _logger.debug('Login attempt completed');
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Unexpected error in login process', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred during login');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    try {
      _logger.debug('Showing error snackbar: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } catch (e, stackTrace) {
      _logger.error('Error showing error snackbar', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('LoginPage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(translate('app.title')),
          actions: const [LanguageSelector()],
        ),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        translate('app.title'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildUsernameField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
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

  Widget _buildUsernameField() {
    try {
      return TextFormField(
        controller: _usernameController,
        decoration: InputDecoration(
          labelText: translate('auth.username'),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            _logger.debug('Username validation failed: empty value');
            return translate('error.usernameNull');
          }
          return null;
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

  Widget _buildPasswordField() {
    try {
      return TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: translate('auth.password'),
          border: const OutlineInputBorder(),
        ),
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            _logger.debug('Password validation failed: empty value');
            return translate('error.passwordNull');
          }
          return null;
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

  Widget _buildLoginButton() {
    try {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          child:
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(translate('auth.login')),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building login button', e, stackTrace);
      return ElevatedButton(onPressed: null, child: const Text('Login'));
    }
  }
}
