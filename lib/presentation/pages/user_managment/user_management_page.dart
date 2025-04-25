import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/user.dart';
import '../../widgets/language_selector.dart';
import '../../../core/utils/logger.dart';
import 'user_controller.dart';

/// A page that displays and manages user accounts in the system.
///
/// This page provides functionality to:
/// - View a list of all users
/// - Add new users
/// - Edit existing users
/// - Activate/deactivate user accounts
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
    await _userController.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    try {
      _logger.debug('UserManagementPage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(translate('userManagement.title')),
          actions: const [LanguageSelector()],
        ),
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

  /// Builds a single user list item with edit and activate/deactivate actions
  ///
  /// [user] The user object to display
  Widget _buildUserListItem(dynamic user) {
    try {
      return ListTile(
        title: Text(user.username),
        subtitle: Text(
          user.isPrivileged
              ? translate('userManagement.privileged')
              : translate('userManagement.regular'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditUserDialog(context, user),
            ),
            IconButton(
              icon: Icon(user.active ? Icons.block : Icons.check_circle),
              onPressed: () => _showActivateDeactivateDialog(context, user),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building user list item', e, stackTrace);
      return const ListTile(title: Text('Error loading user'));
    }
  }

  /// Shows a dialog for adding a new user
  ///
  /// [context] The build context
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
                        DropdownButtonFormField<int>(
                          value: privileges,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.privileges'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(translate('userManagement.visitor')),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                translate('userManagement.regularUser'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                translate('userManagement.installer'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                translate('userManagement.administrator'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => privileges = value ?? 0);
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

                        await _userController.addUser(user);
                        if (mounted) {
                          Navigator.pop(context);
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
  Future<void> _showEditUserDialog(BuildContext context, User user) async {
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
                            labelText: translate('userManagement.newPassword'),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
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
                        DropdownButtonFormField<int>(
                          value: privileges,
                          decoration: InputDecoration(
                            labelText: translate('userManagement.privileges'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(translate('userManagement.visitor')),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                translate('userManagement.regularUser'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                translate('userManagement.installer'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                translate('userManagement.administrator'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => privileges = value ?? 0);
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

                        final updatedUser = User(
                          id: user.id,
                          username: usernameController.text,
                          password:
                              passwordController.text.isEmpty
                                  ? user.password
                                  : passwordController.text,
                          fullname: fullnameController.text,
                          privileges: privileges,
                          active: user.active,
                        );

                        await _userController.handleUserAction(
                          'edit',
                          user.id.toString(),
                          newPrivilege: privileges,
                        );
                        await _userController.updateUser(updatedUser);
                        if (mounted) {
                          Navigator.pop(context);
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
                  if (user.active) {
                    await _userController.deactivateUser(user.id);
                  } else {
                    await _userController.activateUser(user.id);
                  }
                  if (mounted) {
                    Navigator.pop(context);
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
