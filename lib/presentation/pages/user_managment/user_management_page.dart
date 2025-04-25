import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/user.dart';
import '../../widgets/language_selector.dart';
import '../../../core/utils/logger.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.debug('UserManagementPage initialized');
    _loadUsers();
  }

  @override
  void dispose() {
    AppLogger.debug('UserManagementPage disposed');
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      AppLogger.debug('Loading users');
      await context.read<AppState>().loadUsers();
      AppLogger.info('Users loaded successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error loading users', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.loadingUsersError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleUserAction(
    String action,
    String userId, {
    int? newPrivilege,
  }) async {
    try {
      AppLogger.debug('User action started: $action for user $userId');
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
            AppLogger.info('User privileges updated successfully');
            if (mounted) {
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
          AppLogger.warning('Unknown user action: $action');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error performing user action', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('error.userActionError')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      AppLogger.debug('UserManagementPage building');
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
      AppLogger.error('Error building UserManagementPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading user management page: $e')),
      );
    }
  }

  Widget _buildBody() {
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          final currentLanguage = appState.currentLanguage;

          AppLogger.debug(
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
      AppLogger.error('Error building user list', e, stackTrace);
      return Center(child: Text('Error loading user list: $e'));
    }
  }

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
      AppLogger.error('Error building user list item', e, stackTrace);
      return const ListTile(title: Text('Error loading user'));
    }
  }

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

                        await context.read<AppState>().addUser(user);
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

                        await _handleUserAction(
                          'edit',
                          user.id.toString(),
                          newPrivilege: privileges,
                        );
                        await context.read<AppState>().updateUser(updatedUser);
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
                    await context.read<AppState>().deactivateUser(user.id);
                  } else {
                    await context.read<AppState>().activateUser(user.id);
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
