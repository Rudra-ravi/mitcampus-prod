import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/blocs/auth_bloc.dart';
import 'package:mitcampus/blocs/task_bloc.dart';
import 'package:mitcampus/models/task.dart';
import 'package:mitcampus/repositories/user_repository.dart';
import 'package:mitcampus/screens/create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final bool isHOD;

  const TaskDetailScreen({super.key, required this.task, required this.isHOD});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final UserRepository _userRepository = UserRepository();
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    try {
      final users = await _userRepository.getAllUsers();
      final userMap = {for (var user in users) user.id: user.displayName};
      setState(() {
        _userNames = userMap;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user names: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!widget.isHOD)
            IconButton(
              icon: Icon(
                widget.task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                final updatedTask = widget.task.copyWith(
                  isCompleted: !widget.task.isCompleted
                );
                context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
                Navigator.pop(context); // Go back to refresh the list
              },
            ),
          if (widget.isHOD) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditTask(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteTask(context),
            ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildInfoCard(
              title: 'Deadline',
              content: _formatDate(widget.task.deadline),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            _buildProgressTimeline(),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Description',
              content: widget.task.description ?? "No description",
              icon: Icons.description,
            ),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildAssignedUsersCard(),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const Divider(),
                    ...widget.task.comments.map((comment) => CommentWidget(comment: comment)),
                    AddCommentWidget(taskId: widget.task.id ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    if (title == 'Status') {
      final completedCount = widget.task.userCompletions.values.where((v) => v).length;
      final totalCount = widget.task.assignedUsers.length;
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.isHOD
                  ? 'Overall: ${widget.task.isFullyCompleted ? "Completed" : "Pending"}'
                  : 'Your Status: ${widget.task.userCompletions[context.read<AuthBloc>().state.user.uid] ?? false ? "Completed" : "Pending"}',
                style: TextStyle(
                  color: widget.task.isFullyCompleted ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress: $completedCount/$totalCount users completed',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    // Return regular info card for other types
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _navigateToEditTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<TaskBloc>(),
          child: CreateTaskScreen(taskToEdit: widget.task),
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                context.read<TaskBloc>().add(DeleteTaskEvent(widget.task.id!));
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to task list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssignedUsersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Color(0xFF2563EB)),
                SizedBox(width: 16),
                Text(
                  'Assigned Users',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.task.assignedUsers.map((userId) {
              final userName = _userNames[userId] ?? 'Unknown User';
              final isCompleted = widget.task.userCompletions[userId] ?? false;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(userName),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: isCompleted ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted ? 'Completed' : 'Pending',
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTimeline() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            ...widget.task.assignedUsers.map((userId) {
              final userName = _userNames[userId] ?? 'Unknown User';
              final isCompleted = widget.task.userCompletions[userId] ?? false;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.person,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final completedCount = widget.task.userCompletions.values.where((v) => v).length;
    final totalCount = widget.task.assignedUsers.length;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(widget.task.status),
                  color: _getStatusColor(widget.task.status),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(widget.task.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(widget.task.status)),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: $completedCount/$totalCount users completed',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(widget.task.status),
              style: TextStyle(
                color: _getStatusColor(widget.task.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.overdue:
        return Icons.warning;
      case TaskStatus.pending:
        return Icons.schedule;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return 'Task Completed';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.overdue:
        return 'Task Overdue';
      case TaskStatus.pending:
        return 'Pending';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return const Color(0xFF2563EB);
      case TaskStatus.overdue:
        return Colors.red;
      case TaskStatus.pending:
        return Colors.orange;
    }
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${comment.userName} • ${_formatDateTime(comment.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}

class AddCommentWidget extends StatefulWidget {
  final String taskId;

  const AddCommentWidget({super.key, required this.taskId});

  @override
  AddCommentWidgetState createState() => AddCommentWidgetState();
}

class AddCommentWidgetState extends State<AddCommentWidget> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthSuccess) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    final comment = Comment(
                      userId: authState.user.uid,
                      userName: authState.user.displayName ?? authState.user.email?.split('@')[0] ?? 'Anonymous',
                      text: _commentController.text,
                      timestamp: DateTime.now(),
                    );
                    context.read<TaskBloc>().add(AddCommentEvent(widget.taskId, comment));
                    _commentController.clear();
                  }
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

