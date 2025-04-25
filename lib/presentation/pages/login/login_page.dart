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

  @override
  void initState() {
    super.initState();
    AppLogger.debug('LoginPage initialized');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    AppLogger.debug('LoginPage disposed');
    super.dispose();
  }

  Future<void> _login() async {
    try {
      AppLogger.debug('Login attempt started');
      if (!_formKey.currentState!.validate()) {
        AppLogger.warning('Login form validation failed');
        return;
      }

      setState(() => _isLoading = true);
      AppLogger.debug('Login attempt in progress');

      try {
        final success = await context.read<AppState>().login(
          _usernameController.text,
          _passwordController.text,
        );

        if (!mounted) {
          AppLogger.warning(
            'Login attempt completed but widget is no longer mounted',
          );
          return;
        }

        if (!success) {
          AppLogger.warning('Login attempt failed');
          _showErrorSnackBar(translate('auth.loginError'));
        } else {
          AppLogger.info('Login successful');
        }
      } catch (e, stackTrace) {
        AppLogger.error('Login attempt failed with error', e, stackTrace);
        if (mounted) {
          _showErrorSnackBar(translate('auth.loginError'));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          AppLogger.debug('Login attempt completed');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in login process', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar(translate('auth.loginError'));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error showing error snackbar', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      AppLogger.debug('LoginPage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(translate('app.title')),
          actions: const [LanguageSelector()],
        ),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            // Use currentLanguage to force rebuilds
            final currentLanguage = appState.currentLanguage;

            AppLogger.debug(
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
      AppLogger.error('Error building LoginPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading login page: $e')),
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
            AppLogger.debug('Username validation failed: empty value');
            return translate('error.usernameNull');
          }
          return null;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building username field', e, stackTrace);
      return const Text('Error loading username field');
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
            AppLogger.debug('Password validation failed: empty value');
            return translate('error.passwordNull');
          }
          return null;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building password field', e, stackTrace);
      return const Text('Error loading password field');
    }
  }

  Widget _buildLoginButton() {
    try {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child:
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(translate('auth.login')),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building login button', e, stackTrace);
      return const Text('Error loading login button');
    }
  }
}
