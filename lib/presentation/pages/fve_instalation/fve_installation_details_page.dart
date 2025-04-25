import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../data/models/fve_installation.dart';
import '../../../core/utils/logger.dart';
import 'fve_instalation_controller.dart';

class InstallationDetailsPage extends StatefulWidget {
  final FVEInstallation installation;

  const InstallationDetailsPage({super.key, required this.installation});

  @override
  State<InstallationDetailsPage> createState() =>
      _InstallationDetailsPageState();
}

class _InstallationDetailsPageState extends State<InstallationDetailsPage> {
  late FVEInstallationController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = FVEInstallationController(context, widget.installation);
  }

  @override
  Widget build(BuildContext context) {
    try {
      AppLogger.debug('InstallationDetailsPage building');
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.installation.name ?? translate('fve.unnamed')),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _controller.showEditInstallationDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _controller.showDeleteConfirmationDialog,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    title: translate('fve.installationName'),
                    value: widget.installation.name ?? translate('fve.unnamed'),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    title: translate('fve.region'),
                    value:
                        widget.installation.region ?? translate('fve.noRegion'),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    title: translate('fve.address'),
                    value:
                        widget.installation.address ??
                        translate('fve.noAddress'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building InstallationDetailsPage', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error loading installation details: $e')),
      );
    }
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
