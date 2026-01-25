import 'package:flutter/material.dart';
import '../services/model_license_service.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/secure_logger.dart';
import 'package:intl/intl.dart';

class ModelLicenseScreen extends StatefulWidget {
  final String? initialModelId;

  const ModelLicenseScreen({super.key, this.initialModelId});

  @override
  State<ModelLicenseScreen> createState() => _ModelLicenseScreenState();
}

class _ModelLicenseScreenState extends State<ModelLicenseScreen> {
  final ModelLicenseService _licenseService = ModelLicenseService();
  final TextEditingController _searchController = TextEditingController();
  List<ModelLicense> _filteredLicenses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredLicenses = _licenseService.getAllLicenses();
    if (widget.initialModelId != null) {
      _searchQuery = widget.initialModelId!;
      _filterLicenses();
    }
  }

  void _filterLicenses() {
    setState(() {
      _filteredLicenses = _licenseService.searchLicenses(_searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Model Licenses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + DesignConstants.standardPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignConstants.pageHorizontalPadding),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterLicenses();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search models or licenses...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: theme.colorScheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filterLicenses();
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredLicenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No licenses found for "$_searchQuery"',
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        DesignConstants.pageHorizontalPadding,
                        0,
                        DesignConstants.pageHorizontalPadding,
                        DesignConstants.safeAreaPadding,
                      ),
                      itemCount: _filteredLicenses.length,
                      itemBuilder: (context, index) {
                        return _buildLicenseCard(_filteredLicenses[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(ModelLicense license) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        license.modelName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        license.licenseName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_for_offline, color: Colors.white70),
                  tooltip: 'Export Compliance Docs',
                  onPressed: () async {
                    try {
                      final path = await _licenseService.exportComplianceDocumentation(license);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exported to: ${path.split('/').last}'),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Export failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Plain Language Summary'),
            Text(
              license.plainLanguageSummary,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Key Restrictions'),
            ...license.keyRestrictions.map((r) => _buildBulletPoint(r)),
            const SizedBox(height: 16),
            _buildSectionTitle('Attribution Requirements'),
            ...license.attributionRequirements.map((a) => _buildBulletPoint(a)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Reviewed: ${DateFormat.yMMMd().format(license.lastReviewed)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
                ),
                TextButton(
                  onPressed: () => _showFullLicense(license),
                  child: const Text('View Full License'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: Colors.white54),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullLicense(ModelLicense license) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Full License Text',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      license.fullText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
