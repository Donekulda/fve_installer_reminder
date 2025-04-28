import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../core/utils/logger.dart';

/// A controller class that manages the login functionality and form state.
/// Handles user authentication, form validation, and error handling.
class LoginController {
  /// Controller for managing the username input field
  final TextEditingController usernameController = TextEditingController();

  /// Controller for managing the password input field
  final TextEditingController passwordController = TextEditingController();

  /// Logger instance for tracking login-related events
  final _logger = AppLogger('LoginController');

  /// Flag indicating whether a login attempt is in progress
  bool isLoading = false;

  /// Cleans up resources when the controller is no longer needed.
  /// Disposes of text controllers to prevent memory leaks.
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _logger.debug('LoginController disposed');
  }

  /// Handles the login process when the user submits the form.
  ///
  /// This method:
  /// 1. Sets loading state to true
  /// 2. Attempts to log in using AppState
  /// 3. Handles success/failure cases
  /// 4. Shows appropriate error messages
  /// 5. Resets loading state when done
  ///
  /// Returns [true] if login was successful, [false] otherwise.
  Future<bool> handleLogin(BuildContext context) async {
    try {
      _logger.debug('Login attempt started');
      _logger.debug('Username: ${usernameController.text}');
      _logger.debug('Password length: ${passwordController.text.length}');
      isLoading = true;

      try {
        // Attempt to log in using AppState
        _logger.debug('Calling AppState.login()');
        final success = await context.read<AppState>().login(
          usernameController.text,
          passwordController.text,
        );

        if (!success) {
          _logger.warning('Login attempt failed - Invalid credentials');
          if (context.mounted) {
            _showErrorSnackBar(context, translate('auth.loginError'));
          }
          return false;
        }

        _logger.info('Login successful');
        return true;
      } catch (e, stackTrace) {
        _logger.error('Login attempt failed with error', e, stackTrace);
        if (context.mounted) {
          _showErrorSnackBar(context, translate('auth.loginError'));
        }
        return false;
      } finally {
        isLoading = false;
        _logger.debug('Login attempt completed');
      }
    } catch (e, stackTrace) {
      _logger.error('Unexpected error in login process', e, stackTrace);
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'An unexpected error occurred during login',
        );
      }
      return false;
    }
  }

  /// Displays an error message to the user using a SnackBar.
  ///
  /// The message is shown for 3 seconds and includes error logging.
  ///
  /// [context] - The build context for showing the SnackBar
  /// [message] - The error message to display
  void _showErrorSnackBar(BuildContext context, String message) {
    try {
      _logger.debug('Showing error snackbar: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } catch (e, stackTrace) {
      _logger.error('Error showing error snackbar', e, stackTrace);
    }
  }

  /// Validates the username input field.
  ///
  /// Returns:
  /// - [null] if the username is valid
  /// - An error message string if the username is invalid
  ///
  /// [value] - The username value to validate
  String? validateUsername(String? value) {
    _logger.debug('Validating username: ${value ?? 'null'}');
    if (value == null || value.isEmpty) {
      _logger.debug('Username validation failed: empty value');
      return translate('error.usernameNull');
    }
    _logger.debug('Username validation passed');
    return null;
  }

  /// Validates the password input field.
  ///
  /// Returns:
  /// - [null] if the password is valid
  /// - An error message string if the password is invalid
  ///
  /// [value] - The password value to validate
  String? validatePassword(String? value) {
    _logger.debug(
      'Validating password: ${value != null ? '${value.length} characters' : 'null'}',
    );
    if (value == null || value.isEmpty) {
      _logger.debug('Password validation failed: empty value');
      return translate('error.passwordNull');
    }
    _logger.debug('Password validation passed');
    return null;
  }
}
