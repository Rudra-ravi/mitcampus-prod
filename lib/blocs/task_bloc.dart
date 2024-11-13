import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/models/task.dart';
import 'package:mitcampus/models/user.dart';
import 'package:mitcampus/repositories/task_repository.dart';
import 'package:mitcampus/repositories/user_repository.dart';

// Events
abstract class TaskEvent {}

class LoadTasksEvent extends TaskEvent {}

class UpdateTaskEvent extends TaskEvent {
  final Task task;
  UpdateTaskEvent(this.task);
}

class CreateTaskEvent extends TaskEvent {
  final Task task;
  CreateTaskEvent(this.task);
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);
}

class AddCommentEvent extends TaskEvent {
  final String taskId;
  final Comment comment;
  AddCommentEvent(this.taskId, this.comment);
}

class UpdateTaskStatus extends TaskEvent {
  final String taskId;
  final bool isCompleted;

  UpdateTaskStatus({required this.taskId, required this.isCompleted});
}

// States
abstract class TaskState {}

class TasksLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final User currentUser;
  TasksLoaded(this.tasks, this.currentUser);
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

class TasksOptimisticUpdate extends TaskState {
  final List<Task> tasks;
  final User currentUser;
  final Task updatingTask;

  TasksOptimisticUpdate(this.tasks, this.currentUser, this.updatingTask);
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository = TaskRepository();
  final UserRepository _userRepository = UserRepository();
  StreamSubscription? _tasksSubscription;

  TaskBloc() : super(TasksLoading()) {
    _initializeTaskStream();

    on<LoadTasksEvent>((event, emit) async {
      emit(TasksLoading());
      try {
        final currentUser = await _userRepository.getCurrentUser();
        final tasks = await _taskRepository.getTasks();
        emit(TasksLoaded(tasks, currentUser));
      } catch (e) {
        emit(TaskError('Failed to load tasks: $e'));
      }
    });

    on<CreateTaskEvent>((event, emit) async {
      try {
        await _taskRepository.createTask(event.task);
      } catch (e) {
        emit(TaskError('Failed to create task: $e'));
      }
    });

    on<UpdateTaskEvent>((event, emit) async {
      try {
        await _taskRepository.updateTask(event.task);
      } catch (e) {
        emit(TaskError('Failed to update task: $e'));
      }
    });

    on<DeleteTaskEvent>((event, emit) async {
      try {
        await _taskRepository.deleteTask(event.taskId);
      } catch (e) {
        emit(TaskError('Failed to delete task: $e'));
      }
    });

    on<UpdateTaskStatus>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is TasksLoaded) {
          final taskToUpdate = currentState.tasks.firstWhere(
            (task) => task.id == event.taskId,
          );
          
          final updatedCompletions = Map<String, bool>.from(taskToUpdate.userCompletions);
          final currentUserId = currentState.currentUser.id;
          updatedCompletions[currentUserId] = event.isCompleted;

          final updatedTask = taskToUpdate.copyWith(
            userCompletions: updatedCompletions,
            isCompleted: taskToUpdate.assignedUsers.every(
              (userId) => updatedCompletions[userId] == true
            ),
          );

          await _taskRepository.updateTask(updatedTask);
        }
      } catch (e) {
        emit(TaskError('Failed to update task status: $e'));
      }
    });
  }

  void _initializeTaskStream() {
    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository.getTasksStream().listen(
      (tasks) async {
        final currentUser = await _userRepository.getCurrentUser();
        // ignore: invalid_use_of_visible_for_testing_member
        emit(TasksLoaded(tasks, currentUser));
      },
      onError: (error) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(TaskError('Failed to load tasks: $error'));
      },
    );
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
