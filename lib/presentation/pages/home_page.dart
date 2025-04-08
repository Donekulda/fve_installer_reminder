import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../data/models/fve_installation.dart';
import 'installation_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadInstallations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FVE Installations'),
        actions: [
          if (context.watch<AppState>().isPrivileged)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.pushNamed(context, '/users');
              },
            ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.installations.isEmpty) {
            return const Center(
              child: Text('No installations found'),
            );
          }

          return ListView.builder(
            itemCount: appState.installations.length,
            itemBuilder: (context, index) {
              final installation = appState.installations[index];
              return ListTile(
                title: Text(installation.name),
                subtitle: Text(installation.address),
                trailing: Text(
                  '${installation.requiredPhotos.length} photos',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstallationDetailsPage(
                        installation: installation,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInstallationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddInstallationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Installation'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Installation Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter installation name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final installation = FVEInstallation(
                id: 0, // Will be set by the database
                name: nameController.text,
                address: addressController.text,
                installationDate: DateTime.now(),
                requiredPhotos: [
                  'Front view',
                  'Side view',
                  'Back view',
                  'Close-up of connections',
                ],
              );

              await context.read<AppState>().addInstallation(installation);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 