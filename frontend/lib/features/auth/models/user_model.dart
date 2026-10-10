class UserModel {
  final int id;
  final int hostelId;
  final String email;
  final String fullName;
  final String role; // 'ADMIN' or 'STUDENT'
  final String? roomNumber;
  final String? phoneNumber;
  final bool isActive;

  UserModel({
    required this.id,
    required this.hostelId,
    required this.email,
    required this.fullName,
    required this.role,
    this.roomNumber,
    this.phoneNumber,
    this.isActive = true,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isStudent => role == 'STUDENT';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      hostelId: json['hostel_id'] as int? ?? 1,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      roomNumber: json['room_number'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostel_id': hostelId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'room_number': roomNumber,
      'phone_number': phoneNumber,
      'is_active': isActive,
    };
  }
}
