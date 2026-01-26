import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_auth_service.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/responsive_center.dart';
import '../utils/design_constants.dart';

enum PinSetupMode { setup, change, reset }

class PinSetupScreen extends StatefulWidget {
  final PinSetupMode mode;
  final VoidCallback onComplete;
  final VoidCallback? onCancel;
  final bool showAppBar;

  const PinSetupScreen({
    super.key,
    required this.mode,
    required this.onComplete,
    this.onCancel,
    this.showAppBar = true,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  int _stepIndex = 0;
  bool _isSaving = false;
  String? _error;
  PinSecurityQuestion _selectedQuestion = PinSecurityQuestion.mothersMaidenName;

  String get _title {
    switch (widget.mode) {
      case PinSetupMode.setup:
        return 'Set up PIN';
      case PinSetupMode.change:
        return 'Change PIN';
      case PinSetupMode.reset:
        return 'Reset PIN';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PinSetupMode.setup:
        return 'Create a fallback PIN for secure access';
      case PinSetupMode.change:
        return 'Update your PIN to keep access secure';
      case PinSetupMode.reset:
        return 'Create a new PIN to restore access';
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() {
      _error = null;
    });

    if (_stepIndex == 0) {
      if (_pinController.text.trim().length < 4) {
        setState(() {
          _error = 'PIN must be at least 4 digits';
        });
        return;
      }
      setState(() {
        _stepIndex = 1;
      });
      return;
    }

    if (_stepIndex == 1) {
      if (_confirmController.text.trim() != _pinController.text.trim()) {
        setState(() {
          _error = 'PINs do not match';
        });
        return;
      }
      setState(() {
        _stepIndex = 2;
      });
      return;
    }

    if (_stepIndex == 2) {
      if (_answerController.text.trim().isEmpty) {
        setState(() {
          _error = 'Answer cannot be empty';
        });
        return;
      }
      setState(() {
        _isSaving = true;
      });
      final pinSaved = await _pinAuthService.setPin(_pinController.text.trim());
      final questionSaved = await _pinAuthService.setSecurityQuestion(
        _selectedQuestion,
        _answerController.text.trim(),
      );
      setState(() {
        _isSaving = false;
      });
      if (pinSaved && questionSaved) {
        widget.onComplete();
      } else {
        setState(() {
          _error = 'Unable to save PIN. Please try again.';
        });
      }
    }
  }

  void _back() {
    if (_stepIndex == 0) {
      widget.onCancel?.call();
      return;
    }
    setState(() {
      _stepIndex -= 1;
      _error = null;
    });
  }

  Widget _buildStepContent(BuildContext context) {
    final theme = Theme.of(context);
    if (_stepIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create PIN', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'PIN',
              counterText: '',
            ),
          ),
        ],
      );
    }
    if (_stepIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm PIN', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recovery Question', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        DropdownButtonFormField<PinSecurityQuestion>(
          value: _selectedQuestion,
          items: PinSecurityQuestion.values
              .map(
                (question) => DropdownMenuItem(
                  value: question,
                  child: Text(question.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedQuestion = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Security question',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          decoration: const InputDecoration(
            labelText: 'Answer',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmbedded = !widget.showAppBar;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(_title),
                backgroundColor: Colors.transparent,
                elevation: 0,
              )
            : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmbedded) ...[
                    const SizedBox(height: DesignConstants.titleTopPadding),
                    Text(_title, style: theme.textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text(_subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: DesignConstants.sectionSpacing),
                  ],
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${_stepIndex + 1} of 3',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStepContent(context),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _isSaving ? null : _back,
                              child: Text(_stepIndex == 0 ? 'Cancel' : 'Back'),
                            ),
                            const Spacer(),
                            GlassButton(
                              label: _stepIndex == 2 ? 'Save PIN' : 'Continue',
                              icon: _stepIndex == 2
                                  ? Icons.lock
                                  : Icons.arrow_forward,
                              isProminent: true,
                              onPressed: _isSaving ? null : _next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PINs expire every 90 days. You will be asked to update it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PinUnlockMode { pin, recovery }

class PinUnlockScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onAuthenticated;
  final VoidCallback? onCancel;

  const PinUnlockScreen({
    super.key,
    required this.title,
    required this.onAuthenticated,
    this.subtitle,
    this.onCancel,
  });

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _hasPin = false;
  bool _showSetup = false;
  PinSetupMode _setupMode = PinSetupMode.setup;
  PinUnlockMode _mode = PinUnlockMode.pin;
  PinSecurityQuestion? _question;
  String? _error;
  Duration? _lockoutRemaining;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final hasPin = await _pinAuthService.hasPin();
    final question = await _pinAuthService.getSecurityQuestion();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _question = question;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() {
      _error = null;
      _lockoutRemaining = null;
      _isVerifying = true;
    });
    final result = await _pinAuthService.verifyPin(_pinController.text.trim());
    if (!mounted) return;
    if (result.isSuccess) {
      widget.onAuthenticated();
      return;
    }
    if (result.status == PinVerificationStatus.expired) {
      setState(() {
        _showSetup = true;
        _setupMode = PinSetupMode.change;
        _isVerifying = false;
      });
      return;
    }
    setState(() {
      _isVerifying = false;
      _error = result.message;
      _lockoutRemaining = result.lockoutRemaining;
    });
  }

  Future<void> _verifyRecovery() async {
    setState(() {
      _error = null;
      _isVerifying = true;
    });
    final success =
        await _pinAuthService.verifySecurityAnswer(_answerController.text);
    if (!mounted) return;
    if (success) {
      setState(() {
        _showSetup = true;
        _setupMode = PinSetupMode.reset;
        _isVerifying = false;
      });
      return;
    }
    setState(() {
      _isVerifying = false;
      _error = 'Answer does not match';
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showSetup) {
      return PinSetupScreen(
        mode: _setupMode,
        onComplete: widget.onAuthenticated,
        onCancel: widget.onCancel,
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPin) {
      return PinSetupScreen(
        mode: PinSetupMode.setup,
        onComplete: widget.onAuthenticated,
        onCancel: widget.onCancel,
      );
    }

    final subtitle = widget.subtitle;
    final lockoutText = _lockoutRemaining != null
        ? 'Try again in ${_formatDuration(_lockoutRemaining!)}'
        : null;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignConstants.titleTopPadding),
                  Text(widget.title, style: theme.textTheme.displayMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: DesignConstants.sectionSpacing),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mode == PinUnlockMode.pin
                              ? 'Enter PIN'
                              : 'Recovery Question',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_mode == PinUnlockMode.pin) ...[
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'PIN',
                              counterText: '',
                            ),
                          ),
                        ] else ...[
                          if (_question != null)
                            Text(
                              _question!.label,
                              style: theme.textTheme.bodyMedium,
                            ),
                          if (_question == null)
                            Text(
                              'Recovery question not set',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _answerController,
                            decoration: const InputDecoration(
                              labelText: 'Answer',
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        if (lockoutText != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            lockoutText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _isVerifying
                                  ? null
                                  : () {
                                      if (_mode == PinUnlockMode.recovery) {
                                        setState(() {
                                          _mode = PinUnlockMode.pin;
                                          _error = null;
                                        });
                                        return;
                                      }
                                      widget.onCancel?.call();
                                    },
                              child: Text(_mode == PinUnlockMode.recovery
                                  ? 'Back'
                                  : 'Cancel'),
                            ),
                            const Spacer(),
                            GlassButton(
                              label: _mode == PinUnlockMode.pin
                                  ? 'Unlock'
                                  : 'Verify',
                              icon: _mode == PinUnlockMode.pin
                                  ? Icons.lock_open
                                  : Icons.check,
                              isProminent: true,
                              onPressed: _isVerifying
                                  ? null
                                  : (_mode == PinUnlockMode.pin
                                      ? _verifyPin
                                      : _verifyRecovery),
                            ),
                          ],
                        ),
                        if (_mode == PinUnlockMode.pin) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isVerifying
                                  ? null
                                  : () {
                                      setState(() {
                                        _mode = PinUnlockMode.recovery;
                                        _error = null;
                                      });
                                    },
                              child: const Text('Forgot PIN?'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PIN access is secured with device encryption.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
