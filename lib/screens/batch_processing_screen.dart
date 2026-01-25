import 'package:flutter/material.dart';
import '../models/batch_task.dart';
import '../services/batch_processing_service.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_button.dart';
import 'package:intl/intl.dart';

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({super.key});

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  final BatchProcessingService _batchService = BatchProcessingService();

  @override
  void initState() {
    super.initState();
    _batchService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Batch Processing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Completed',
            onPressed: () => _batchService.clearCompleted(),
          ),
        ],
      ),
      body: LiquidGlassBackground(
        child: StreamBuilder<List<BatchTask>>(
          stream: _batchService.tasksStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_motion,
                        size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'No batch tasks in queue',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            final tasks = snapshot.data!;
            final pendingCount =
                tasks.where((t) => t.status == BatchTaskStatus.pending).length;
            final processingCount = tasks
                .where((t) => t.status == BatchTaskStatus.processing)
                .length;
            final completedCount = tasks
                .where((t) => t.status == BatchTaskStatus.completed)
                .length;
            final failedCount =
                tasks.where((t) => t.status == BatchTaskStatus.failed).length;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    child: _buildSummaryCard(
                      pending: pendingCount,
                      processing: processingCount,
                      completed: completedCount,
                      failed: failedCount,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _buildTaskCard(task),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int pending,
    required int processing,
    required int completed,
    required int failed,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queue Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Pending', pending.toString(), Colors.orange),
                _buildStatItem(
                    'Processing', processing.toString(), Colors.blue),
                _buildStatItem('Completed', completed.toString(), Colors.green),
                _buildStatItem('Failed', failed.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    onPressed: () {
                      if (_batchService.isPaused) {
                        _batchService.resumeProcessing();
                      } else {
                        _batchService.pauseProcessing();
                      }
                      setState(() {}); // Refresh to update button text
                    },
                    label:
                        _batchService.isPaused ? 'Resume Queue' : 'Pause Queue',
                    icon:
                        _batchService.isPaused ? Icons.play_arrow : Icons.pause,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Tasks?'),
                          content: const Text(
                              'This will remove all tasks from the queue.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear All',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _batchService.clearAll();
                      }
                    },
                    label: 'Clear All',
                    icon: Icons.clear_all,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BatchTask task) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(task.status),
                  color: _getStatusColor(task.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Created: ${DateFormat('HH:mm:ss').format(task.createdAt)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(task.priority),
                if (task.status == BatchTaskStatus.failed)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () => _batchService.retryTask(task.id),
                  ),
                if (task.status == BatchTaskStatus.pending ||
                    task.status == BatchTaskStatus.processing)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _batchService.cancelTask(task.id),
                  ),
              ],
            ),
            if (task.status == BatchTaskStatus.processing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '${(task.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
            if (task.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${task.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(BatchTaskPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case BatchTaskPriority.high:
        color = Colors.red;
        label = 'HIGH';
        break;
      case BatchTaskPriority.normal:
        color = Colors.blue;
        label = 'NORMAL';
        break;
      case BatchTaskPriority.low:
        color = Colors.grey;
        label = 'LOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getStatusIcon(BatchTaskStatus status) {
    switch (status) {
      case BatchTaskStatus.pending:
        return Icons.schedule;
      case BatchTaskStatus.processing:
        return Icons.sync;
      case BatchTaskStatus.completed:
        return Icons.check_circle;
      case BatchTaskStatus.failed:
        return Icons.error;
      case BatchTaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(BatchTaskStatus status) {
    switch (status) {
      case BatchTaskStatus.pending:
        return Colors.orange;
      case BatchTaskStatus.processing:
        return Colors.blue;
      case BatchTaskStatus.completed:
        return Colors.green;
      case BatchTaskStatus.failed:
        return Colors.red;
      case BatchTaskStatus.cancelled:
        return Colors.grey;
    }
  }
}
