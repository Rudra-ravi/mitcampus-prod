import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/blocs/task_bloc.dart';
import 'package:mitcampus/models/task.dart';
import 'package:mitcampus/screens/create_task_screen.dart';
import 'package:mitcampus/screens/task_detail_screen.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskBloc()..add(LoadTasksEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2563EB),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TasksLoaded && state.currentUser.isHOD) {
                return FloatingActionButton(
                  onPressed: () => _navigateToCreateTask(context),
                  backgroundColor: const Color(0xFF2563EB),
                  child: const Icon(Icons.add, color: Colors.white),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
            ),
          ),
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TasksLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (state is TasksLoaded) {
                if (state.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tasks available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        if (state.currentUser.isHOD)
                          TextButton(
                            onPressed: () => _navigateToCreateTask(context),
                            child: const Text(
                              'Create a task',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TaskBloc>().add(LoadTasksEvent());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.tasks.length,
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return TaskListItem(
                        task: task,
                        isHOD: state.currentUser.isHOD,
                        currentUserId: state.currentUser.id,
                      );
                    },
                  ),
                );
              } else if (state is TaskError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<TaskBloc>().add(LoadTasksEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _navigateToCreateTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<TaskBloc>(),
          child: const CreateTaskScreen(),
        ),
      ),
    );
  }
}

class TaskListItem extends StatelessWidget {
  final Task task;
  final bool isHOD;
  final String currentUserId;

  const TaskListItem({
    super.key,
    required this.task,
    required this.isHOD,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isUserCompleted = task.userCompletions[currentUserId] ?? false;
    final completedCount = task.userCompletions.values.where((v) => v).length;
    final totalCount = task.assignedUsers.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(task.status),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isFullyCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Deadline: ${_formatDate(task.deadline)}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(task.status)),
            ),
            const SizedBox(height: 4),
            Text(
              'Progress: $completedCount/$totalCount completed',
              style: TextStyle(
                color: _getStatusColor(task.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHOD)
              Checkbox(
                value: isUserCompleted,
                onChanged: (bool? value) {
                  if (value != null) {
                    final updatedCompletions = Map<String, bool>.from(task.userCompletions);
                    updatedCompletions[currentUserId] = value;
                    
                    final updatedTask = task.copyWith(
                      userCompletions: updatedCompletions,
                      isCompleted: task.assignedUsers.every(
                        (userId) => updatedCompletions[userId] == true
                      ),
                    );
                    
                    context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
                  }
                },
                activeColor: const Color(0xFF2563EB),
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(task: task, isHOD: isHOD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(TaskStatus status) {
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
