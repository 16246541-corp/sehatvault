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
  int? _selectedYear;

  final List<String> _adjectives = [
    'Swift',
    'Mighty',
    'Brave',
    'Silver',
    'Golden',
    'Neon',
    'Arctic',
    'Silent',
    'Wild',
    'Shadow'
  ];
  final List<String> _nouns = [
    'Falcon',
    'Wolf',
    'Panda',
    'Tiger',
    'Eagle',
    'Knight',
    'Ranger',
    'Striker',
    'Ghost',
    'Pilot'
  ];

  final LocalStorageService _storageService = LocalStorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomName() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final adj = _adjectives[random % _adjectives.length];
    final noun = _nouns[(random ~/ 7) % _nouns.length];
    final num = (random % 900) + 100;
    setState(() {
      _nameController.text = '$adj$noun$num';
    });
  }

  void _showDataUsageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.calculate_outlined, color: AppTheme.accentTeal),
            const SizedBox(width: 12),
            const Text('Local Calculations',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your data is used locally on this device to:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Calibrate lab result ranges for your age/sex'),
            _buildBulletPoint('Calculate BMI and health trends'),
            _buildBulletPoint('Generate personalized wellness insights'),
            const SizedBox(height: 20),
            const Text(
              'How this benefits you:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
                'Accuracy: Get medical references specific to you'),
            _buildBulletPoint(
                'Privacy: No personal data ever leaves your device'),
            _buildBulletPoint('Speed: Instant processing without internet'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: AppTheme.accentTeal)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppTheme.accentTeal, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final int currentYear = DateTime.now().year;
    final int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Select Year of Birth',
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              selectedDate: DateTime(_selectedYear ?? 1990),
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime.year);
              },
            ),
          ),
        );
      },
    );
    if (picked != null && picked != _selectedYear) {
      setState(() {
        _selectedYear = picked;
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
            dateOfBirth:
                _selectedYear != null ? DateTime(_selectedYear!, 1, 1) : null,
          );

    await _storageService.saveUserProfile(profile);

    if (skipped) {
      await _analyticsService.logEvent('profile_skipped');
    } else {
      if (profile.displayName != null)
        await _analyticsService.logEvent('profile_name_set');
      if (_selectedSex != 'unspecified' || _selectedYear != null) {
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
                          'Personalize Your Experience',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Providing basic info helps us calibrate lab result ranges for your age and sex.\n\nAll data stays local on your device.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLabel('Display Name', 'Optional'),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('e.g. John Doe'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextButton.icon(
                                onPressed: _generateRandomName,
                                icon: const Icon(Icons.casino_outlined,
                                    size: 18, color: AppTheme.accentTeal),
                                label: const Text(
                                  'Randomize',
                                  style: TextStyle(
                                      color: AppTheme.accentTeal,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Sex', 'For medical reference ranges'),
                        _buildSexSelection(),
                        const SizedBox(height: 24),
                        _buildLabel('Year of Birth', 'Just the year is enough'),
                        InkWell(
                          onTap: () => _selectYear(context),
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
                                  _selectedYear == null
                                      ? 'Select Year'
                                      : _selectedYear.toString(),
                                  style: TextStyle(
                                    color: _selectedYear == null
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

  Widget _buildLabel(String mainText, String bracketText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: mainText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' ($bracketText)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
          IconButton(
            onPressed: _showDataUsageInfo,
            icon: const Icon(Icons.info_outline,
                size: 18, color: AppTheme.healthGreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Where is it used?',
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
