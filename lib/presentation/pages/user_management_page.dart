import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../data/models/user.dart';
import '../widgets/app_top_bar.dart';
import '../../core/utils/logger.dart';
import '../../core/config/config.dart';
import '../controllers/user_management_controller.dart';

/// A page that displays and manages user accounts in the system.
///
/// This page provides functionality to:
/// - View a list of all users
/// - Add new users
/// - Edit existing users
/// - Activate/deactivate user accounts
/// - Manage user privileges based on role hierarchy
/// - Securely view user passwords with admin authentication
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  /// Logger instance for tracking page lifecycle and errors
  final _logger = AppLogger('UserManagementPage');

  /// Controller instance for handling user-related operations
  late UserController _userController;

  @override
  void initState() {
    super.initState();
    _logger.debug('UserManagementPage initialized');
    _userController = UserController(context);
    _loadUsers();
  }

  @override
  void dispose() {
    _logger.debug('UserManagementPage disposed');
    super.dispose();
  }

  /// Loads the initial list of users when the page is opened
  Future<void> _loadUsers() async {
    try {
      await _userController.loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('UserManagementPage building');
      return Scaffold(
        appBar: const AppTopBar(),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          child: const Icon(Icons.add),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building UserManagementPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading user management page: $e')),
      );
    }
  }

  /// Builds the main content of the page
  ///
  /// This method creates a list view of users if there are any,
  /// or displays appropriate messages if the list is empty or loading.
  Widget _buildBody() {
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final currentLanguage = appState.currentLanguage;

          _logger.debug(
            'Building user list with ${appState.users.length} users, language: $currentLanguage',
          );

          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.users.isEmpty) {
            return Center(child: Text(translate('common.noUsers')));
          }

          return ListView.builder(
            itemCount: appState.users.length,
            itemBuilder: (context, index) {
              final user = appState.users[index];
              return _buildUserListItem(user);
            },
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error building user list', e, stackTrace);
      return Center(child: Text('Error loading user list: $e'));
    }
  }

  /// Shows a dialog to confirm admin/superAdmin password before viewing user password
  ///
  /// [context] The build context
  /// [user] The user whose password is being viewed
  ///
  /// This method implements a security measure requiring admin/superAdmin
  /// to authenticate before viewing another user's password.
  Future<void> _showPasswordConfirmationDialog(
    BuildContext context,
    User user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(translate('userManagement.confirmPassword')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translate('userManagement.confirmPasswordMessage')),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: translate('userManagement.password'),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate('error.passwordNull');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  // Verify the current user's password
                  final currentUser = context.read<AppState>().currentUser;
                  if (currentUser?.password == passwordController.text) {
                    Navigator.pop(context);
                    _showUserPasswordDialog(context, user);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translate('error.invalidPassword')),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Text(translate('common.confirm')),
              ),
            ],
          ),
    );
  }

  /// Shows a dialog displaying the user's password
  ///
  /// [context] The build context
  /// [user] The user whose password is being displayed
  ///
  /// This method displays the user's password in a clear, formatted way
  /// after successful authentication.
  Future<void> _showUserPasswordDialog(BuildContext context, User user) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(translate('userManagement.userPassword')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(translate('userManagement.username')),
                Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(translate('userManagement.password')),
                Text(
                  user.password,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate('common.close')),
              ),
            ],
          ),
    );
  }

  /// Builds a single user list item with edit and activate/deactivate actions
  ///
  /// [user] The user object to display
  ///
  /// This method handles the following privilege rules:
  /// - SuperAdmin can edit any user and change their privileges (except own)
  /// - Admin can edit users with lower privileges and change their privileges
  /// - Users can edit their own profile but not their privileges
  /// - SuperAdmin can view any user's password
  /// - Admin can view passwords of users with lower privileges
  Widget _buildUserListItem(dynamic user) {
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final currentUser = appState.currentUser;
          final isSuperAdmin = appState.hasRequiredPrivilege('superAdmin');
          final isAdmin = appState.hasRequiredPrivilege('admin');

          // Determine if the current user can edit this user
          // SuperAdmin can edit anyone
          // Admin can edit users with lower privileges
          // Users can edit themselves
          final canEdit =
              isSuperAdmin ||
              (isAdmin && user.privileges < Config.privilegeLevels['admin']!) ||
              (currentUser?.id == user.id);

          // Determine if the current user can change privileges
          // Can't change own privileges
          // SuperAdmin can change anyone's privileges
          // Admin can change privileges of users with lower privileges
          final canChangePrivileges =
              (isSuperAdmin ||
                  (isAdmin &&
                      user.privileges < Config.privilegeLevels['admin']!)) &&
              currentUser?.id != user.id;

          // Determine if the current user can view the password
          // SuperAdmin can view any user's password
          // Admin can view passwords of users with lower privileges
          final canViewPassword =
              isSuperAdmin ||
              (isAdmin && user.privileges < Config.privilegeLevels['admin']!);

          return ListTile(
            title: Text(user.username),
            subtitle: Text(Config.getPrivilegeName(user.privileges)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canViewPassword)
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed:
                        () => _showPasswordConfirmationDialog(context, user),
                    tooltip: translate('userManagement.viewPassword'),
                  ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed:
                        () => _showEditUserDialog(
                          context,
                          user,
                          canChangePrivileges: canChangePrivileges,
                        ),
                  ),
                IconButton(
                  icon: Icon(user.active ? Icons.block : Icons.check_circle),
                  onPressed: () => _showActivateDeactivateDialog(context, user),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error building user list item', e, stackTrace);
      return const ListTile(title: Text('Error loading user'));
    }
  }

  /// Shows a dialog for adding a new user
  ///
  /// [context] The build context
  ///
  /// This method handles the process of adding a new user to the system.
  Future<void> _showAddUserDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullnameController = TextEditingController();
    int privileges = 0;

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(translate('userManagement.addUser')),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.username'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate('error.usernameNull');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.password'),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate('error.passwordNull');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: fullnameController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.fullName'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<AppState>(
                          builder: (context, appState, child) {
                            final isSuperAdmin = appState.hasRequiredPrivilege(
                              'superAdmin',
                            );
                            final isAdmin = appState.hasRequiredPrivilege(
                              'admin',
                            );

                            // Filter available privilege levels based on current user's privileges
                            final availablePrivileges =
                                Config.privilegeNames.entries.where((entry) {
                                  // SuperAdmin can assign any privilege
                                  if (isSuperAdmin) return true;
                                  // Admin can assign any privilege except admin
                                  if (isAdmin) {
                                    return entry.key <
                                        Config.privilegeLevels['admin']!;
                                  }
                                  // Others can't assign privileges
                                  return false;
                                }).toList();

                            // Ensure the current privilege value is valid
                            if (!availablePrivileges.any(
                              (entry) => entry.key == privileges,
                            )) {
                              // If current privilege is not available, set to the highest available privilege
                              privileges = availablePrivileges.last.key;
                            }

                            return DropdownButtonFormField<int>(
                              value: privileges,
                              decoration: InputDecoration(
                                labelText: translate(
                                  'userManagement.privileges',
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              items:
                                  availablePrivileges.map((entry) {
                                    return DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(
                                        translate(
                                          'userManagement.${entry.value}',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() => privileges = value ?? 0);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(translate('common.cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final user = User(
                          id: 0,
                          username: usernameController.text,
                          password: passwordController.text,
                          fullname: fullnameController.text,
                          privileges: privileges,
                          active: true,
                        );

                        final currentContext = context;
                        await _userController.addUser(user);
                        if (mounted && currentContext.mounted) {
                          Navigator.pop(currentContext);
                        }
                      },
                      child: Text(translate('common.add')),
                    ),
                  ],
                ),
          ),
    );
  }

  /// Shows a dialog for editing an existing user
  ///
  /// [context] The build context
  /// [user] The user to edit
  /// [canChangePrivileges] Whether the current user can change privileges
  ///
  /// This method handles the following privilege rules:
  /// - SuperAdmin can assign any privilege level
  /// - Admin can assign any privilege level except admin
  /// - Users cannot change their own privileges
  Future<void> _showEditUserDialog(
    BuildContext context,
    User user, {
    required bool canChangePrivileges,
  }) async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController();
    final fullnameController = TextEditingController(text: user.fullname);
    int privileges = user.privileges;

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(translate('userManagement.editUser')),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Username field
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.username'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return translate('error.usernameNull');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password field (optional for editing)
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.newPassword'),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        // Full name field
                        TextFormField(
                          controller: fullnameController,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.fullName'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Privilege selection or display
                        if (canChangePrivileges)
                          Consumer<AppState>(
                            builder: (context, appState, child) {
                              final isSuperAdmin = appState
                                  .hasRequiredPrivilege('superAdmin');
                              final isAdmin = appState.hasRequiredPrivilege(
                                'admin',
                              );

                              // Filter available privilege levels based on current user's privileges
                              final availablePrivileges =
                                  Config.privilegeNames.entries.where((entry) {
                                    // SuperAdmin can assign any privilege
                                    if (isSuperAdmin) return true;
                                    // Admin can assign any privilege except admin
                                    if (isAdmin) {
                                      return entry.key <
                                          Config.privilegeLevels['admin']!;
                                    }
                                    // Others can't assign privileges
                                    return false;
                                  }).toList();

                              // Ensure the current privilege value is valid
                              if (!availablePrivileges.any(
                                (entry) => entry.key == privileges,
                              )) {
                                // If current privilege is not available, set to the highest available privilege
                                privileges = availablePrivileges.last.key;
                              }

                              return DropdownButtonFormField<int>(
                                value: privileges,
                                decoration: InputDecoration(
                                  labelText: translate(
                                    'userManagement.privileges',
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                items:
                                    availablePrivileges.map((entry) {
                                      return DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(
                                          translate(
                                            'userManagement.${entry.value}',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() => privileges = value ?? 0);
                                },
                              );
                            },
                          )
                        else
                          // Display current privilege level if user can't change it
                          TextFormField(
                            enabled: false,
                            initialValue: translate(
                              'userManagement.${Config.getPrivilegeName(user.privileges)}',
                            ),
                            decoration: InputDecoration(
                              labelText: translate('userManagement.privileges'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(translate('common.cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Create updated user object
                        final updatedUser = User(
                          id: user.id,
                          username: usernameController.text,
                          password:
                              passwordController.text.isEmpty
                                  ? user.password
                                  : passwordController.text,
                          fullname: fullnameController.text,
                          privileges:
                              canChangePrivileges
                                  ? privileges
                                  : user.privileges,
                          active: user.active,
                        );

                        final currentContext = context;
                        // Only update privileges if user has permission
                        if (canChangePrivileges) {
                          await _userController.handleUserAction(
                            'edit',
                            user.id.toString(),
                            newPrivilege: privileges,
                          );
                        }
                        await _userController.updateUser(updatedUser);
                        if (mounted && currentContext.mounted) {
                          Navigator.pop(currentContext);
                        }
                      },
                      child: Text(translate('common.save')),
                    ),
                  ],
                ),
          ),
    );
  }

  /// Shows a confirmation dialog for activating or deactivating a user
  ///
  /// [context] The build context
  /// [user] The user to activate or deactivate
  ///
  /// This method handles the process of activating or deactivating a user in the system.
  Future<void> _showActivateDeactivateDialog(
    BuildContext context,
    User user,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              user.active
                  ? translate('userManagement.deactivateUser')
                  : translate('userManagement.activateUser'),
            ),
            content: Text(
              user.active
                  ? translate(
                    'userManagement.deactivateConfirm',
                    args: {'username': user.username},
                  )
                  : translate(
                    'userManagement.activateConfirm',
                    args: {'username': user.username},
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final currentContext = context;
                  if (user.active) {
                    await _userController.deactivateUser(user.id);
                  } else {
                    await _userController.activateUser(user.id);
                  }
                  if (mounted && currentContext.mounted) {
                    Navigator.pop(currentContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.active ? Colors.red : Colors.green,
                ),
                child: Text(
                  user.active
                      ? translate('userManagement.deactivate')
                      : translate('userManagement.activate'),
                ),
              ),
            ],
          ),
    );
  }
}
