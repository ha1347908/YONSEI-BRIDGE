import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final List<String> targetCountries;
  final DateTime createdAt;
  final String createdBy;
  final int recipientCount;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.targetCountries,
    required this.createdAt,
    required this.createdBy,
    this.recipientCount = 0,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'targetCountries': targetCountries,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'recipientCount': recipientCount,
    };
  }

  // Create from Firestore document
  factory AdminNotification.fromFirestore(Map<String, dynamic> data, String docId) {
    return AdminNotification(
      id: docId,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      targetCountries: List<String>.from(data['targetCountries'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      recipientCount: data['recipientCount'] as int? ?? 0,
    );
  }
}

class NotificationRecipient {
  final String notificationId;
  final String userId;
  final bool isRead;
  final DateTime receivedAt;

  NotificationRecipient({
    required this.notificationId,
    required this.userId,
    this.isRead = false,
    required this.receivedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'isRead': isRead,
      'receivedAt': Timestamp.fromDate(receivedAt),
    };
  }

  factory NotificationRecipient.fromFirestore(Map<String, dynamic> data) {
    return NotificationRecipient(
      notificationId: data['notificationId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      receivedAt: (data['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
