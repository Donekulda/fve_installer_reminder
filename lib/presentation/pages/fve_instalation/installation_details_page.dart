import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../../../data/models/required_image.dart';
import '../../../data/models/saved_image.dart';

class InstallationDetailsPage extends StatefulWidget {
  final FVEInstallation installation;

  const InstallationDetailsPage({super.key, required this.installation});

  @override
  State<InstallationDetailsPage> createState() =>
      _InstallationDetailsPageState();
}

class _InstallationDetailsPageState extends State<InstallationDetailsPage> {
  List<RequiredImage> _requiredImages = [];
  List<SavedImage> _savedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      _requiredImages = await appState.databaseService.getAllRequiredImages();
      _savedImages = await appState.databaseService
          .getSavedImagesByInstallationId(widget.installation.id);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.installation.name ?? 'Installation Details'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _requiredImages.length,
                itemBuilder: (context, index) {
                  final requiredImage = _requiredImages[index];
                  final savedImages =
                      _savedImages
                          .where(
                            (img) => img.requiredImageId == requiredImage.id,
                          )
                          .toList();
                  return Card(
                    child: ListTile(
                      title: Text(requiredImage.name ?? 'Unnamed Type'),
                      subtitle: Text('${savedImages.length} photos taken'),
                      trailing: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _takePhoto(requiredImage),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _takePhoto(RequiredImage requiredImage) async {
    // TODO: Implement photo capture functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Take photo: ${requiredImage.name}'),
        action: SnackBarAction(
          label: 'Take Photo',
          onPressed: () {
            // TODO: Implement photo capture
          },
        ),
      ),
    );
  }
}
