import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/design/glass_card.dart';
import '../../widgets/design/responsive_center.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const ProfileSetupScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedSex = 'unspecified';
  DateTime? _selectedDob;

  final LocalStorageService _storageService = LocalStorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentTeal,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveProfile({bool skipped = false}) async {
    final profile = skipped
        ? UserProfile()
        : UserProfile(
            displayName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            sex: _selectedSex,
            dateOfBirth: _selectedDob,
          );

    await _storageService.saveUserProfile(profile);

    if (skipped) {
      await _analyticsService.logEvent('profile_skipped');
    } else {
      if (profile.displayName != null)
        await _analyticsService.logEvent('profile_name_set');
      if (_selectedSex != 'unspecified' || _selectedDob != null) {
        await _analyticsService.logEvent('profile_demographics_set');
      }
    }

    await _onboardingService.markStepCompleted(OnboardingStep.profile);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveCenter(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Personalize Your\nExperience',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Providing basic info helps us calibrate lab result ranges for your age and sex. All data stays local on your device.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLabel('Display Name (Optional)'),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g. John Doe'),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Sex (For medical reference ranges)'),
                        _buildSexSelection(),
                        const SizedBox(height: 24),
                        _buildLabel('Date of Birth'),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: AppTheme.accentTeal
                                        .withValues(alpha: 0.7),
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDob == null
                                      ? 'Select Date'
                                      : DateFormat('MMMM dd, yyyy')
                                          .format(_selectedDob!),
                                  style: TextStyle(
                                    color: _selectedDob == null
                                        ? Colors.white54
                                        : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildPrivacyNote(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            'Step 6 of 10',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accentTeal),
      ),
    );
  }

  Widget _buildSexSelection() {
    final options = [
      {'id': 'male', 'label': 'Male', 'icon': Icons.male},
      {'id': 'female', 'label': 'Female', 'icon': Icons.female},
      {
        'id': 'unspecified',
        'label': 'Prefer not to say',
        'icon': Icons.remove_circle_outline
      },
    ];

    return Wrap(
      spacing: 12,
      children: options.map((opt) {
        final isSelected = _selectedSex == opt['id'];
        return ChoiceChip(
          label: Text(opt['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedSex = opt['id'] as String);
          },
          avatar: Icon(
            opt['icon'] as IconData,
            size: 18,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: AppTheme.accentTeal.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? AppTheme.accentTeal
                : Colors.white.withValues(alpha: 0.1),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.healthGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.healthGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.privacy_tip_outlined,
              color: AppTheme.healthGreen, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'This info never leaves your device. It is used only for local calculations.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextButton(
            onPressed: () => _saveProfile(skipped: true),
            child: const Text('Skip for Now',
                style: TextStyle(color: Colors.white60)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Save & Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _saveProfile(),
              isProminent: true,
            ),
          ),
        ],
      ),
    );
  }
}
