import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_storage_service.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';

class IceContactScreen extends StatefulWidget {
  const IceContactScreen({super.key});

  @override
  State<IceContactScreen> createState() => _IceContactScreenState();
}

class _IceContactScreenState extends State<IceContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _showOnLockScreen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = LocalStorageService().getAppSettings();
    _nameController = TextEditingController(text: settings.iceContactName);
    _phoneController = TextEditingController(text: settings.iceContactPhone);
    _showOnLockScreen = settings.showIceOnLockScreen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = LocalStorageService().getAppSettings();
      settings.iceContactName = _nameController.text.trim();
      settings.iceContactPhone = _phoneController.text.trim();
      settings.showIceOnLockScreen = _showOnLockScreen;

      await LocalStorageService().saveAppSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ICE Contact updated')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Emergency Contact (ICE)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.contact_emergency,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'In Case of Emergency',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This contact information can be displayed on your lock screen widget for emergency responders.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contact Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Contact Name',
                    hintText: 'e.g., Jane Doe',
                    filled: true,
                    fillColor: theme.colorScheme.surface.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +1 234 567 8900',
                    filled: true,
                    fillColor: theme.colorScheme.surface.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    title: const Text('Show on Lock Screen Widget'),
                    subtitle: const Text(
                      'Information will be partially redacted for privacy (e.g., ICE: ***-***-1234 • J***).',
                    ),
                    value: _showOnLockScreen,
                    onChanged: (value) {
                      setState(() {
                        _showOnLockScreen = value;
                      });
                    },
                    secondary: const Icon(Icons.lock_clock),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: _isLoading ? 'Saving...' : 'Save Configuration',
                    icon: Icons.save,
                    onPressed: _isLoading ? null : _save,
                    isProminent: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
