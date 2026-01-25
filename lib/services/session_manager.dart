import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'llm_engine.dart';
import 'model_fallback_service.dart';
import '../services/local_storage_service.dart';
import '../services/conversation_recorder_service.dart';
import '../services/temp_file_manager.dart';
import '../services/local_audit_service.dart';
import '../services/platform_detector.dart';
import '../services/window_manager_service.dart';
import '../screens/lock_screen.dart';
import '../widgets/education/education_modal.dart';

class SessionManager with WidgetsBindingObserver, ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _timeoutTimer;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLocked = false;
  DateTime? _lastActivityTime;
  DateTime? _lastUnlockTime;
  int _validationFailures = 0;
  String? _currentSessionId;
  Map<String, dynamic>? _preservedModelContext;

  final StreamController<void> _resumeStream =
      StreamController<void>.broadcast();
  Stream<void> get onResume => _resumeStream.stream;

  // Getter to check if session is currently locked
  bool get isLocked => _isLocked;
  DateTime? get lastUnlockTime => _lastUnlockTime;
  int get validationFailures => _validationFailures;
  String? get currentSessionId => _currentSessionId;

  /// Preserves AI context during model fallback or session transitions.
  void preserveModelContext(Map<String, dynamic> context) {
    _preservedModelContext = context;
  }

  /// Retrieves and clears preserved AI context.
  Map<String, dynamic>? consumePreservedContext() {
    final ctx = _preservedModelContext;
    _preservedModelContext = null;
    return ctx;
  }

  void trackValidationFailure() {
    _validationFailures++;
  }

  void resetValidationFailures() {
    _validationFailures = 0;
  }

  void startSession() {
    WidgetsBinding.instance.addObserver(this);
    _lastUnlockTime = DateTime.now();
    _currentSessionId = const Uuid().v4();

    // Initialize platform detector
    PlatformDetector().getCapabilities();

    final auditService = LocalAuditService(LocalStorageService(), this);
    auditService.log(
      action: 'session_start',
      details: {'sessionId': _currentSessionId ?? ''},
      sensitivity: 'info',
    );
    // Periodic integrity check on session start
    auditService.verifyIntegrity();
    _resetTimer();
  }

  void stopSession() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _releaseAIResources();
  }

  void _releaseAIResources() {
    LLMEngine().dispose();
  }

  void resetActivity() {
    if (!_isLocked) {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _timeoutTimer?.cancel();
    _lastActivityTime = DateTime.now();

    final settings = LocalStorageService().getAppSettings();
    final int timeoutMinutes = settings.sessionTimeoutMinutes;

    final duration = Duration(minutes: timeoutMinutes > 0 ? timeoutMinutes : 2);

    _timeoutTimer = Timer(duration, _lockApp);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeStream.add(null);
      if (_isLocked) {
        // Ensure lock screen is top? It should be.
        return;
      }

      // Check if we should lock based on time elapsed since last activity
      // (which essentially includes background time if we count from last reset)
      if (_lastActivityTime != null) {
        final settings = LocalStorageService().getAppSettings();
        final int timeoutMinutes = settings.sessionTimeoutMinutes;
        final duration =
            Duration(minutes: timeoutMinutes > 0 ? timeoutMinutes : 2);

        if (DateTime.now().difference(_lastActivityTime!) > duration) {
          _lockApp();
        } else {
          _resetTimer();
        }
      } else {
        _resetTimer();
      }
    } else if (state == AppLifecycleState.paused) {
      // We can cancel timer to save resources, or let it run.
      // If we cancel, we rely on _lastActivityTime check on resume.
      _timeoutTimer?.cancel();

      // Trigger data minimization protocol
      _performBackgroundCleanup();
    }
  }

  Future<void> _performBackgroundCleanup() async {
    // Purge temporary files that are not preserved
    await TempFileManager().purgeAll(reason: 'background_pause');
    await LocalAuditService(LocalStorageService(), this).runDailyCleanup();
    _releaseAIResources();
  }

  Future<void> lockImmediately() async {
    await _lockApp();
  }

  Future<void> _lockApp() async {
    // Check exceptions
    final recorderService = ConversationRecorderService();
    if (recorderService.isRecording) {
      // If recording, restart timer
      _resetTimer();
      return;
    }

    _isLocked = true;
    _timeoutTimer?.cancel();
    notifyListeners();
    await LocalAuditService(LocalStorageService(), this).log(
      action: 'session_lock',
      details: {'reason': 'timeout'},
      sensitivity: 'warning',
    );

    // Navigate to lock screen
    // We use pushAndRemoveUntil or just push over everything?
    // Pushing over everything is safer to preserve state underneath.
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const LockScreen(),
          fullscreenDialog: true,
        ),
      );
      // When we return from LockScreen (popped), we are unlocked
      _isLocked = false;
      _lastUnlockTime = DateTime.now();
      _currentSessionId = const Uuid().v4();
      notifyListeners();
      await LocalAuditService(LocalStorageService(), this).log(
        action: 'session_unlock',
        details: {'sessionId': _currentSessionId ?? ''},
        sensitivity: 'info',
      );
      _resetTimer();
    }
  }

  // Education Logic
  Future<void> showEducationIfNeeded(String featureId) async {
    // This is a simplified call, actual implementation might check storage
    // Assuming EducationService is handled elsewhere or we invoke UI here
    // For now, this is a placeholder matching the service call in recorder
  }
}
