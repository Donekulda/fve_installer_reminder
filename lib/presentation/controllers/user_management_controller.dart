import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../data/models/user.dart';
import '../../core/utils/logger.dart';

/// Controller class responsible for managing user-related operations.
/// This class handles all business logic related to user management,
/// including loading, adding, updating, and activating/deactivating users.
class UserController {
  /// The BuildContext used to access the app state and show snackbars
  final BuildContext context;

  /// Logger instance for tracking operations and errors
  final _logger = AppLogger('UserController');

  /// Creates a new UserController instance
  ///
  /// [context] The BuildContext used to access the app state
  UserController(this.context);

  /// Loads all users from the app state
  ///
  /// This method attempts to load users and handles any errors that occur
  /// during the loading process. If an error occurs, it shows a snackbar
  /// with an error message.
  Future<void> loadUsers() async {
    try {
      _logger.debug('Loading users');
      await context.read<AppState>().loadUsers();
      _logger.info('Users loaded successfully');
    } catch (e, stackTrace) {
      _logger.error('Error loading users', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.loadingUsersError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handles user-related actions such as editing privileges
  ///
  /// [action] The type of action to perform (e.g., 'edit')
  /// [userId] The ID of the user to perform the action on
  /// [newPrivilege] Optional new privilege level to set for the user
  Future<void> handleUserAction(
    String action,
    String userId, {
    int? newPrivilege,
  }) async {
    try {
      _logger.debug('User action started: $action for user $userId');
      switch (action) {
        case 'edit':
          if (newPrivilege != null) {
            final user = context.read<AppState>().users.firstWhere(
              (u) => u.id.toString() == userId,
            );
            final updatedUser = User(
              id: user.id,
              username: user.username,
              password: user.password,
              fullname: user.fullname,
              privileges: newPrivilege,
              active: user.active,
            );
            await context.read<AppState>().updateUser(updatedUser);
            _logger.info('User privileges updated successfully');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(translate('userManagement.privilegesUpdated')),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
          break;
        default:
          _logger.warning('Unknown user action: $action');
      }
    } catch (e, stackTrace) {
      _logger.error('Error performing user action', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.userActionError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Adds a new user to the system
  ///
  /// [user] The User object containing the new user's information
  ///
  /// This method attempts to add the user and handles any errors that occur
  /// during the process. If an error occurs, it shows a snackbar with an
  /// error message.
  Future<void> addUser(User user) async {
    try {
      await context.read<AppState>().addUser(user);
      _logger.info('User added successfully');
    } catch (e, stackTrace) {
      _logger.error('Error adding user', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.addUserError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Updates an existing user's information
  ///
  /// [user] The User object containing the updated user information
  ///
  /// This method attempts to update the user and handles any errors that occur
  /// during the process. If an error occurs, it shows a snackbar with an
  /// error message.
  Future<void> updateUser(User user) async {
    try {
      await context.read<AppState>().updateUser(user);
      _logger.info('User updated successfully');
    } catch (e, stackTrace) {
      _logger.error('Error updating user', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.updateUserError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Activates a user account
  ///
  /// [userId] The ID of the user to activate
  ///
  /// This method attempts to activate the user and handles any errors that occur
  /// during the process. If an error occurs, it shows a snackbar with an
  /// error message.
  Future<void> activateUser(int userId) async {
    try {
      await context.read<AppState>().activateUser(userId);
      _logger.info('User activated successfully');
    } catch (e, stackTrace) {
      _logger.error('Error activating user', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.activateUserError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Deactivates a user account
  ///
  /// [userId] The ID of the user to deactivate
  ///
  /// This method attempts to deactivate the user and handles any errors that occur
  /// during the process. If an error occurs, it shows a snackbar with an
  /// error message.
  Future<void> deactivateUser(int userId) async {
    try {
      await context.read<AppState>().deactivateUser(userId);
      _logger.info('User deactivated successfully');
    } catch (e, stackTrace) {
      _logger.error('Error deactivating user', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.deactivateUserError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
