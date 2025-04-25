import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../state/app_state.dart';
import '../../../data/models/fve_installation.dart';
import '../../../data/models/required_image.dart';
import '../../../data/models/saved_image.dart';
import '../../../core/utils/logger.dart';
import '../../widgets/language_selector.dart';

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
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.installation.name ?? translate('fve.unnamed')),
          actions: const [LanguageSelector()],
        ),
        body: Consumer<AppState>(
          builder: (context, appState, child) {
            // Use currentLanguage to force rebuilds
            final currentLanguage = appState.currentLanguage;

            AppLogger.debug(
              'InstallationDetailsPage - Building with language: $currentLanguage',
            );

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstallationDetails(),
                  const SizedBox(height: 24),
                  _buildRequiredImages(),
                  const SizedBox(height: 24),
                  _buildSavedImages(),
                ],
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building InstallationDetailsPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading installation details: $e')),
      );
    }
  }

  Widget _buildInstallationDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('fve.installationName'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.installation.name ?? translate('fve.unnamed')),
            const SizedBox(height: 16),
            Text(
              translate('fve.region'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.installation.region ?? translate('fve.noRegion')),
            const SizedBox(height: 16),
            Text(
              translate('fve.address'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.installation.address ?? translate('fve.noAddress')),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredImages() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _requiredImages.length,
      itemBuilder: (context, index) {
        final requiredImage = _requiredImages[index];
        final savedImages =
            _savedImages
                .where((img) => img.requiredImageId == requiredImage.id)
                .toList();
        return Card(
          child: ListTile(
            title: Text(requiredImage.name ?? translate('fve.unnamed')),
            subtitle: Text('${savedImages.length} photos taken'),
            trailing: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _takePhoto(requiredImage),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedImages() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('fve.savedImages'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedImages.length,
              itemBuilder: (context, index) {
                final savedImage = _savedImages[index];
                return ListTile(
                  title: Text(savedImage.name ?? translate('fve.unnamed')),
                  subtitle: Text(savedImage.timeAdded?.toString() ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteImage(savedImage),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(RequiredImage requiredImage) async {
    // Implementation of _takePhoto method
  }

  Future<void> _deleteImage(SavedImage savedImage) async {
    // Implementation of _deleteImage method
  }
}
