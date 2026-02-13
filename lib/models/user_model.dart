import 'package:cloud_firestore/cloud_firestore.dart';

/// User status enumeration
enum UserStatus {
  pending,
  approved,
  rejected,
}

/// User role enumeration
enum UserRole {
  user,
  admin,
}

/// User model for YONSEI BRIDGE application
class UserModel {
  final String userId;
  final String name;
  final String nationality;
  final String contact;
  final String? idPhotoUrl; // Temporary - deleted after approval/rejection
  final UserStatus status;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final String? approvedBy;

  UserModel({
    required this.userId,
    required this.name,
    required this.nationality,
    required this.contact,
    this.idPhotoUrl,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.approvedBy,
  });

  /// Convert UserStatus enum to string
  static String statusToString(UserStatus status) {
    switch (status) {
      case UserStatus.pending:
        return 'Pending';
      case UserStatus.approved:
        return 'Approved';
      case UserStatus.rejected:
        return 'Rejected';
    }
  }

  /// Convert string to UserStatus enum
  static UserStatus stringToStatus(String status) {
    switch (status) {
      case 'Pending':
        return UserStatus.pending;
      case 'Approved':
        return UserStatus.approved;
      case 'Rejected':
        return UserStatus.rejected;
      default:
        return UserStatus.pending;
    }
  }

  /// Convert UserRole enum to string
  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Convert string to UserRole enum
  static UserRole stringToRole(String role) {
    switch (role) {
      case 'Admin':
        return UserRole.admin;
      case 'User':
      default:
        return UserRole.user;
    }
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: data['user_id'] as String? ?? documentId,
      name: data['name'] as String? ?? '',
      nationality: data['nationality'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      idPhotoUrl: data['id_photo_url'] as String?,
      status: stringToStatus(data['status'] as String? ?? 'Pending'),
      role: stringToRole(data['role'] as String? ?? 'User'),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
      approvedBy: data['approved_by'] as String?,
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'nationality': nationality,
      'contact': contact,
      'id_photo_url': idPhotoUrl ?? '',
      'status': statusToString(status),
      'role': roleToString(role),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      if (approvedAt != null) 'approved_at': Timestamp.fromDate(approvedAt!),
      if (approvedBy != null) 'approved_by': approvedBy,
    };
  }

  /// Check if user is approved
  bool get isApproved => status == UserStatus.approved;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user has pending status
  bool get isPending => status == UserStatus.pending;

  /// Copy with method
  UserModel copyWith({
    String? userId,
    String? name,
    String? nationality,
    String? contact,
    String? idPhotoUrl,
    UserStatus? status,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      contact: contact ?? this.contact,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}
