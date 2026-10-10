class KitchenPrepItemModel {
  final String mealType;
  final String? menuTitle;
  final List<String> dishNames;
  final int totalPortions;
  final bool published;

  KitchenPrepItemModel({
    required this.mealType,
    this.menuTitle,
    required this.dishNames,
    required this.totalPortions,
    required this.published,
  });

  factory KitchenPrepItemModel.fromJson(Map<String, dynamic> json) {
    return KitchenPrepItemModel(
      mealType: json['meal_type'] as String? ?? '',
      menuTitle: json['menu_title'] as String?,
      dishNames: (json['dish_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalPortions: json['total_portions'] as int? ?? 0,
      published: json['published'] as bool? ?? false,
    );
  }
}

class KitchenPrepSheetModel {
  final String date;
  final String hostelName;
  final List<KitchenPrepItemModel> items;
  final int totalActiveStudents;
  final int totalBookingsDay;

  KitchenPrepSheetModel({
    required this.date,
    required this.hostelName,
    required this.items,
    required this.totalActiveStudents,
    required this.totalBookingsDay,
  });

  factory KitchenPrepSheetModel.fromJson(Map<String, dynamic> json) {
    return KitchenPrepSheetModel(
      date: json['date'] as String? ?? '',
      hostelName: json['hostel_name'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => KitchenPrepItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      totalActiveStudents: json['total_active_students'] as int? ?? 0,
      totalBookingsDay: json['total_bookings_day'] as int? ?? 0,
    );
  }
}

class PriceHistoryItemModel {
  final int id;
  final String mealType;
  final double oldPrice;
  final double newPrice;
  final String? changedByName;
  final String changedAt;

  PriceHistoryItemModel({
    required this.id,
    required this.mealType,
    required this.oldPrice,
    required this.newPrice,
    this.changedByName,
    required this.changedAt,
  });

  factory PriceHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PriceHistoryItemModel(
      id: json['id'] as int? ?? 0,
      mealType: json['meal_type'] as String? ?? '',
      oldPrice: (json['old_price'] as num?)?.toDouble() ?? 0.0,
      newPrice: (json['new_price'] as num?)?.toDouble() ?? 0.0,
      changedByName: json['changed_by_name'] as String?,
      changedAt: json['changed_at'] as String? ?? '',
    );
  }
}
