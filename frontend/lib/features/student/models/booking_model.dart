class BookingModel {
  final int id;
  final int userId;
  final String? userName;
  final String? roomNumber;
  final String date;
  final bool breakfastBooked;
  final bool lunchBooked;
  final bool dinnerBooked;
  final bool isLocked;
  final double estimatedCost;
  final bool adminOverride;
  final String? overrideReason;

  BookingModel({
    required this.id,
    required this.userId,
    this.userName,
    this.roomNumber,
    required this.date,
    required this.breakfastBooked,
    required this.lunchBooked,
    required this.dinnerBooked,
    this.isLocked = false,
    this.estimatedCost = 0.0,
    this.adminOverride = false,
    this.overrideReason,
  });

  BookingModel copyWith({
    bool? breakfastBooked,
    bool? lunchBooked,
    bool? dinnerBooked,
    double? estimatedCost,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      userName: userName,
      roomNumber: roomNumber,
      date: date,
      breakfastBooked: breakfastBooked ?? this.breakfastBooked,
      lunchBooked: lunchBooked ?? this.lunchBooked,
      dinnerBooked: dinnerBooked ?? this.dinnerBooked,
      isLocked: isLocked,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      adminOverride: adminOverride,
      overrideReason: overrideReason,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String?,
      roomNumber: json['room_number'] as String?,
      date: json['date'] as String? ?? '',
      breakfastBooked: json['breakfast_booked'] as bool? ?? false,
      lunchBooked: json['lunch_booked'] as bool? ?? false,
      dinnerBooked: json['dinner_booked'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      adminOverride: json['admin_override'] as bool? ?? false,
      overrideReason: json['override_reason'] as String?,
    );
  }
}
