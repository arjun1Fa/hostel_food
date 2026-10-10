class MealStatusModel {
  final String mealType;
  final bool booked;
  final bool consumed;
  final double priceCharged;

  MealStatusModel({
    required this.mealType,
    required this.booked,
    required this.consumed,
    required this.priceCharged,
  });

  factory MealStatusModel.fromJson(Map<String, dynamic> json) {
    return MealStatusModel(
      mealType: json['meal_type'] as String? ?? '',
      booked: json['booked'] as bool? ?? false,
      consumed: json['consumed'] as bool? ?? false,
      priceCharged: (json['price_charged'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentDayExpenseModel {
  final String date;
  final MealStatusModel breakfast;
  final MealStatusModel lunch;
  final MealStatusModel dinner;
  final double totalCharge;

  StudentDayExpenseModel({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.totalCharge,
  });

  factory StudentDayExpenseModel.fromJson(Map<String, dynamic> json) {
    return StudentDayExpenseModel(
      date: json['date'] as String? ?? '',
      breakfast: MealStatusModel.fromJson(json['breakfast'] as Map<String, dynamic>),
      lunch: MealStatusModel.fromJson(json['lunch'] as Map<String, dynamic>),
      dinner: MealStatusModel.fromJson(json['dinner'] as Map<String, dynamic>),
      totalCharge: (json['total_charge'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentExpenseSummaryModel {
  final int userId;
  final String userName;
  final int month;
  final int year;
  final double totalCharges;
  final int totalConsumedCount;
  final List<StudentDayExpenseModel> days;

  StudentExpenseSummaryModel({
    required this.userId,
    required this.userName,
    required this.month,
    required this.year,
    required this.totalCharges,
    required this.totalConsumedCount,
    required this.days,
  });

  factory StudentExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentExpenseSummaryModel(
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String? ?? '',
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      totalCharges: (json['total_charges'] as num?)?.toDouble() ?? 0.0,
      totalConsumedCount: json['total_consumed_count'] as int? ?? 0,
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => StudentDayExpenseModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
