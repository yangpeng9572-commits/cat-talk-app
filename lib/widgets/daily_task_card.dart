import 'package:flutter/material.dart';
import '../models/daily_task.dart';
import '../services/task_companion_service.dart';

/// 每日任務卡片 widget（陪伴版）
class DailyTaskCard extends StatefulWidget {
  final List<DailyTask> tasks;
  final int currentStreak;
  final VoidCallback? onTaskTap;
  final Function(TaskType)? onTaskComplete;

  const DailyTaskCard({
    super.key,
    required this.tasks,
    required this.currentStreak,
    this.onTaskTap,
    this.onTaskComplete,
  });

  @override
  State<DailyTaskCard> createState() => _DailyTaskCardState();
}

class _DailyTaskCardState extends State<DailyTaskCard>
    with SingleTickerProviderStateMixin {
  final TaskCompanionService _companion = TaskCompanionService();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;
    final totalCount = widget.tasks.length;

    // 空任務狀態
    if (widget.tasks.isEmpty) {
      return _buildEmptyState();
    }

    // 全部完成狀態
    if (completedCount == totalCount) {
      return _buildAllDoneState();
    }

    // 顯示的任務（預設 3 個，其餘可展開）
    final displayTasks = _isExpanded || widget.tasks.length <= 3
        ? widget.tasks
        : widget.tasks.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 標題列 =====
          Row(
            children: [
              // 🔥 連續標記
              if (widget.currentStreak > 0) ...[
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '${widget.currentStreak} 天',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今天陪她的小事',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '完成一點點陪伴，累積你們的默契',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // 完成進度
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == totalCount
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: completedCount == totalCount
                        ? Colors.green
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== 任務列表 =====
          ...displayTasks.map((task) => _buildTaskItem(task)),

          // ===== 展開按鈕 =====
          if (!_isExpanded && widget.tasks.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _isExpanded = true),
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text(
                  '還有 ${widget.tasks.length - 3} 個小任務',
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ),
          ],

          // ===== 全部完成提示 =====
          if (completedCount == totalCount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade50, Colors.orange.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _companion.getAllCompletedMessage(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 空的時候顯示
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _companion.getEmptyMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 全部完成的時候顯示
  Widget _buildAllDoneState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('💕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _companion.getAllDoneMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立任務項目
  Widget _buildTaskItem(DailyTask task) {
    final isCompleted = task.isCompleted;
    final companionTitle = _companion.getTitle(task.type);
    final companionDesc = _companion.getDescription(task.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade50.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // 左側 emoji
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.shade100
                  : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.green, size: 22)
                  : Text(task.type.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // 中間：標題與描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companionTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  companionDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 右側：默契獎勵（不用 exp）
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '默契 +5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            )
          else
            _buildProgressIndicator(task),
        ],
      ),
    );
  }

  /// 進度條
  Widget _buildProgressIndicator(DailyTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          task.progressText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.orange.shade300),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}
