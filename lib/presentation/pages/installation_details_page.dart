import 'package:flutter/material.dart';
import '../../data/models/fve_installation.dart';

class InstallationDetailsPage extends StatelessWidget {
  final FVEInstallation installation;

  const InstallationDetailsPage({
    super.key,
    required this.installation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(installation.name),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: installation.requiredPhotos.length,
        itemBuilder: (context, index) {
          final photo = installation.requiredPhotos[index];
          return Card(
            child: ListTile(
              title: Text(photo),
              trailing: const Icon(Icons.camera_alt),
              onTap: () {
                // TODO: Implement photo capture functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Take photo: $photo'),
                    action: SnackBarAction(
                      label: 'Take Photo',
                      onPressed: () {
                        // TODO: Implement photo capture
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 