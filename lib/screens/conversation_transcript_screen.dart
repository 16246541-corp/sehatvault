import 'package:flutter/material.dart';
import '../models/doctor_conversation.dart';
import '../widgets/design/liquid_glass_background.dart';

class ConversationTranscriptScreen extends StatefulWidget {
  final DoctorConversation conversation;

  const ConversationTranscriptScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationTranscriptScreen> createState() => _ConversationTranscriptScreenState();
}

class _ConversationTranscriptScreenState extends State<ConversationTranscriptScreen> {
  late List<ConversationSegment> _segments;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Use existing segments or create a default one from transcript
    _segments = widget.conversation.segments?.toList() ?? [];
    
    if (_segments.isEmpty && widget.conversation.transcript.isNotEmpty) {
       _segments.add(ConversationSegment(
         text: widget.conversation.transcript, 
         startTimeMs: 0, 
         endTimeMs: 0, 
         speaker: "Doctor" 
       ));
    }
  }

  Future<void> _saveChanges() async {
    widget.conversation.segments = _segments;
    // Update the main transcript string based on segments
    widget.conversation.transcript = _segments.map((e) => e.text).join('\n');
    
    await widget.conversation.save();
    
    setState(() {
      _hasChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved')),
      );
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
          title: Text(widget.conversation.title, style: theme.textTheme.titleLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: _segments.isEmpty
            ? Center(
                child: Text(
                  "No transcript available",
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _segments.length,
                itemBuilder: (context, index) {
                  final segment = _segments[index];
                  return _buildSegmentItem(index, segment);
                },
              ),
      ),
    );
  }

  Widget _buildSegmentItem(int index, ConversationSegment segment) {
    final isUser = segment.speaker == "User";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Speaker Label (Clickable to toggle)
                InkWell(
                  onTap: () {
                    setState(() {
                      segment.speaker = isUser ? "Doctor" : "User";
                      _hasChanges = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      segment.speaker,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                
                // Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Theme.of(context).primaryColor.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    initialValue: segment.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
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
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
      child: Icon(
        isUser ? Icons.person : Icons.medical_services,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
