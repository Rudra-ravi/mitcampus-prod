import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/blocs/auth_bloc.dart';
import 'package:mitcampus/screens/task_detail_screen.dart';

import '../blocs/task_bloc.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is TasksLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(
                child: Text('No tasks available'),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                final currentUserId = context.read<AuthBloc>().state.user.uid;
                final isAssigned = task.assignedUsers.contains(currentUserId);
                
                return TaskCard(
                  task: task,
                  isCurrentUserAssigned: isAssigned,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task, isHOD: false),
                    ),
                  ),
                  onStatusChanged: isAssigned ? (bool? value) {
                    if (value != null) {
                      context.read<TaskBloc>().add(
                        UpdateTaskStatus(
                          taskId: task.id!,
                          isCompleted: value,
                        ),
                      );
                    }
                  } : null,
                );
              },
            );
          }
          
          if (state is TaskError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-task');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}