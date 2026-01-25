import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../models/doctor_conversation.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../services/audio_playback_service.dart';
import '../services/local_storage_service.dart';
import '../services/encryption_service.dart';
import '../services/biometric_service.dart';
import '../services/export_service.dart';
import '../widgets/compliance/fda_disclaimer_widget.dart';
import '../widgets/design/recording_disclaimer.dart';
import '../widgets/auth_gate.dart';
import '../services/risk_mitigation_service.dart';
import '../services/conversation_memory_service.dart';
import '../models/conversation_memory.dart';

class ConversationTranscriptScreen extends StatefulWidget {
  final DoctorConversation conversation;

  const ConversationTranscriptScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationTranscriptScreen> createState() =>
      _ConversationTranscriptScreenState();
}

class _ConversationTranscriptScreenState
    extends State<ConversationTranscriptScreen>
    with SingleTickerProviderStateMixin {
  late List<ConversationSegment> _segments;
  bool _hasChanges = false;

  late TabController _tabController;
  ConversationMemory? _memory;
  bool _isLoadingMemory = true;

  // Undo/Redo
  final List<List<ConversationSegment>> _undoStack = [];
  final List<List<ConversationSegment>> _redoStack = [];

  // Audio Playback
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  late final AudioPlaybackService _playbackService;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  bool _isKept = false;
  DateTime? _deletionDate;

  List<String> _riskQuestions = [];
  bool _isLoadingRiskQuestions = true;

  @override
  void initState() {
    super.initState();
    // Use existing segments or create a default one from transcript
    _segments = widget.conversation.segments?.toList() ?? [];

    // TODO: Integrate SafetyFilterService if AI summaries or insights are added in the future.
    // e.g., String summary = SafetyFilterService().sanitize(aiSummary);

    if (_segments.isEmpty && widget.conversation.transcript.isNotEmpty) {
      _segments.add(ConversationSegment(
          text: widget.conversation.transcript,
          startTimeMs: 0,
          endTimeMs: 0,
          speaker: "Doctor"));
    }

    // Initial state for undo
    // _saveStateForUndo(); // Don't save initial state as first undo step, or maybe yes?
    // Usually undo stack starts empty.

    _initAudio();
    _checkAutoDeleteStatus();
    _loadRiskQuestions();
    _loadMemory();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadMemory() async {
    final memory =
        LocalStorageService().getConversationMemory(widget.conversation.id);
    if (mounted) {
      setState(() {
        _memory = memory;
        _isLoadingMemory = false;
      });
    }
  }

  Future<void> _loadRiskQuestions() async {
    try {
      final questions = await RiskMitigationService()
          .generateRiskMitigationQuestions(widget.conversation.transcript);
      if (mounted) {
        setState(() {
          _riskQuestions = questions;
          _isLoadingRiskQuestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading risk questions: $e');
      if (mounted) {
        setState(() => _isLoadingRiskQuestions = false);
      }
    }
  }

  void _saveStateForUndo() {
    _undoStack.add(_deepCopySegments(_segments));
    _redoStack.clear();
    // Limit stack size
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  List<ConversationSegment> _deepCopySegments(
      List<ConversationSegment> segments) {
    return segments
        .map((s) => ConversationSegment(
              text: s.text,
              startTimeMs: s.startTimeMs,
              endTimeMs: s.endTimeMs,
              speaker: s.speaker,
            ))
        .toList();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_deepCopySegments(_segments));
    setState(() {
      _segments = _undoStack.removeLast();
      _hasChanges = true;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_deepCopySegments(_segments));
    setState(() {
      _segments = _redoStack.removeLast();
      _hasChanges = true;
    });
  }

  Map<String, dynamic> get _validationMetrics {
    int charCount = _segments.fold(0, (sum, seg) => sum + seg.text.length);
    int emptySegments = _segments.where((s) => s.text.trim().isEmpty).length;
    int shortSegments = _segments.where((s) => s.text.trim().length < 5).length;
    int qualityScore = 100 - (emptySegments * 10) - (shortSegments * 2);
    if (qualityScore < 0) qualityScore = 0;
    return {
      "charCount": charCount,
      "qualityScore": qualityScore,
      "issues": emptySegments + shortSegments
    };
  }

  void _checkAutoDeleteStatus() {
    final settings = LocalStorageService().getAppSettings();
    setState(() {
      _isKept = settings.keepAudioIds.contains(widget.conversation.id);
      if (settings.autoDeleteRecordingsDays > 0) {
        _deletionDate = widget.conversation.createdAt
            .add(Duration(days: settings.autoDeleteRecordingsDays));
      }
    });
  }

  Future<void> _toggleKeep() async {
    final settings = LocalStorageService().getAppSettings();
    setState(() {
      if (_isKept) {
        settings.keepAudioIds.remove(widget.conversation.id);
        _isKept = false;
      } else {
        settings.keepAudioIds.add(widget.conversation.id);
        _isKept = true;
      }
    });
    await LocalStorageService().saveAppSettings(settings);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _initAudio() async {
    // Initialize services directly (or use a locator in a real app)
    _playbackService = AudioPlaybackService(
      LocalStorageService(),
      EncryptionService(),
      BiometricService(),
    );

    await _player.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _handlePlayback() async {
    if (!_isPlayerInitialized) return;

    if (_isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    try {
      // Show loading or some indication?
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authenticating...')),
      );

      final audioBytes =
          await _playbackService.decryptAudio(widget.conversation.id);

      if (audioBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load audio')),
          );
        }
        return;
      }

      await _player.startPlayer(
        fromDataBuffer: audioBytes,
        codec:
            Codec.pcm16WAV, // Assuming WAV from recorder/transcription service
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback Error: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges({bool confirm = false}) async {
    // Versioning logic
    if (widget.conversation.originalTranscript == null) {
      widget.conversation.originalTranscript = widget.conversation.transcript;
    }
    widget.conversation.editedAt = DateTime.now();

    widget.conversation.segments = _segments;
    // Update the main transcript string based on segments
    widget.conversation.transcript = _segments.map((e) => e.text).join('\n');

    await widget.conversation.save();

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(confirm ? 'Transcript Confirmed' : 'Changes saved')),
      );
    }
  }

  Future<void> _confirmTranscript() async {
    final metrics = _validationMetrics;
    if (metrics['qualityScore'] < 50) {
      // Show warning
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Low Quality Score'),
          content: const Text(
              'The transcript quality score is low. Are you sure you want to confirm?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proceed')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await _saveChanges(confirm: true);
  }

  Future<void> _exportTranscript() async {
    try {
      await ExportService().exportTranscript(context, widget.conversation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBanner = !_isKept &&
        _deletionDate != null &&
        _deletionDate!.isAfter(DateTime.now()) &&
        widget.conversation.encryptedAudioPath.isNotEmpty;

    final metrics = _validationMetrics;
    final settings = LocalStorageService().getAppSettings();

    return AuthGate(
        enabled:
            settings.enhancedPrivacySettings.requireBiometricsForSensitiveData,
        reason: 'Authenticate to view transcript',
        child: LiquidGlassBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.conversation.title,
                  style: theme.textTheme.titleLarge),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undoStack.isNotEmpty ? _undo : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                  tooltip: 'Redo',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Export Transcript',
                  onPressed: _exportTranscript,
                ),
                // Keep Toggle
                IconButton(
                  icon: Icon(_isKept ? Icons.bookmark : Icons.bookmark_border),
                  tooltip: _isKept ? 'Kept Permanently' : 'Keep Recording',
                  onPressed: _toggleKeep,
                ),
                // Playback Button
                IconButton(
                  icon: Icon(_isPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.lock_open_rounded),
                  tooltip: _isPlaying ? 'Stop' : 'Secure Playback',
                  onPressed: _handlePlayback,
                ),
                if (_hasChanges)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _saveChanges(),
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                      text: 'Transcript',
                      icon: Icon(Icons.description_outlined)),
                  Tab(text: 'AI Memory', icon: Icon(Icons.psychology_outlined)),
                ],
                indicatorColor: theme.primaryColor,
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              color: theme.colorScheme.surface.withOpacity(0.9),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quality: ${metrics['qualityScore']}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: (metrics['qualityScore'] as int) > 80
                                ? Colors.green
                                : (metrics['qualityScore'] as int) > 50
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${metrics['charCount']} chars',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _confirmTranscript,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                if (showBanner)
                  MaterialBanner(
                    content: Text(
                      'Recording will auto-delete on ${_formatDate(_deletionDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    leading: const Icon(Icons.auto_delete_outlined,
                        color: Colors.orange),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    actions: [
                      TextButton(
                        onPressed: _toggleKeep,
                        child: const Text('Keep Permanently'),
                      ),
                    ],
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Transcript
                      _segments.isEmpty
                          ? Center(
                              child: Text(
                                "No transcript available",
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _segments.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RecordingDisclaimer(
                                          initialValue: widget.conversation
                                                  .complianceReviewDate !=
                                              null,
                                          onConfirmationChanged: (_) {},
                                        ),
                                        const SizedBox(height: 16),
                                        FdaDisclaimerWidget(),
                                        if (_riskQuestions.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50
                                                  .withOpacity(0.9),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.amber.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons.lightbulb_outline,
                                                        color: Colors
                                                            .amber.shade900),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Doctor-Patient Discussion Guide',
                                                      style: theme
                                                          .textTheme.titleSmall
                                                          ?.copyWith(
                                                              color: Colors
                                                                  .amber
                                                                  .shade900,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                ..._riskQuestions
                                                    .map((q) => Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 8.0),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text('• ',
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          color: Colors
                                                                              .amber
                                                                              .shade900,
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                              Expanded(
                                                                  child: Text(q,
                                                                      style: theme
                                                                          .textTheme
                                                                          .bodyMedium
                                                                          ?.copyWith(
                                                                              color: Colors.amber.shade900))),
                                                            ],
                                                          ),
                                                        )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                                final segment = _segments[index - 1];
                                return _buildSegmentItem(index - 1, segment);
                              },
                            ),
                      // Tab 2: AI Memory
                      _buildMemoryHistoryTab(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildMemoryHistoryTab(ThemeData theme) {
    if (_isLoadingMemory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memory == null || _memory!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              "No AI memory history for this conversation",
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Context is generated when you ask questions about this recording.",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildMemoryMetricsHeader(theme),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _memory!.entries.length,
            itemBuilder: (context, index) {
              final entry = _memory!.entries[index];
              return _buildMemoryEntryItem(entry, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryMetricsHeader(ThemeData theme) {
    final metrics = _memory!.metrics;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            theme,
            label: 'Messages',
            value: '${metrics['message_count'] ?? 0}',
            icon: Icons.message_outlined,
          ),
          _buildMetricItem(
            theme,
            label: 'Tokens',
            value: '${metrics['total_tokens'] ?? 0}',
            icon: Icons.token_outlined,
          ),
          _buildMetricItem(
            theme,
            label: 'Redacted',
            value: '${metrics['redaction_count'] ?? 0}',
            icon: Icons.privacy_tip_outlined,
            color: (metrics['redaction_count'] ?? 0) > 0 ? Colors.orange : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme,
      {required String label,
      required String value,
      required IconData icon,
      Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.white70),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
      ],
    );
  }

  Widget _buildMemoryEntryItem(MemoryEntry entry, ThemeData theme) {
    final isAssistant = entry.role == 'assistant';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAssistant)
                const Icon(Icons.psychology, size: 14, color: Colors.blue),
              if (!isAssistant)
                const Icon(Icons.person, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                entry.role.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAssistant ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(entry.timestamp),
                style:
                    theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAssistant
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAssistant
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontStyle:
                        entry.isRedacted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (entry.isRedacted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Privacy redacted',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                if (entry.metadata['truncated'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Context window truncated',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildSegmentItem(int index, ConversationSegment segment) {
    final isUser = segment.speaker == "User";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(segment.speaker),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Speaker Label (Clickable to toggle)
                InkWell(
                  onTap: () {
                    _saveStateForUndo();
                    setState(() {
                      if (segment.speaker == "User") {
                        segment.speaker = "Doctor";
                      } else if (segment.speaker == "Doctor") {
                        segment.speaker = "Unknown";
                      } else {
                        segment.speaker = "User";
                      }
                      _hasChanges = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          segment.speaker,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _getSpeakerColor(segment.speaker),
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (segment.speakerConfidence != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            "(${(segment.speakerConfidence! * 100).toInt()}%)",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(segment.speaker),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextFormField(
                    key: ObjectKey(segment),
                    initialValue: segment.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      _saveStateForUndo();
                    },
                    onChanged: (value) {
                      segment.text = value;
                      _hasChanges = true;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(segment.speaker),
        ],
      ),
    );
  }

  Color _getSpeakerColor(String speaker) {
    if (speaker == "User") return Colors.blueAccent;
    if (speaker == "Doctor") return Colors.greenAccent;
    return Colors.grey;
  }

  Color _getBubbleColor(String speaker) {
    if (speaker == "User") {
      return Theme.of(context).primaryColor.withValues(alpha: 0.2);
    }
    if (speaker == "Doctor") return Colors.green.withValues(alpha: 0.1);
    return Colors.grey.withValues(alpha: 0.1);
  }

  Widget _buildAvatar(String speaker) {
    Color color;
    IconData icon;

    if (speaker == "User") {
      color = Colors.blue;
      icon = Icons.person;
    } else if (speaker == "Doctor") {
      color = Colors.green;
      icon = Icons.medical_services;
    } else {
      color = Colors.grey;
      icon = Icons.question_mark;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}
