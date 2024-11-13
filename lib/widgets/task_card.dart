import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mitcampus/blocs/auth_bloc.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onStatusChanged;
  final bool isCurrentUserAssigned;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    required this.isCurrentUserAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(task.status).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentUserAssigned)
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: task.userCompletions[context.read<AuthBloc>().state.user.uid] ?? false,
                        onChanged: onStatusChanged,
                        activeColor: _getStatusColor(task.status),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, 
                        size: 14, 
                        color: _isOverdue(task.deadline) ? Colors.red : Colors.grey[600]
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(task.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOverdue(task.deadline) ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  _buildProgressIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(task.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(task.status),
        style: TextStyle(
          color: _getStatusColor(task.status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final completedCount = task.userCompletions.values.where((v) => v).length;
    final totalCount = task.assignedUsers.length;
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(task.status)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$completedCount/$totalCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.overdue:
        return Colors.red;
      case TaskStatus.pending:
        return Colors.orange;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.pending:
        return 'Pending';
    }
  }

  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now()) && !task.isCompleted;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(date);
  }
} 