import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue
}

class Task {
  final String? id;
  final String title;
  final String? description;
  final DateTime deadline;
  final List<String> assignedUsers;
  final List<Comment> comments;
  final bool isCompleted;
  final Map<String, bool> userCompletions;
  final String createdBy;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.deadline,
    required this.assignedUsers,
    required this.comments,
    required this.isCompleted,
    required this.userCompletions,
    required this.createdBy, required bool isFullyCompleted,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? assignedUsers,
    List<Comment>? comments,
    bool? isCompleted,
    Map<String, bool>? userCompletions,
    String? createdBy,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      comments: comments ?? this.comments,
      isCompleted: isCompleted ?? this.isCompleted,
      userCompletions: userCompletions ?? this.userCompletions,
      createdBy: createdBy ?? this.createdBy, isFullyCompleted: false,
    );
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, bool> userCompletions = {};
    if (data['userCompletions'] != null) {
      data['userCompletions'].forEach((key, value) {
        userCompletions[key] = value as bool;
      });
    }
    
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      description: data['description'],
      assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((comment) => Comment.fromMap(comment))
          .toList(),
      userCompletions: userCompletions,
      createdBy: data['createdBy'] ?? '', isFullyCompleted: false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'deadline': Timestamp.fromDate(deadline),
      'isCompleted': isCompleted,
      'description': description,
      'assignedUsers': assignedUsers,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'userCompletions': userCompletions,
      'createdBy': createdBy,
    };
  }

  bool get isFullyCompleted {
    return assignedUsers.isNotEmpty && 
           assignedUsers.every((userId) => userCompletions[userId] == true);
  }

  TaskStatus get status {
    if (isFullyCompleted) return TaskStatus.completed;
    if (deadline.isBefore(DateTime.now())) return TaskStatus.overdue;
    if (userCompletions.values.any((completed) => completed)) return TaskStatus.inProgress;
    return TaskStatus.pending;
  }
}

class Comment {
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: map['userId'],
      userName: map['userName'] ?? 'Anonymous',
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
