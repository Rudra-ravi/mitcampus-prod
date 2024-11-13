import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mitcampus/models/task.dart';
import 'package:rxdart/rxdart.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  Future<List<Task>> getTasks() async {
    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data to check if they are HOD
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final isHOD = userDoc.data()?['isHOD'] ?? false;

      QuerySnapshot snapshot;
      if (isHOD) {
        // If HOD, get all tasks
        snapshot = await _firestore.collection(_collection)
            .orderBy('deadline')
            .get();
      } else {
        // For regular users, get tasks where they are assigned or created by them
        final assignedTasksQuery = await _firestore.collection(_collection)
            .where('assignedUsers', arrayContains: currentUser.uid)
            .get();
            
        final createdTasksQuery = await _firestore.collection(_collection)
            .where('createdBy', isEqualTo: currentUser.uid)
            .get();

        // Combine and deduplicate results
        final allDocs = {...assignedTasksQuery.docs, ...createdTasksQuery.docs};
        return allDocs
            .map((doc) => Task.fromFirestore(doc))
            .toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));
      }

      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      if (task.id == null) {
        throw Exception('Task ID cannot be null');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('tasks').doc(task.id);
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('Task does not exist');
        }

        transaction.update(docRef, task.toFirestore());
      });
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(task.toFirestore());

      // Fetch the created document to return the complete task with ID
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception(
            'Failed to create task: Document does not exist after creation');
      }

      return Task.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Future<void> addComment(String taskId, Comment comment) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('tasks').doc(taskId);
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('Task does not exist');
        }

        transaction.update(docRef, {
          'comments': FieldValue.arrayUnion([comment.toMap()])
        });
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<List<Task>> getTasksForUser(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedUsers', arrayContains: userId)
        .get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  Stream<List<Task>> getTasksStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .switchMap((userDoc) {
      final isHOD = userDoc.data()?['isHOD'] ?? false;

      if (isHOD) {
        return _firestore
            .collection(_collection)
            .orderBy('deadline')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => Task.fromFirestore(doc))
                .toList());
      } else {
        return Rx.combineLatest2(
          _firestore
              .collection(_collection)
              .where('assignedUsers', arrayContains: currentUser.uid)
              .snapshots(),
          _firestore
              .collection(_collection)
              .where('createdBy', isEqualTo: currentUser.uid)
              .snapshots(),
          (QuerySnapshot assigned, QuerySnapshot created) {
            final tasks = [
              ...assigned.docs.map((doc) => Task.fromFirestore(doc)),
              ...created.docs.map((doc) => Task.fromFirestore(doc))
            ];
            
            final uniqueTasks = tasks.fold<Map<String, Task>>({}, (map, task) {
              if (task.id != null) {
                map[task.id!] = task;
              }
              return map;
            }).values.toList();

            uniqueTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
            return uniqueTasks;
          },
        );
      }
    });
  }

  // Add filtered streams for better performance
  Stream<List<Task>> getTasksStreamByStatus(TaskStatus status) {
    return _firestore
        .collection(_collection)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .where((task) => task.status == status)
            .toList());
  }
}

// Add a custom exception class for better error handling
class TaskRepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  TaskRepositoryException(this.message, [this.originalError]);

  @override
  String toString() =>
      'TaskRepositoryException: $message${originalError != null ? ' ($originalError)' : ''}';
}
