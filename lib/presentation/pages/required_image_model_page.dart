import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../state/app_state.dart';
import '../../data/models/required_image.dart';
import '../controllers/required_image_model_controller.dart';
import '../widgets/app_top_bar.dart';
import '../../core/utils/logger.dart';

/// Page for managing required image models in the application.
/// This page allows administrators to define what types of images
/// are required for FVE installations.
class RequiredImageModelPage extends StatefulWidget {
  const RequiredImageModelPage({super.key});

  @override
  State<RequiredImageModelPage> createState() => _RequiredImageModelPageState();
}

class _RequiredImageModelPageState extends State<RequiredImageModelPage> {
  late RequiredImageModelController _controller;
  late final AppLogger _logger;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minImagesController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<RequiredImage> _requiredImages = [];
  bool _isLoading = false;
  RequiredImage? _editingImage;

  @override
  void initState() {
    super.initState();
    _logger = AppLogger('RequiredImageModelPage');
    _controller = RequiredImageModelController(context.read<AppState>());
    _loadRequiredImages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minImagesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRequiredImages() async {
    setState(() => _isLoading = true);
    try {
      _logger.info('Loading required image models');
      final images = await _controller.loadRequiredImageModels();
      setState(() {
        _requiredImages = images;
        _isLoading = false;
      });
      _logger.info(
        'Successfully loaded ${images.length} required image models',
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to load required image models', e, stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('common.error_loading_data'))),
        );
      }
    }
  }

  void _startEditing(RequiredImage image) {
    try {
      _logger.info('Starting edit for image model: ${image.id}');
      setState(() {
        _editingImage = image;
        _nameController.text = image.name ?? '';
        _minImagesController.text = image.minImages.toString();
        _descriptionController.text = image.description ?? '';
      });
    } catch (e, stackTrace) {
      _logger.error('Error while preparing edit form', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('common.error_loading_data'))),
      );
    }
  }

  void _cancelEditing() {
    try {
      _logger.info('Canceling edit operation');
      setState(() {
        _editingImage = null;
        _nameController.clear();
        _minImagesController.clear();
        _descriptionController.clear();
      });
    } catch (e, stackTrace) {
      _logger.error('Error while canceling edit', e, stackTrace);
    }
  }

  Future<void> _saveRequiredImage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        _logger.info('Saving required image model');
        if (_editingImage != null) {
          _logger.info('Updating existing image model: ${_editingImage!.id}');
          await _controller.updateRequiredImageModel(
            _editingImage!.id,
            _nameController.text,
            int.parse(_minImagesController.text),
            _descriptionController.text,
          );
        } else {
          _logger.info('Creating new image model');
          await _controller.addRequiredImageModel(
            _nameController.text,
            int.parse(_minImagesController.text),
            _descriptionController.text,
          );
        }
        _logger.info('Successfully saved required image model');
        _cancelEditing();
        await _loadRequiredImages();
      } catch (e, stackTrace) {
        _logger.error('Failed to save required image model', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translate('common.error_saving_data'))),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRequiredImage(RequiredImage image) async {
    try {
      _logger.info('Initiating delete operation for image model: ${image.id}');
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(translate('common.confirm_delete')),
              content: Text(
                translate('required_images.management.delete_confirm'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(translate('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(translate('common.confirm')),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          _logger.info('Deleting image model: ${image.id}');
          await _controller.deleteRequiredImageModel(image.id);
          _logger.info('Successfully deleted image model: ${image.id}');
          await _loadRequiredImages();
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to delete image model: ${image.id}',
            e,
            stackTrace,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(translate('common.error_deleting_data'))),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        _logger.info('Delete operation cancelled by user');
      }
    } catch (e, stackTrace) {
      _logger.error('Error in delete operation', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('common.error_deleting_data'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          // Check if user has admin privileges
          if (!_controller.isAdmin) {
            return Center(child: Text(translate('common.unauthorized')));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translate('required_images.management.title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                // Form for adding/editing required image model
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: translate(
                            'required_images.management.name',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return translate(
                              'required_images.management.name_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minImagesController,
                        decoration: InputDecoration(
                          labelText: translate(
                            'required_images.management.min_images',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return translate(
                              'required_images.management.min_images_required',
                            );
                          }
                          if (int.tryParse(value) == null) {
                            return translate(
                              'required_images.management.min_images_invalid',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: translate(
                            'required_images.management.description',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return translate(
                              'required_images.management.description_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveRequiredImage,
                              child: Text(
                                _editingImage != null
                                    ? translate('common.save')
                                    : translate(
                                      'required_images.management.add',
                                    ),
                              ),
                            ),
                          ),
                          if (_editingImage != null) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _cancelEditing,
                                child: Text(translate('common.cancel')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // List of required image models
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            itemCount: _requiredImages.length,
                            itemBuilder: (context, index) {
                              final image = _requiredImages[index];
                              return Card(
                                child: ListTile(
                                  title: Text(image.name ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        translate(
                                          'required_images.management.min_images_count',
                                          args: {
                                            'count': image.minImages.toString(),
                                          },
                                        ),
                                      ),
                                      if (image.description != null)
                                        Text(
                                          image.description!,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _startEditing(image),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            () => _deleteRequiredImage(image),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
